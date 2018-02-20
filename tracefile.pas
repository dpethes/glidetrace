unit tracefile;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, classes, math, gli_common, glist;

const
  MEM_BUFFER_SIZE = 1 << 20;
  CMD_GUARD: longword = $deadbeef;

type
  TFrameOffsetList = specialize TList<int64>;

var
  g_tr: record
      frame_offsets: TFrameOffsetList;
      next_cmd_is_frame_marker: boolean;
      call_stats: array[TraceFunc] of integer;
  end;

  g_tracewrite: record
      file_text: Text;
      file_bin: file;
      buffer: TMemoryStream;
      trace_text: boolean;
      trace_bin: boolean;
      flush_each_write: boolean;
  end;

  g_traceread: record
      file_bin: file;
      buffer: TMemoryStream;
      load_buffer: pbyte;
      file_pos: int64;
  end;

procedure OpenTraceFileWrite(s: string);
procedure CloseTraceFileWrite;
function OpenTraceFileRead(s: string): boolean;
procedure CloseTraceFileRead;
procedure SeekToFrame(frame: integer);  //backward only seek
procedure TraceFPUExceptionMask();
procedure Trace(fn: TraceFunc);
procedure Trace(s: string);
procedure Trace(i: integer);
procedure Store(const buf; const size: integer);

procedure Load(out buf; const size: integer);
function LoadFunc: TraceFunc;
function HaveMore: boolean;

procedure StoreGuard; inline;
procedure LoadGuard; inline;

implementation

{ ================================================================================================ }
{ trace writing }

procedure OpenTraceFileWrite(s: string);
var
  i: TraceFunc;
begin
  for i := Low(TraceFunc) to High(TraceFunc) do
      g_tr.call_stats[i] := 0;

  with g_tracewrite do begin
      trace_bin := True;
      trace_text := false;
      flush_each_write := true;

      Assign(file_text, s + '.txt');
      Rewrite(file_text);

      Assign(file_bin, s + '.bin');
      Rewrite(file_bin, 1);

      buffer := TMemoryStream.Create;
      buffer.SetSize(MEM_BUFFER_SIZE * 2);
      buffer.WriteDWord(TRACE_VERSION);
  end;
end;

procedure CloseTraceFileWrite;
var
  i: TraceFunc;
begin
  if g_tracewrite.buffer.Position > 0 then
      BlockWrite(g_tracewrite.file_bin, PByte(g_tracewrite.buffer.Memory)^, g_tracewrite.buffer.Position);
  g_tracewrite.buffer.Free;
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
  if g_tracewrite.buffer.Position > MEM_BUFFER_SIZE then begin
      BlockWrite(g_tracewrite.file_bin, PByte(g_tracewrite.buffer.Memory)^, g_tracewrite.buffer.Position);
      g_tracewrite.buffer.Clear;
  end;
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

procedure RefillReadBuffer;
var
  size_avail: int64;
begin
  g_traceread.file_pos := FilePos(g_traceread.file_bin);
  size_avail := FileSize(g_traceread.file_bin) - g_traceread.file_pos;
  if size_avail > MEM_BUFFER_SIZE then
      size_avail := MEM_BUFFER_SIZE;

  blockread(g_traceread.file_bin, g_traceread.load_buffer^, size_avail);
  g_traceread.buffer.Clear;
  g_traceread.buffer.Write(g_traceread.load_buffer^, size_avail);
  g_traceread.buffer.Position := 0;
end;

function OpenTraceFileRead(s: string): boolean;
begin
  result := false;
  if not FileExists(s) then
      exit;
  Assign(g_traceread.file_bin, s);
  Reset(g_traceread.file_bin, 1);

  g_traceread.buffer := TMemoryStream.Create;
  g_traceread.load_buffer := Getmem(MEM_BUFFER_SIZE);
  RefillReadBuffer;

  if g_traceread.buffer.Size <= 4 then begin
      writeln('invalid or empty trace');
  end else if g_traceread.buffer.ReadDWord() <> TRACE_VERSION then begin
      writeln('cannot retrace! expected version is ', TRACE_VERSION);
  end else
      result := true;

  if not result then begin
      CloseTraceFileRead;
      exit;
  end;

  g_tr.frame_offsets := TFrameOffsetList.Create;
  g_tr.frame_offsets.Reserve(1 << 10);
end;

procedure CloseTraceFileRead;
begin
  g_traceread.buffer.Free;
  freemem(g_traceread.load_buffer);
  Close(g_traceread.file_bin);
end;

procedure SeekToFrame(frame: integer);
var
  fpos, current_fpos, how_much: int64;
begin
  if g_tr.frame_offsets.Count <= frame then
      frame := g_tr.frame_offsets.Count - 1;
  if frame < 0 then
      frame := 0;
  fpos := g_tr.frame_offsets[frame];
  current_fpos := g_traceread.file_pos + g_traceread.buffer.Position;
  how_much := current_fpos - fpos;
  assert(how_much >= 0, 'bad seek');

  if how_much <= g_traceread.buffer.Position then begin
      //fast seek - just rewind membuffer
      g_traceread.buffer.Position := g_traceread.buffer.Position - how_much;
  end
  else begin
      Seek(g_traceread.file_bin, fpos);
      RefillReadBuffer;
  end;
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
      RefillReadBuffer;
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
  fpos: int64;
begin
  if g_tr.next_cmd_is_frame_marker then begin
      //some extra checks, because seeking backwards can mess up the frame indexing order
      fpos := g_traceread.file_pos + g_traceread.buffer.Position;
      if (g_tr.frame_offsets.Count = 0) or (g_tr.frame_offsets[g_tr.frame_offsets.Count-1] < fpos) then
          g_tr.frame_offsets.Add(fpos);
  end;

  Load(cmd, 1);
  LoadGuard;
  if cmd <= ord(High(TraceFunc)) then begin
      result := TraceFunc(cmd);
      g_tr.next_cmd_is_frame_marker := result in [grSstWinOpen, grBufferSwap];
  end else begin
      writeln('bad command');  //ouch, cannot continue
      halt;
  end;
end;



end.
