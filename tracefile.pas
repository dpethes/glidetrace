unit tracefile;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, classes, math, gli_common,
  dc2_encoder, dc2_decoder, crc32fast,
  glist;

const
  MEM_BUFFER_SIZE = 1 << 20;
  LOAD_BUFFER_SIZE = 1 << 24;  //quake 2 needs at least 16MB for initial texture upload
  CMD_GUARD: longword = $deadbeef;

type
  TFrameOffsetList = specialize TList<int64>;

var
  g_tr: record
      frame_offsets: TFrameOffsetList;
      call_stats: array[TraceFunc] of integer;
      frame_size_bytes: integer;
      frame_compressed_size_bytes: integer;
  end;

  g_tracewrite: record
      file_text: Text;
      file_bin: file;
      buffer: TMemoryStream;
      compressed_buffer: TMemoryStream;
      trace_text: boolean;
      trace_bin: boolean;
      flush_each_write: boolean;
  end;

  g_traceread: record
      file_bin: file;
      buffer: TMemoryStream;
      load_buffer: pbyte;
      file_pos: int64;
      frame_num: integer;
  end;

procedure OpenTraceFileWrite(s: string);
procedure CloseTraceFileWrite;
function OpenTraceFileRead(s: string): boolean;
procedure CloseTraceFileRead;
procedure TraceFPUExceptionMask();
procedure Trace(fn: TraceFunc);
procedure Trace(s: string);
procedure Trace(i: integer);
procedure Store(const buf; const size: integer);

procedure Load(out buf; const size: integer);
function LoadFunc: TraceFunc;
procedure LoadPrevFrame;
procedure LoadNewFrame;
procedure RewindFrame;
function HaveMore: boolean;

procedure StoreGuard; inline;
procedure LoadGuard; inline;

implementation

{ ================================================================================================ }
{ trace writing }

const
  MAX_COMPRESSED_SUBBLOCK_SIZE = 32 * 1024;

function EncodeBytesToStream(const src: pbyte; const size: integer; var dest: TMemoryStream): integer;
var
  encoder: TDc2Encoder;
  src_data: pbyte;
  bytes_in: integer;
  bytes_left, encoded_size: integer;
  encdata: TEncodedSlice;
begin
  encoder := TDc2Encoder.Create();

  encoded_size := 0;
  src_data := src;
  bytes_in := MAX_COMPRESSED_SUBBLOCK_SIZE;
  bytes_left := size;

  while bytes_left > 0 do begin
      if bytes_left <= bytes_in then begin
          bytes_in := bytes_left;
          encoder.SetLastSlice();
      end;

      encoder.EncodeSlice(src_data, bytes_in, encdata);
      dest.Write(encdata.data^, encdata.size);
      encoded_size += encdata.size;

      src_data += bytes_in;
      bytes_left -= bytes_in;
  end;

  result := encoded_size;
  encoder.Free;
end;


procedure DecodeBytesToStream(const src: pbyte; const size: integer; var dest: TMemoryStream);
var
  decoder: TDc2Decoder;
  src_data: pbyte;
  bytes_in: integer;
  bytes_decoded: integer;
  decdata: TDecodedSlice;
begin
  decoder := TDc2Decoder.Create;

  src_data := src;
  bytes_decoded := 0;

  while bytes_decoded < size do begin
      bytes_in := size - bytes_decoded;
      if bytes_in > MAX_COMPRESSED_SUBBLOCK_SIZE then
          bytes_in := MAX_COMPRESSED_SUBBLOCK_SIZE
      else
          decoder.SetLastSlice;

      repeat
          decoder.DecodeSlice(src_data, bytes_in, decdata);
          dest.Write(decdata.data^, decdata.size);
      until decdata.size = 0;

      src_data += bytes_in;
      bytes_decoded += bytes_in;
  end;
  decoder.Free;
end;



procedure FramingWrite();
var
  encoded_size: integer;
  crc: LongWord;
begin
  crc := crc32(0, PByte(g_tracewrite.buffer.Memory), g_tracewrite.buffer.Position);

  g_tracewrite.compressed_buffer.Clear;
  encoded_size := EncodeBytesToStream(
                    PByte(g_tracewrite.buffer.Memory),
                    g_tracewrite.buffer.Position,
                    g_tracewrite.compressed_buffer
                  );

  Trace('frame size: ' + IntToStr(g_tracewrite.buffer.Position));
  Trace('compressed size: ' + IntToStr(encoded_size));

  BlockWrite(g_tracewrite.file_bin, encoded_size, 4);
  BlockWrite(g_tracewrite.file_bin, crc, 4);
  BlockWrite(g_tracewrite.file_bin, PByte(g_tracewrite.compressed_buffer.Memory)^, encoded_size);

  //raw
  {
  encoded_size := g_tracewrite.buffer.Position;
  BlockWrite(g_tracewrite.file_bin, g_tracewrite.buffer.Position, 4);
  BlockWrite(g_tracewrite.file_bin, crc, 4);
  BlockWrite(g_tracewrite.file_bin, PByte(g_tracewrite.buffer.Memory)^, encoded_size);
  }

  g_tracewrite.buffer.Clear;
end;


procedure FramingRead;
var
  size_avail: int64;
  frame_size: integer;
  crc, stored_crc: LongWord;
begin

  g_traceread.file_pos := FilePos(g_traceread.file_bin);
  size_avail := FileSize(g_traceread.file_bin) - g_traceread.file_pos;
  if size_avail < 4 then
      exit;

  blockread(g_traceread.file_bin, frame_size, 4);
  blockread(g_traceread.file_bin, stored_crc, 4);
  blockread(g_traceread.file_bin, g_traceread.load_buffer^, frame_size);

  g_traceread.buffer.Clear;
  DecodeBytesToStream(g_traceread.load_buffer, frame_size, g_traceread.buffer);


  g_tr.frame_compressed_size_bytes := frame_size;
  g_tr.frame_size_bytes := g_traceread.buffer.Position;

  //raw
  {
  blockread(g_traceread.file_bin, frame_size, 4);
  blockread(g_traceread.file_bin, stored_crc, 4);
  blockread(g_traceread.file_bin, g_traceread.load_buffer^, frame_size);
  g_traceread.buffer.Clear;
  g_traceread.buffer.Write(g_traceread.load_buffer^, frame_size);
  }
  crc := crc32(0, PByte(g_traceread.buffer.Memory), g_traceread.buffer.Position);
  if crc <> stored_crc then begin
      writeln('couldn''t decode frame data!');
      halt;
  end;

  g_traceread.buffer.Position := 0
end;


procedure OpenTraceFileWrite(s: string);
var
  i: TraceFunc;
begin
  for i := Low(TraceFunc) to High(TraceFunc) do
      g_tr.call_stats[i] := 0;

  with g_tracewrite do begin
      trace_bin := True;
      trace_text := false;
      flush_each_write := false;

      Assign(file_text, s + '.txt');
      Rewrite(file_text);

      Assign(file_bin, s + '.bin');
      Rewrite(file_bin, 1);

      buffer := TMemoryStream.Create;
      buffer.SetSize(MEM_BUFFER_SIZE * 2);
      buffer.WriteBuffer(TRACE_ID[1], length(TRACE_ID));
      buffer.WriteDWord(TRACE_VERSION);
      //flush file header
      BlockWrite(file_bin, PByte(buffer.Memory)^, buffer.Position);
      buffer.Clear;

      compressed_buffer := TMemoryStream.Create;
      compressed_buffer.SetSize(MEM_BUFFER_SIZE div 2);
  end;
end;

procedure CloseTraceFileWrite;
var
  i: TraceFunc;
begin
  if g_tracewrite.buffer.Position > 0 then
      FramingWrite();
  g_tracewrite.buffer.Free;
  g_tracewrite.compressed_buffer.Free;
  Close(g_tracewrite.file_bin);

  writeln(g_tracewrite.file_text, '===');
  writeln(g_tracewrite.file_text, 'api call statistics');
  for i := Low(TraceFunc) to High(TraceFunc) do
      if g_tr.call_stats[i] > 0 then
          writeln(g_tracewrite.file_text, TraceFuncNames[i], ': ', g_tr.call_stats[i]);
  Close(g_tracewrite.file_text);
end;

procedure WriteTxt(s: string);
begin
  if not g_tracewrite.trace_text then
      exit;

  writeln(g_tracewrite.file_text, s);
  if g_tracewrite.flush_each_write then
      Flush(g_tracewrite.file_text);
end;

procedure WriteBin(const buf; size: integer);
begin
  if not g_tracewrite.trace_bin then
      exit;
  g_tracewrite.buffer.Write(buf, size);
end;

procedure Store(const buf; const size: integer);
begin
  WriteBin(buf, size);
end;

procedure StoreGuard;
begin
  Store(CMD_GUARD, 4);
end;

procedure TraceFPUExceptionMask();
var
  FPUException: TFPUException;
  FPUExceptionMask: TFPUExceptionMask;
  s: string;
begin
  FPUExceptionMask := GetExceptionMask;
  for FPUException := Low(TFPUException) to High(TFPUException) do begin
      WriteStr(s, FPUException, ' - ');
      if not (FPUException in FPUExceptionMask) then
          s += 'not ';
      s += 'masked';
      WriteTxt(s);
  end;
end;

procedure Trace(fn: TraceFunc);
begin
  g_tr.call_stats[fn] += 1;
  WriteTxt(TraceFuncNames[fn]);
  WriteBin(fn, 1);
  StoreGuard;

  if fn = grBufferSwap then begin
      FramingWrite();
  end;
end;

procedure Trace(s: string);
begin
  WriteTxt('string: ' + s);
end;

procedure Trace(i: integer);
begin
  WriteTxt('int: ' + IntToStr(i));
end;

{ ================================================================================================ }
{ trace reading }

function OpenTraceFileRead(s: string): boolean;
const
  HEADER_SIZE = Length(TRACE_ID) + 4;
begin
  result := false;
  if not FileExists(s) then
      exit;
  Assign(g_traceread.file_bin, s);
  Reset(g_traceread.file_bin, 1);

  g_traceread.buffer := TMemoryStream.Create;
  g_traceread.load_buffer := Getmem(LOAD_BUFFER_SIZE);

  if FileSize(g_traceread.file_bin) <= HEADER_SIZE then begin
      writeln('invalid or empty trace');
  end else begin
      blockread(g_traceread.file_bin, g_traceread.load_buffer^, HEADER_SIZE);
      g_traceread.buffer.Write(g_traceread.load_buffer^, HEADER_SIZE);
      g_traceread.buffer.Position := Length(TRACE_ID);

      if g_traceread.buffer.ReadDWord() <> TRACE_VERSION then
          writeln('cannot retrace! expected version is ', TRACE_VERSION)
      else
          result := true;
  end;

  if not result then begin
      CloseTraceFileRead;
      exit;
  end;

  g_traceread.frame_num := 0;
  FramingRead;

  g_tr.frame_offsets := TFrameOffsetList.Create;
  g_tr.frame_offsets.Reserve(1 << 10);
end;

procedure CloseTraceFileRead;
begin
  g_tr.frame_offsets.Free;
  g_traceread.buffer.Free;
  freemem(g_traceread.load_buffer);
  Close(g_traceread.file_bin);
end;

procedure LoadPrevFrame;
var
  frame: integer;
  fpos: int64;
begin
  g_traceread.frame_num -= 1;
  frame := g_traceread.frame_num - 1;
  if frame < 0 then
      frame := 0;
  fpos := g_tr.frame_offsets[frame];
  Seek(g_traceread.file_bin, fpos);
  FramingRead;
end;

procedure LoadNewFrame;
var
  fpos: int64;
begin
  fpos := FilePos(g_traceread.file_bin);
  if (g_tr.frame_offsets.Count = 0) or (g_tr.frame_offsets[g_tr.frame_offsets.Count-1] < fpos) then
      g_tr.frame_offsets.Add(fpos);
  FramingRead;
  g_traceread.frame_num += 1;
end;

procedure RewindFrame;
begin
  g_traceread.buffer.Position := 0;
end;

function HaveMore: boolean;
begin
  result := g_traceread.buffer.Position < g_traceread.buffer.Size;
  if not result then
      result := (FileSize(g_traceread.file_bin) - FilePos(g_traceread.file_bin)) > 0;
end;

procedure Load(out buf; const size: integer);
var
  left_bytes: Int64;
  partial_size: integer;
begin
  left_bytes := g_traceread.buffer.Size - g_traceread.buffer.Position;
  if size > left_bytes then begin
      partial_size := size - left_bytes;
      if left_bytes > 0 then
          g_traceread.buffer.Read(buf, left_bytes);
      FramingRead;
      g_traceread.buffer.Read((pbyte(@buf) + left_bytes)^, partial_size);
  end else begin
      g_traceread.buffer.Read(buf, size);
  end;
end;

procedure LoadGuard; inline;
var
  guard: longword;
begin
  Load(guard, 4);
  if (guard <> CMD_GUARD) then begin
      writeln('invalid guard!');
      halt;
  end;
end;

function LoadFunc: TraceFunc;
var
  cmd: byte;
begin
  Load(cmd, 1);
  LoadGuard;
  if cmd <= ord(High(TraceFunc)) then begin
      result := TraceFunc(cmd);
  end else begin
      writeln('bad command');  //ouch, cannot continue
      halt;
  end;
end;


end.
