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
      file_text: Text;
      file_bin: file;
      buffer: TMemoryStream;
      load_buffer: pbyte;
      frame_offsets: TFrameOffsetList;
      file_pos: int64;
      next_cmd_is_frame_marker: boolean;

      can_write: boolean;
      trace_text: boolean;
      trace_bin: boolean;
      flush_each_write: boolean;

      call_stats: array[TraceFunc] of integer;
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

procedure StoreGuard;
procedure LoadGuard;

implementation


procedure OpenTraceFileWrite(s: string);
var
  i: TraceFunc;
begin
  with g_tr do begin
      trace_bin := True;
      trace_text := false;
      flush_each_write := true;
      for i := Low(TraceFunc) to High(TraceFunc) do
          g_tr.call_stats[i] := 0;
  end;

  Assign(g_tr.file_text, s + '.txt');
  Rewrite(g_tr.file_text);

  Assign(g_tr.file_bin, s + '.bin');
  Rewrite(g_tr.file_bin, 1);

  g_tr.buffer := TMemoryStream.Create;
  g_tr.buffer.SetSize(MEM_BUFFER_SIZE * 2);
  g_tr.buffer.WriteDWord(TRACE_VERSION);
end;

procedure CloseTraceFileWrite;
var
  i: TraceFunc;
begin
  if g_tr.buffer.Position > 0 then
      BlockWrite(g_tr.file_bin, PByte(g_tr.buffer.Memory)^, g_tr.buffer.Position);
  g_tr.buffer.Free;
  Close(g_tr.file_bin);

  writeln(g_tr.file_text, '===');
  writeln(g_tr.file_text, 'api call statistics');
  for i := Low(TraceFunc) to High(TraceFunc) do
      if g_tr.call_stats[i] > 0 then
          writeln(g_tr.file_text, TraceFuncNames[i], ': ', g_tr.call_stats[i]);
  Close(g_tr.file_text);
end;

procedure RefillReadBuffer;
var
  size_avail: int64;
begin
  g_tr.file_pos := FilePos(g_tr.file_bin);
  size_avail := FileSize(g_tr.file_bin) - g_tr.file_pos;
  if size_avail > MEM_BUFFER_SIZE then
      size_avail := MEM_BUFFER_SIZE;

  blockread(g_tr.file_bin, g_tr.load_buffer^, size_avail);
  g_tr.buffer.Clear;
  g_tr.buffer.Write(g_tr.load_buffer^, size_avail);
  g_tr.buffer.Position := 0;
end;

function OpenTraceFileRead(s: string): boolean;
begin
  result := false;
  if not FileExists(s) then
      exit;
  Assign(g_tr.file_bin, s);
  Reset(g_tr.file_bin, 1);

  g_tr.frame_offsets := TFrameOffsetList.Create;
  g_tr.frame_offsets.Reserve(1 << 10);
  g_tr.buffer := TMemoryStream.Create;
  g_tr.load_buffer := Getmem(MEM_BUFFER_SIZE);
  RefillReadBuffer;

  if g_tr.buffer.Size <= 4 then begin
      writeln('invalid or empty trace');
      close(g_tr.file_bin);
      exit;
  end;
  if g_tr.buffer.ReadDWord() <> TRACE_VERSION then begin
      writeln('cannot retrace! expected version is ', TRACE_VERSION);
      close(g_tr.file_bin);
      exit;
  end;
  result := true;
end;

procedure CloseTraceFileRead;
begin
  g_tr.buffer.Free;
  freemem(g_tr.load_buffer);
  Close(g_tr.file_bin);
end;

procedure SeekToFrame(frame: integer);
var
  fpos: int64;
begin
  if g_tr.frame_offsets.Count <= frame then
      frame := g_tr.frame_offsets.Count - 1;
  if frame < 0 then
      frame := 0;
  fpos := g_tr.frame_offsets[frame];
  Seek(g_tr.file_bin, fpos);
  RefillReadBuffer;
end;

procedure WriteTxt(s: string);
begin
  if not g_tr.trace_text then
      exit;

  writeln(g_tr.file_text, s);
  if g_tr.flush_each_write then
      Flush(g_tr.file_text);
end;

procedure WriteBin(const buf; size: integer);  //todo merge with Store
begin
  if not g_tr.trace_bin then
      exit;

  g_tr.buffer.Write(buf, size);
  if g_tr.buffer.Position > MEM_BUFFER_SIZE {or g_tr.flush_each_write} then begin
      BlockWrite(g_tr.file_bin, PByte(g_tr.buffer.Memory)^, g_tr.buffer.Position);
      g_tr.buffer.Clear;
  end;
end;

procedure TraceFPUExceptionMask();
var
  FPUException: TFPUException;
  FPUExceptionMask: TFPUExceptionMask;
begin
  if not g_tr.trace_text then
      exit;

  FPUExceptionMask := GetExceptionMask;
  for FPUException := Low(TFPUException) to High(TFPUException) do begin
    write(g_tr.file_text, FPUException, ' - ');
    if not (FPUException in FPUExceptionMask) then
        write(g_tr.file_text, 'not ');
    writeln(g_tr.file_text, 'masked');
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

procedure Store(const buf; const size: integer);
begin
  WriteBin(buf, size);
end;

function HaveMore: boolean;
begin
  result := g_tr.buffer.Position < g_tr.buffer.Size;
  if not result then
      result := (FileSize(g_tr.file_bin) - FilePos(g_tr.file_bin)) > 0;
end;

procedure Load(out buf; const size: integer);
var
  left_bytes: Int64;
  partial_size: integer;
begin
  left_bytes := g_tr.buffer.Size - g_tr.buffer.Position;
  if size > left_bytes then begin
      partial_size := size - left_bytes;
      if left_bytes > 0 then
          g_tr.buffer.Read(buf, left_bytes);
      RefillReadBuffer;
      g_tr.buffer.Read((pbyte(@buf) + left_bytes)^, partial_size);
  end else begin
      g_tr.buffer.Read(buf, size);
  end;
end;

function LoadFunc: TraceFunc;
var
  cmd: byte;
  fpos: int64;
begin
  if g_tr.next_cmd_is_frame_marker then begin
      //some extra checks, because seeking backwards can mess up the frame indexing order
      fpos := g_tr.file_pos + g_tr.buffer.Position;
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

procedure StoreGuard;
begin
  Store(CMD_GUARD, 4);
end;

procedure LoadGuard;
var
  guard: longword;
begin
  Load(guard, 4);
  if (guard <> CMD_GUARD) then begin
      writeln('invalid guard!');
      halt;
  end;
end;



end.
