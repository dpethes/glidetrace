unit wrapper_util;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Windows, Glide2x, tracefile;

var
  g_ctx: record
      data_16bit, data_24bit: PByte;
      wxh: integer;
      buffer_swaps, lfb_locks: integer;

      lfb_write_trace: boolean;
      lfb_write_buffer: pointer;
      lfb_write_buffer_size: integer;
      lfb_info: record
          size: integer;
          ptr: Pointer;
          stride: TFxU32;
          locked: boolean;
      end;
  end;

procedure InitGCtx();
procedure SaveFrontBuffer();
procedure SaveLfbPtr();

//should be available from Windows 98 on
function GetWriteWatch(dwFlags: DWORD; lpBaseAddress: PVOID; dwRegionSize: SIZE_T;
  lpAddresses: PVOID; lpdwCount: PLongWord; lpdwGranularity: PLongWord): UINT;
  stdcall; external 'kernel32.dll' Name 'GetWriteWatch';

const
  WRITE_WATCH_FLAG_RESET = $01;

implementation

procedure Rgb565ToRgb24(const src, dst: pbyte; const w, h: integer);
var
  i: integer;
  r, g, b, c: integer;
begin
  for i := 0 to w * h - 1 do
  begin
      c := (src[i * 2 + 1] shl 8) or src[i * 2 + 0];
      b := (c and %00011111) shl 3;
      g := ((c shr 5) and %00111111) shl 2;
      r := ((c shr 11) and %00011111) shl 3;

      //fill lowest bits - not strictly needed but nicer?
      b := b or (b shr 5);
      g := g or (g shr 6);
      r := r or (r shr 5);

      dst[i * 3 + 0] := byte(r);
      dst[i * 3 + 1] := byte(g);
      dst[i * 3 + 2] := byte(b);
  end;
end;

procedure PnmSave(const fname: string; const p: pbyte; const w, h: word);
var
  f: file;
  c: PChar;
begin
  c := PChar(format('P6'#10'%d %d'#10'255'#10, [w, h]));
  AssignFile(f, fname);
  Rewrite(f, 1);
  BlockWrite(f, c^, strlen(c));
  BlockWrite(f, p^, w * h * 3);
  CloseFile(f);
end;

procedure InitGCtx;
var
  wxh: integer;
  lfb_valloc_flags: integer;
begin
  with g_ctx do
  begin
      buffer_swaps := 0;
      lfb_locks := 0;
      wxh := 0;
      lfb_write_trace := False;
      lfb_write_buffer := nil;
      lfb_info.locked := False;
  end;
  g_ctx.lfb_write_trace := false;  //experimental

  wxh := 640 * 480;  //todo use grSstScreenWidth() * grSstScreenHeight();
  Trace(format('InitGBuffer %dx%d', [grSstScreenWidth(), grSstScreenHeight()]));

  if g_ctx.wxh < wxh then
  begin
      if g_ctx.wxh > 0 then
      begin
          freemem(g_ctx.data_16bit);
          if g_ctx.lfb_write_buffer <> nil then
              VirtualFree(g_ctx.lfb_write_buffer, 0, MEM_RELEASE);
          //todo free valloc;
      end;
      g_ctx.wxh := wxh;
      g_ctx.data_16bit := GetMem(wxh * 5);
      g_ctx.data_24bit := g_ctx.data_16bit + wxh * 2;

      if g_ctx.lfb_write_trace then
      begin
          g_ctx.lfb_write_buffer_size := wxh * 8;  //todo height * max.stride
          lfb_valloc_flags := MEM_COMMIT or MEM_RESERVE or MEM_WRITE_WATCH;
          g_ctx.lfb_write_buffer := VirtualAlloc(nil, g_ctx.lfb_write_buffer_size, lfb_valloc_flags, PAGE_READWRITE);
          if g_ctx.lfb_write_buffer = nil then
              Trace('VirtualAlloc failed with errno ' + IntToStr(GetLastError));
      end;
  end;
end;

procedure SaveFrontBuffer();
var
  ok: TFxBOOL;
begin
  if g_ctx.wxh <= 0 then
      exit;

  ok := grLfbReadRegion(GR_BUFFER_FRONTBUFFER, 0, 0, 640, 480, 640 * 2, g_ctx.data_16bit);
  if ok then
  begin
      Rgb565ToRgb24(g_ctx.data_16bit, g_ctx.data_24bit, 640, 480);
      PnmSave(format('screen_%0.6d.pnm', [g_ctx.buffer_swaps]), g_ctx.data_24bit, 640, 480);
  end;
end;

procedure SaveLfbPtr();
const
  MAX_ADR = 480;
var
  used_adresses: array[0..MAX_ADR] of pointer;
  used_adresses_count, page_size: longword;
  gww_ok: longword;
begin
  used_adresses_count := MAX_ADR;
  gww_ok := GetWriteWatch(WRITE_WATCH_FLAG_RESET, g_ctx.lfb_write_buffer,
      g_ctx.lfb_write_buffer_size, @used_adresses[0], @used_adresses_count, @page_size);

  if gww_ok <> 0 then begin
      Trace('something went wrong with LFB tracing...');
      exit;
  end;

  Trace(format('adr: %d  pagesize: %d', [used_adresses_count, page_size]));

  Rgb565ToRgb24(g_ctx.lfb_write_buffer, g_ctx.data_24bit, 640, 480);
  PnmSave(format('lfbptr_%0.6d.pnm', [g_ctx.lfb_locks]), g_ctx.data_24bit, 640, 480);
end;


end.
