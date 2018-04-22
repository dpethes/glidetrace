unit funcwrap;

{$mode objfpc}
{$asmmode intel}

interface

uses
  SysUtils, glide2x, gli_common, tracefile, wrapper_util;

procedure grDrawPlanarPolygon(nverts: integer; const ilist: PInteger; const vlist: PGrVertex); stdcall;
procedure grDrawPlanarPolygonVertexList(nverts: integer; const vlist: PGrVertex); stdcall;
procedure grDrawPolygon(nverts: integer; const ilist: PInteger; const vlist: PGrVertex); stdcall;
procedure grDrawPolygonVertexList(nverts: integer; const vlist: PGrVertex); stdcall;
procedure grDrawPoint(const pt: PGrVertex); stdcall;
procedure grDrawLine(const v1, v2: PGrVertex); stdcall;
procedure grDrawTriangle(const a, b, c: PGrVertex); stdcall;
procedure grBufferClear(color: TGrColor; alpha: TGrAlpha; depth: TFxU32); stdcall;
procedure grBufferNumPending; stdcall;
procedure grBufferSwap(swap_interval: TFxU32); stdcall;
procedure grRenderBuffer(buffer: TGrBuffer); stdcall;
procedure grErrorSetCallback(fnc: TGrErrorCallbackFnc); stdcall;
procedure grSstIdle; stdcall;
function grSstVideoLine: TFxU32; stdcall;
function grSstVRetraceOn: TFxBool; stdcall;
function grSstIsBusy: TFxBool; stdcall;
function grSstWinOpen(hWnd: TFxU32; screen_resolution: TGrScreenResolution; refresh_rate: TGrScreenRefresh;
  color_format: TGrColorFormat; origin_location: TGrOriginLocation; nColBuffers: TFxI32;
  nAuxBuffers: TFxI32): TFxBool; stdcall;
procedure grSstWinClose; stdcall;
function grSstControl(code: TGrControl): TFxBOOL; stdcall;
function grSstQueryHardware(hwconfig: PGrHwConfiguration): TFxBOOL; stdcall;
function grSstQueryBoards(hwconfig: PGrHwConfiguration): TFxBOOL; stdcall;
procedure grSstOrigin(origin: TGrOriginLocation); stdcall;
procedure grSstSelect(which_sst: TFxI32); stdcall;
function grSstScreenHeight: TFxU32; stdcall;
function grSstScreenWidth: TFxU32; stdcall;
function grSstStatus: TFxU32; stdcall;
procedure grSstPerfStats(pStats: PGrSstPerfStats); stdcall;
procedure grSstResetPerfStats; stdcall;
procedure grResetTriStats; stdcall;
procedure grTriStats(trisProcessed: PFxU32; trisDrawn: PFxU32); stdcall;
procedure grAlphaBlendFunction(rgb_sf, rgb_df, alpha_sf, alpha_df: TGrAlphaBlendFnc); stdcall;
procedure grAlphaCombine(func: TGrCombineFunction; factor: TGrCombineFactor; local: TGrCombineLocal;
  other: TGrCombineOther; invert: TFxBOOL); stdcall;
procedure grAlphaControlsITRGBLighting(enable: TFxBOOL); stdcall;
procedure grAlphaTestFunction(func: TGrCmpFnc); stdcall;
procedure grAlphaTestReferenceValue(Value: TGrAlpha); stdcall;
procedure grChromakeyMode(mode: TGrChromaKeyMode); stdcall;
procedure grChromakeyValue(Value: TGrColor); stdcall;
procedure grClipWindow(minx, miny, maxx, maxy: TFxU32); stdcall;
procedure grColorCombine(func: TGrCombineFunction; factor: TGrCombineFactor; local: TGrCombineLocal;
  other: TGrCombineOther; invert: TFxBOOL); stdcall;
procedure grColorMask(rgb, a: TFxBOOL); stdcall;
procedure grCullMode(mode: TGrCullMode); stdcall;
procedure grConstantColorValue(Value: TGrColor); stdcall;
procedure grConstantColorValue4(a, r, g, b: single); stdcall;
procedure grDepthBiasLevel(level: TFxI32); stdcall;
procedure grDepthBufferFunction(func: TGrCmpFnc); stdcall;
procedure grDepthBufferMode(mode: TGrDepthBufferMode); stdcall;
procedure grDepthMask(mask: TFxBOOL); stdcall;
procedure grDisableAllEffects; stdcall;
procedure grDitherMode(mode: TGrDitherMode); stdcall;
procedure grFogColorValue(fogcolor: TGrColor); stdcall;
procedure grFogMode(mode: TGrFogMode); stdcall;
procedure grFogTable(const ft: PGrFog); stdcall;
procedure grGammaCorrectionValue(Value: single); stdcall;
procedure grSplash(x, y, Width, Height: single; frame: TFxU32); stdcall;
function grTexCalcMemRequired(lodmin, lodmax: TGrLOD; aspect: TGrAspectRatio; fmt: TGrTextureFormat): TFxU32; stdcall;
function grTexTextureMemRequired(evenOdd: TFxU32; info: PGrTexInfo): TFxU32; stdcall;
function grTexMinAddress(tmu: TGrChipID): TFxU32; stdcall;
function grTexMaxAddress(tmu: TGrChipID): TFxU32; stdcall;
procedure grTexNCCTable(tmu: TGrChipID; table: TGrNccTable); stdcall;
procedure grTexSource(tmu: TGrChipID; startAddress, evenOdd: TFxU32; info: PGrTexInfo); stdcall;
procedure grTexClampMode(tmu: TGrChipID; s_clampmode, t_clampmode: TGrTextureClampMode); stdcall;
procedure grTexCombine(tmu: TGrChipID; rgb_function: TGrCombineFunction; rgb_factor: TGrCombineFactor;
  alpha_function: TGrCombineFunction; alpha_factor: TGrCombineFactor; rgb_invert: TFxBOOL;
  alpha_invert: TFxBOOL); stdcall;
procedure grTexCombineFunction(tmu: TGrChipID; func: TGrTextureCombineFnc); stdcall;
procedure grTexDetailControl(tmu: TGrChipID; lod_bias: integer; detail_scale: TFxU8; detail_max: single); stdcall;
procedure grTexFilterMode(tmu: TGrChipID; minfilter_mode, magfilter_mode: TGrTextureFilterMode); stdcall;
procedure grTexLodBiasValue(tmu: TGrChipID; bias: single); stdcall;
procedure grTexDownloadMipMap(tmu: TGrChipID; startAddress, evenOdd: TFxU32; info: PGrTexInfo); stdcall;
procedure grTexDownloadMipMapLevel(tmu: TGrChipID; startAddress: TFxU32; thisLod: TGrLOD;
  largeLod: TGrLOD; aspectRatio: TGrAspectRatio; format: TGrTextureFormat; evenOdd: TFxU32; Data: Pointer); stdcall;
procedure grTexDownloadMipMapLevelPartial(tmu: TGrChipID; startAddress: TFxU32; thisLod: TGrLOD;
  largeLod: TGrLOD; aspectRatio: TGrAspectRatio; format: TGrTextureFormat; evenOdd: TFxU32;
  Data: Pointer; _start: TFxI32; _end: TFxI32); stdcall;
procedure ConvertAndDownloadRle(tmu: TGrChipID; startAddress: TFxU32; thisLod: TGrLOD;
  largeLod: TGrLOD; aspectRatio: TGrAspectRatio; format: TGrTextureFormat; evenOdd: TFxU32;
  bm_data: PFxU8; bm_h: longword; u0: TFxU32; v0: TFxU32; Width: TFxU32; Height: TFxU32;
  dest_width: TFxU32; dest_height: TFxU32; tlut: PFxU16); stdcall;
procedure grCheckForRoom(n: TFxI32); stdcall;
procedure grTexDownloadTable(tmu: TGrChipID; _type: TGrTexTable; Data: Pointer); stdcall;
procedure grTexDownloadTablePartial(tmu: TGrChipID; _type: TGrTexTable; Data: Pointer;
  _start: TFxI32; _end: TFxI32); stdcall;
procedure grTexMipMapMode(tmu: TGrChipID; mode: TGrMipMapMode; lodBlend: TFxBOOL); stdcall;
procedure grTexMultibase(tmu: TGrChipID; enable: TFxBOOL); stdcall;
procedure grTexMultibaseAddress(tmu: TGrChipID; range: TGrTexBaseRange; startAddress: TFxU32;
  evenOdd: TFxU32; var info: TGrTexInfo); stdcall;
function grLfbLock(_type: TGrLock; buffer: TGrBuffer; writeMode: TGrLFBWriteMode;
  origin: TGrOriginLocation; pixelPipeline: TFxBOOL; var info: TGrLFBInfo): TFxBOOL; stdcall;
function grLfbUnlock(_type: TGrLock; buffer: TGrBuffer): TFxBOOL; stdcall;
procedure grLfbConstantAlpha(alpha: TGrAlpha); stdcall;
procedure grLfbConstantDepth(depth: TFxU16); stdcall;
procedure grLfbWriteColorSwizzle(swizzleBytes: TFxBOOL; swapWords: TFxBOOL); stdcall;
procedure grLfbWriteColorFormat(colorFormat: TGrColorFormat); stdcall;
function grLfbWriteRegion(dst_buffer: TGrBuffer; dst_x, dst_y: TFxU32; src_format: TGrLFBSrcFmt;
  src_width: TFxU32; src_height: TFxU32; src_stride: TFxI32; src_data: Pointer): TFxBOOL; stdcall;
function grLfbReadRegion(src_buffer: TGrBuffer; src_x, src_y, src_width, src_height, dst_stride: TFxU32;
  dst_data: Pointer): TFxBOOL; stdcall;
procedure grAADrawLine(const v1, v2: PGrVertex); stdcall;
procedure grAADrawPoint(const pt: PGrVertex); stdcall;
procedure grAADrawPolygon(const nverts: integer; const ilist: PInteger; const vlist: PGrVertex); stdcall;
procedure grAADrawPolygonVertexList(const nverts: integer; const vlist: PGrVertex); stdcall;
procedure grAADrawTriangle(const a, b, c: PGrVertex; ab_antialias, bc_antialias, ca_antialias: TFxBOOL); stdcall;
procedure grGlideInit; stdcall;
procedure grGlideShutdown; stdcall;
procedure grGlideGetVersion(version: PChar); stdcall;
procedure grGlideGetState(state: PGrState); stdcall;
procedure grGlideSetState(const state: PGrState); stdcall;
procedure grGlideShamelessPlug(on_: TFxBool); stdcall;
procedure grHints(hintType: TGrHint; hintMask: TFxU32); stdcall;

function gu3dfGetInfo(const filename: PChar; info: PGu3dfInfo): TFxBool; stdcall;
function gu3dfLoad(const filename: PChar; info: PGu3dfInfo): TFxBool; stdcall;
procedure guAADrawTriangleWithClip(const a, b, c: PGrVertex); stdcall;
procedure guAlphaSource(mode: TGrAlphaSource); stdcall;
procedure guColorCombineFunction(func: TGrColorCombineFnc); stdcall;
procedure guDrawTriangleWithClip(const a, b, c: PGrVertex); stdcall;
procedure guFogGenerateExp(fogTable: PGrFog; density: single); stdcall;
procedure guFogGenerateExp2(fogTable: PGrFog; density: single); stdcall;
procedure guFogGenerateLinear(fogTable: PGrFog; nearW, farW: single); stdcall;
function guFogTableIndexToW(i: integer): single; stdcall;

function guTexAllocateMemory(
  tmu: TGrChipID;
  evenOddMask: TFxU8;
  width, height: integer;
  format: TGrTextureFormat;
  mmMode: TGrMipMapMode;
  smallLod, largeLod: TGrLOD;
  aspectRatio: TGrAspectRatio;
  sClampMode, tClampMode: TGrTextureClampMode;
  minFilterMode, magFilterMode: TGrTextureFilterMode;
  lodBias: single;
  lodBlend: TFxBool
  ): TGrMipMapId; stdcall;
function guTexChangeAttributes(
  mmid: TGrMipMapId;
  width, height: integer;
  format: TGrTextureFormat;
  mmMode: TGrMipMapMode;
  smallLod, largeLod: TGrLOD;
  aspectRatio: TGrAspectRatio;
  sClampMode, tClampMode: TGrTextureClampMode;
  minFilterMode, magFilterMode: TGrTextureFilterMode
  ): TFxBool; stdcall;
procedure guTexCombineFunction(tmu: TGrChipID; func: TGrTextureCombineFnc); stdcall;
procedure guTexDownloadMipMap(mmid: TGrMipMapId; const src: pointer; const nccTable: PGuNCCTable); stdcall;
procedure guTexDownloadMipMapLevel(mmid: TGrMipMapId; lod: TGrLOD; const src: PPointer); stdcall;
function guTexGetCurrentMipMap(tmu: TGrChipID): TGrMipMapId; stdcall;
function guTexGetMipMapInfo(mmid: TGrMipMapId): PGrMipMapInfo; stdcall;
function guTexMemQueryAvail(tmu: TGrChipID): TFxU32; stdcall;
procedure guTexMemReset; stdcall;
procedure guTexSource(mmid: TGrMipMapId); stdcall;

procedure guDrawPolygonVertexListWithClip(nverts: integer; const vlist: PGrVertex); stdcall;
function guEndianSwapBytes(Value: TFxU32): TFxU32; stdcall;
function guEndianSwapWords(Value: TFxU32): TFxU32; stdcall;
function guEncodeRLE16(dst, src: pointer; Width, Height: TFxU32): integer; stdcall;
function guTexCreateColorMipMap(): PFxU16; stdcall;


procedure SetGlideLib(path: string);
procedure Unload;

{ ================================================================================================ }
implementation

var
  g_buffer: record
      ilist: PInteger;
      vlist: PGrVertex;
  end;
  g_is_init: boolean = false;
  g_glide_dll: string;

//maybe use critical section?
procedure Init();
begin
  if g_is_init then
      exit;
  InitGlideFromLibrary(g_glide_dll);
  OpenTraceFileWrite('trace');
  g_buffer.ilist := getmem(1 shl 20);
  g_buffer.vlist := getmem(1 shl 20);
  g_is_init := true;
end;

procedure Unload;
begin
  CloseTraceFileWrite();
end;

procedure SetGlideLib(path: string);
begin
  g_glide_dll := path;
end;

{ ================================================================================================ }
{ glide management functions }

procedure grGlideInit; stdcall;
begin
  Init();
  Trace(TraceFunc.grGlideInit);
  glide2x.grGlideInit();
end;

procedure grGlideShutdown; stdcall;
begin
  Trace(TraceFunc.grGlideShutdown);
  glide2x.grGlideShutdown();
end;

procedure grGlideGetVersion(version: PChar); stdcall;
const
  ID = ' (wrapped)' + #0;
var
  i: integer;
begin
  Init();
  Trace(TraceFunc.grGlideGetVersion);
  glide2x.grGlideGetVersion(version);
  i := 0;
  while (version[i] <> #0) and (i < 60) do
      i += 1;
  Move(ID, version[i], Length(ID));
end;

procedure grGlideGetState(state: PGrState); stdcall;
begin
  Trace(TraceFunc.grGlideGetState);
  glide2x.grGlideGetState(state);
end;

procedure grGlideSetState(const state: PGrState); stdcall;
begin
  Trace(TraceFunc.grGlideSetState);
  //Store(state^, sizeof(TGrState));
  glide2x.grGlideSetState(state);
end;

procedure grGlideShamelessPlug(on_: TFxBool); stdcall;
begin
  Trace(TraceFunc.grGlideShamelessPlug);
  glide2x.grGlideShamelessPlug(on_);
end;

{ ================================================================================================ }
{ SST routines }

procedure grSstIdle; stdcall;
begin
  Trace(TraceFunc.grSstIdle);
  glide2x.grSstIdle();
end;

function grSstVideoLine: TFxU32; stdcall;
begin
  Trace(TraceFunc.grSstVideoLine);
  Result := glide2x.grSstVideoLine();
end;

function grSstVRetraceOn: TFxBool; stdcall;
begin
  Trace(TraceFunc.grSstVRetraceOn);
  Result := glide2x.grSstVRetraceOn();
end;

function grSstIsBusy: TFxBool; stdcall;
begin
  Trace(TraceFunc.grSstIsBusy);
  Result := glide2x.grSstIsBusy();
end;

function grSstWinOpen(hWnd: TFxU32; screen_resolution: TGrScreenResolution; refresh_rate: TGrScreenRefresh;
  color_format: TGrColorFormat; origin_location: TGrOriginLocation; nColBuffers: TFxI32;
  nAuxBuffers: TFxI32): TFxBool; stdcall;
begin
  Trace(TraceFunc.grSstWinOpen);
  Store(screen_resolution, sizeof(TGrScreenResolution));
  Store(refresh_rate,      sizeof(TGrScreenRefresh   ));
  Store(color_format,      sizeof(TGrColorFormat     ));
  Store(origin_location,   sizeof(TGrOriginLocation  ));
  Store(nColBuffers,       sizeof(TFxI32             ));
  Store(nAuxBuffers,       sizeof(TFxI32             ));

  Result := glide2x.grSstWinOpen(hWnd, screen_resolution, refresh_rate, color_format,
      origin_location, nColBuffers, nAuxBuffers);
  if Result then
      InitGCtx();
end;

procedure grSstWinClose; stdcall;
begin
  Trace(TraceFunc.grSstWinClose);
  glide2x.grSstWinClose;
end;

function grSstControl(code: TGrControl): TFxBOOL; stdcall;
begin
  Trace(TraceFunc.grSstControl);
  Result := glide2x.grSstControl(code);
end;

function grSstQueryHardware(hwconfig: PGrHwConfiguration): TFxBOOL; stdcall;
begin
  Trace(TraceFunc.grSstQueryHardware);
  Result := glide2x.grSstQueryHardware(hwconfig);
end;

function grSstQueryBoards(hwconfig: PGrHwConfiguration): TFxBOOL; stdcall;
begin
  Init();
  Trace(TraceFunc.grSstQueryBoards);
  Result := glide2x.grSstQueryBoards(hwconfig);
end;

procedure grSstOrigin(origin: TGrOriginLocation); stdcall;
begin
  Trace(TraceFunc.grSstOrigin);
  Store(origin, sizeof(TGrOriginLocation));
  glide2x.grSstOrigin(origin);
end;

procedure grSstSelect(which_sst: TFxI32); stdcall;
begin
  Trace(TraceFunc.grSstSelect);
  glide2x.grSstSelect(which_sst);
end;

function grSstScreenHeight: TFxU32; stdcall;
begin
  Trace(TraceFunc.grSstScreenHeight);
  Result := glide2x.grSstScreenHeight();
end;

function grSstScreenWidth: TFxU32; stdcall;
begin
  Trace(TraceFunc.grSstScreenWidth);
  Result := glide2x.grSstScreenWidth();
end;

function grSstStatus: TFxU32; stdcall;
begin
  Trace(TraceFunc.grSstStatus);
  Result := glide2x.grSstStatus();
end;

procedure grSstPerfStats(pStats: PGrSstPerfStats); stdcall;
begin
  Trace(TraceFunc.grSstPerfStats);
  glide2x.grSstPerfStats(pStats);
end;

procedure grSstResetPerfStats; stdcall;
begin
  Trace(TraceFunc.grSstResetPerfStats);
  glide2x.grSstResetPerfStats();
end;

procedure grResetTriStats; stdcall;
begin
  Trace(TraceFunc.grResetTriStats);
  glide2x.grResetTriStats();
end;

procedure grTriStats(trisProcessed: PFxU32; trisDrawn: PFxU32); stdcall;
begin
  Trace(TraceFunc.grTriStats);
  glide2x.grTriStats(trisProcessed, trisDrawn);
end;


{ ================================================================================================ }
{ rendering functions }

{ this is a bit tricky: the offsets in ilist can be higher than nverts (subselections of a mesh)
  therefore, reorder verts in buffer and store just the subselection
  (basically, transform the input to be suitable for grDrawPolygonVertexList)
}
procedure grDrawPolygon(nverts: integer; const ilist: PInteger; const vlist: PGrVertex); stdcall;
var
  i: integer;
begin
  Trace(TraceFunc.grDrawPolygon);

  for i := 0 to nverts - 1 do begin
      g_buffer.ilist[i] := i;  //todo pre-generate on init?
      g_buffer.vlist[i] := vlist[ilist[i]];
  end;
  Store(nverts, 4);
  Store(g_buffer.ilist^, nverts * 4);
  Store(g_buffer.vlist^, nverts * sizeof(TGrVertex));
  glide2x.grDrawPolygon(nverts, g_buffer.ilist, g_buffer.vlist);
end;

procedure grDrawPlanarPolygon(nverts: integer; const ilist: PInteger; const vlist: PGrVertex);
  stdcall;
var
  i: Integer;
begin
  Trace(TraceFunc.grDrawPlanarPolygon);

  for i := 0 to nverts - 1 do begin
      g_buffer.ilist[i] := i;  //todo pre-generate on init?
      g_buffer.vlist[i] := vlist[ilist[i]];
  end;
  Store(nverts, 4);
  Store(g_buffer.ilist^, nverts * 4);
  Store(g_buffer.vlist^, nverts * sizeof(TGrVertex));
  glide2x.grDrawPlanarPolygon(nverts, g_buffer.ilist, g_buffer.vlist);
end;

procedure grDrawPolygonVertexList(nverts: integer; const vlist: PGrVertex); stdcall;
begin
  Trace(TraceFunc.grDrawPolygonVertexList);
  Store(nverts, 4);
  Store(vlist^, nverts * sizeof(TGrVertex));
  glide2x.grDrawPolygonVertexList(nverts, vlist);
end;

procedure grDrawPlanarPolygonVertexList(nverts: integer; const vlist: PGrVertex);
  stdcall;
begin
  Trace(TraceFunc.grDrawPlanarPolygonVertexList);
  Store(nverts, 4);
  Store(vlist^, nverts * sizeof(TGrVertex));
  glide2x.grDrawPlanarPolygonVertexList(nverts, vlist);
end;

procedure grDrawPoint(const pt: PGrVertex); stdcall;
begin
  Trace(TraceFunc.grDrawPoint);
  Store(pt^, sizeof(TGrVertex));
  glide2x.grDrawPoint(pt);
end;

procedure grDrawLine(const v1, v2: PGrVertex); stdcall;
begin
  Trace(TraceFunc.grDrawLine);
  Store(v1^, sizeof(TGrVertex));
  Store(v2^, sizeof(TGrVertex));
  glide2x.grDrawLine(v1, v2);
end;

procedure grDrawTriangle(const a, b, c: PGrVertex); stdcall;
begin
  Trace(TraceFunc.grDrawTriangle);
  Store(a^, sizeof(TGrVertex));
  Store(b^, sizeof(TGrVertex));
  Store(c^, sizeof(TGrVertex));
  glide2x.grDrawTriangle(a, b, c);
end;

procedure grAADrawLine(const v1, v2: PGrVertex); stdcall;
begin
  Trace(TraceFunc.grAADrawLine);
  Store(v1^, sizeof(TGrVertex));
  Store(v2^, sizeof(TGrVertex));
  glide2x.grAADrawLine(v1, v2);
end;

procedure grAADrawPoint(const pt: PGrVertex); stdcall;
begin
  Trace(TraceFunc.grAADrawPoint);
  Store(pt^, sizeof(TGrVertex));
  glide2x.grAADrawPoint(pt);
end;

procedure grAADrawPolygon(const nverts: integer; const ilist: PInteger; const vlist: PGrVertex);
  stdcall;
begin
  Trace(TraceFunc.grAADrawPolygon);
  glide2x.grAADrawPolygon(nverts, ilist, vlist);
end;

procedure grAADrawPolygonVertexList(const nverts: integer; const vlist: PGrVertex); stdcall;
begin
  Trace(TraceFunc.grAADrawPolygonVertexList);
  glide2x.grAADrawPolygonVertexList(nverts, vlist);
end;

procedure grAADrawTriangle(const a, b, c: PGrVertex; ab_antialias, bc_antialias, ca_antialias: TFxBOOL);
  stdcall;
begin
  Trace(TraceFunc.grAADrawTriangle);
  Store(a^, sizeof(TGrVertex));
  Store(b^, sizeof(TGrVertex));
  Store(c^, sizeof(TGrVertex));
  Store(ab_antialias, sizeof(TFxBool));
  Store(bc_antialias, sizeof(TFxBool));
  Store(ca_antialias, sizeof(TFxBool));
  glide2x.grAADrawTriangle(a, b, c, ab_antialias, bc_antialias, ca_antialias);
end;

{ ================================================================================================ }
{ buffer management }

procedure grBufferClear(color: TGrColor; alpha: TGrAlpha; depth: TFxU32); stdcall;
begin
  Trace(TraceFunc.grBufferClear);
  Store(color, sizeof(TGrColor));
  Store(alpha, sizeof(TGrAlpha));
  Store(depth, sizeof(TFxU32));
  glide2x.grBufferClear(color, alpha, depth);
end;

procedure grBufferNumPending; stdcall;
begin
  //skip completely, retrace doesn't care
  //Trace(TraceFunc.grBufferNumPending);
  glide2x.grBufferNumPending();
end;

procedure grBufferSwap(swap_interval: TFxU32); stdcall;
begin
  Trace(TraceFunc.grBufferSwap);
  glide2x.grBufferSwap(swap_interval);

  //if (g_ctx.buffer_swaps mod 10 = 0) then
  //    SaveFrontBuffer();
  g_ctx.buffer_swaps += 1;
end;

procedure grRenderBuffer(buffer: TGrBuffer); stdcall;
begin
  Trace(TraceFunc.grRenderBuffer);
  Store(buffer, sizeof(TGrBuffer));
  glide2x.grRenderBuffer(buffer);
end;

procedure grErrorSetCallback(fnc: TGrErrorCallbackFnc); stdcall;
begin
  Trace(TraceFunc.grErrorSetCallback);
  glide2x.grErrorSetCallback(fnc);
end;

{ ================================================================================================ }
{ Glide configuration and special effect maintenance functions }

procedure grAlphaBlendFunction(rgb_sf, rgb_df, alpha_sf, alpha_df: TGrAlphaBlendFnc); stdcall;
begin
  Trace(TraceFunc.grAlphaBlendFunction);
  Store(rgb_sf, sizeof(TGrAlphaBlendFnc));
  Store(rgb_df, sizeof(TGrAlphaBlendFnc));
  Store(alpha_sf, sizeof(TGrAlphaBlendFnc));
  Store(alpha_df, sizeof(TGrAlphaBlendFnc));
  glide2x.grAlphaBlendFunction(rgb_sf, rgb_df, alpha_sf, alpha_df);
end;

procedure grAlphaCombine(func: TGrCombineFunction; factor: TGrCombineFactor; local: TGrCombineLocal;
  other: TGrCombineOther; invert: TFxBOOL); stdcall;
begin
  Trace(TraceFunc.grAlphaCombine);
  Store(func, sizeof(TGrCombineFunction));
  Store(factor, sizeof(TGrCombineFactor));
  Store(local, sizeof(TGrCombineLocal));
  Store(other, sizeof(TGrCombineOther));
  Store(invert, sizeof(TFxBOOL));
  glide2x.grAlphaCombine(func, factor, local, other, invert);
end;

procedure grAlphaControlsITRGBLighting(enable: TFxBOOL); stdcall;
begin
  Trace(TraceFunc.grAlphaControlsITRGBLighting);
  glide2x.grAlphaControlsITRGBLighting(enable);
end;

procedure grAlphaTestFunction(func: TGrCmpFnc); stdcall;
begin
  Trace(TraceFunc.grAlphaTestFunction);
  Store(func, sizeof(TGrCmpFnc));
  glide2x.grAlphaTestFunction(func);
end;

procedure grAlphaTestReferenceValue(Value: TGrAlpha); stdcall;
begin
  Trace(TraceFunc.grAlphaTestReferenceValue);
  Store(Value, sizeof(TGrAlpha));
  glide2x.grAlphaTestReferenceValue(Value);
end;

procedure grChromakeyMode(mode: TGrChromaKeyMode); stdcall;
begin
  Trace(TraceFunc.grChromakeyMode);
  Store(mode, sizeof(TGrChromakeyMode));
  glide2x.grChromakeyMode(mode);
end;

procedure grChromakeyValue(Value: TGrColor); stdcall;
begin
  Trace(TraceFunc.grChromakeyValue);
  Store(Value, sizeof(TGrColor));
  glide2x.grChromakeyValue(Value);
end;

procedure grClipWindow(minx, miny, maxx, maxy: TFxU32); stdcall;
begin
  Trace(TraceFunc.grClipWindow);
  Store(minx, sizeof(TFxU32));
  Store(miny, sizeof(TFxU32));
  Store(maxx, sizeof(TFxU32));
  Store(maxy, sizeof(TFxU32));
  glide2x.grClipWindow(minx, miny, maxx, maxy);
end;

procedure grColorCombine(func: TGrCombineFunction; factor: TGrCombineFactor; local: TGrCombineLocal;
  other: TGrCombineOther; invert: TFxBOOL); stdcall;
begin
  Trace(TraceFunc.grColorCombine);
  Store(func, sizeof(TGrCombineFunction));
  Store(factor, sizeof(TGrCombineFactor));
  Store(local, sizeof(TGrCombineLocal));
  Store(other, sizeof(TGrCombineOther));
  Store(invert, sizeof(TFxBOOL));
  glide2x.grColorCombine(func, factor, local, other, invert);
end;

procedure grColorMask(rgb, a: TFxBOOL); stdcall;
begin
  Trace(TraceFunc.grColorMask);
  Store(rgb, sizeof(TFxBOOL));
  Store(a, sizeof(TFxBOOL));
  glide2x.grColorMask(rgb, a);
end;

procedure grCullMode(mode: TGrCullMode); stdcall;
begin
  Trace(TraceFunc.grCullMode);
  Store(mode, sizeof(TGrCullMode));
  glide2x.grCullMode(mode);
end;

procedure grConstantColorValue(Value: TGrColor); stdcall;
begin
  Trace(TraceFunc.grConstantColorValue);
  Store(Value, sizeof(TGrColor));
  glide2x.grConstantColorValue(Value);
end;

procedure grConstantColorValue4(a, r, g, b: single); stdcall;
begin
  Trace(TraceFunc.grConstantColorValue4);
  glide2x.grConstantColorValue4(a, r, g, b);
end;

procedure grDepthBiasLevel(level: TFxI32); stdcall;
begin
  Trace(TraceFunc.grDepthBiasLevel);
  Store(level, sizeof(TFxI32));
  glide2x.grDepthBiasLevel(level);
end;

procedure grDepthBufferFunction(func: TGrCmpFnc); stdcall;
begin
  Trace(TraceFunc.grDepthBufferFunction);
  Store(func, sizeof(TGrCmpFnc));
  glide2x.grDepthBufferFunction(func);
end;

procedure grDepthBufferMode(mode: TGrDepthBufferMode); stdcall;
begin
  Trace(TraceFunc.grDepthBufferMode);
  Store(mode, sizeof(TGrDepthBufferMode));
  glide2x.grDepthBufferMode(mode);
end;

procedure grDepthMask(mask: TFxBOOL); stdcall;
begin
  Trace(TraceFunc.grDepthMask);
  Store(mask, sizeof(TFxBOOL));
  glide2x.grDepthMask(mask);
end;

procedure grDisableAllEffects; stdcall;
begin
  Trace(TraceFunc.grDisableAllEffects);
  glide2x.grDisableAllEffects();
end;

procedure grDitherMode(mode: TGrDitherMode); stdcall;
begin
  Trace(TraceFunc.grDitherMode);
  Store(mode, sizeof(TGrDitherMode));
  glide2x.grDitherMode(mode);
end;

procedure grFogColorValue(fogcolor: TGrColor); stdcall;
begin
  Trace(TraceFunc.grFogColorValue);
  Store(fogcolor, sizeof(TGrColor));
  glide2x.grFogColorValue(fogcolor);
end;

procedure grFogMode(mode: TGrFogMode); stdcall;
begin
  Trace(TraceFunc.grFogMode);
  Store(mode, sizeof(TGrFogMode));
  glide2x.grFogMode(mode);
end;

procedure grFogTable(const ft: PGrFog); stdcall;
begin
  Trace(TraceFunc.grFogTable);
  Store(ft^, GR_FOG_TABLE_SIZE);
  glide2x.grFogTable(ft);
end;

procedure grGammaCorrectionValue(Value: single); stdcall;
begin
  Trace(TraceFunc.grGammaCorrectionValue);
  Store(Value, sizeof(single));
  glide2x.grGammaCorrectionValue(Value);
end;

procedure grSplash(x, y, Width, Height: single; frame: TFxU32); stdcall;
begin
  Trace(TraceFunc.grSplash);
  glide2x.grSplash(x, y, Width, Height, frame);
end;

function grTexCalcMemRequired(lodmin, lodmax: TGrLOD; aspect: TGrAspectRatio; fmt: TGrTextureFormat): TFxU32;
  stdcall;
begin
  Trace(TraceFunc.grTexCalcMemRequired);
  Result := glide2x.grTexCalcMemRequired(lodmin, lodmax, aspect, fmt);
end;

function grTexTextureMemRequired(evenOdd: TFxU32; info: PGrTexInfo): TFxU32; stdcall;
begin
  Trace(TraceFunc.grTexTextureMemRequired);
  Result := glide2x.grTexTextureMemRequired(evenOdd, info);
end;

function grTexMinAddress(tmu: TGrChipID): TFxU32; stdcall;
begin
  Trace(TraceFunc.grTexMinAddress);
  Result := glide2x.grTexMinAddress(tmu);
end;

function grTexMaxAddress(tmu: TGrChipID): TFxU32; stdcall;
begin
  Trace(TraceFunc.grTexMaxAddress);
  Result := glide2x.grTexMaxAddress(tmu);
end;

procedure grTexNCCTable(tmu: TGrChipID; table: TGrNccTable); stdcall;
begin
  Trace(TraceFunc.grTexNCCTable);
  glide2x.grTexNCCTable(tmu, table);
end;

procedure grTexSource(tmu: TGrChipID; startAddress, evenOdd: TFxU32; info: PGrTexInfo); stdcall;
begin
  Trace(TraceFunc.grTexSource);
  Store(tmu, sizeof(TGrChipID));
  Store(startAddress, sizeof(TFxU32));
  Store(evenOdd, sizeof(TFxU32));
  Store(info^, sizeof(TGrTexInfo));  //todo data pointer is useless, skip?
  glide2x.grTexSource(tmu, startAddress, evenOdd, info);
end;

procedure grTexClampMode(tmu: TGrChipID; s_clampmode, t_clampmode: TGrTextureClampMode); stdcall;
begin
  Trace(TraceFunc.grTexClampMode);
  Store(tmu, sizeof(TGrChipID));
  Store(s_clampmode, sizeof(TGrTextureClampMode));
  Store(t_clampmode, sizeof(TGrTextureClampMode));
  glide2x.grTexClampMode(tmu, s_clampmode, t_clampmode);
end;

procedure grTexCombine(tmu: TGrChipID; rgb_function: TGrCombineFunction; rgb_factor: TGrCombineFactor;
  alpha_function: TGrCombineFunction; alpha_factor: TGrCombineFactor; rgb_invert: TFxBOOL;
  alpha_invert: TFxBOOL); stdcall;
begin
  Trace(TraceFunc.grTexCombine);
  Store(tmu, sizeof(TGrChipID));
  Store(rgb_function, sizeof(TGrCombineFunction));
  Store(rgb_factor, sizeof(TGrCombineFactor));
  Store(alpha_function, sizeof(TGrCombineLocal));
  Store(alpha_factor, sizeof(TGrCombineOther));
  Store(rgb_invert, sizeof(TFxBOOL));
  Store(alpha_invert, sizeof(TFxBOOL));
  glide2x.grTexCombine(tmu, rgb_function, rgb_factor, alpha_function, alpha_factor, rgb_invert, alpha_invert);
end;

procedure grTexDetailControl(tmu: TGrChipID; lod_bias: integer; detail_scale: TFxU8; detail_max: single);
  stdcall;
begin
  Trace(TraceFunc.grTexDetailControl);
  glide2x.grTexDetailControl(tmu, lod_bias, detail_scale, detail_max);
end;

procedure grTexFilterMode(tmu: TGrChipID; minfilter_mode, magfilter_mode: TGrTextureFilterMode);
  stdcall;
begin
  Trace(TraceFunc.grTexFilterMode);
  Store(tmu, sizeof(TGrChipID));
  Store(minfilter_mode, sizeof(TGrTextureFilterMode));
  Store(magfilter_mode, sizeof(TGrTextureFilterMode));
  glide2x.grTexFilterMode(tmu, minfilter_mode, magfilter_mode);
end;

procedure grTexLodBiasValue(tmu: TGrChipID; bias: single); stdcall;
begin
  Trace(TraceFunc.grTexLodBiasValue);
  Store(tmu, sizeof(TGrChipID));
  Store(bias, sizeof(single));
  glide2x.grTexLodBiasValue(tmu, bias);
end;

procedure grTexDownloadMipMap(tmu: TGrChipID; startAddress, evenOdd: TFxU32; info: PGrTexInfo);
  stdcall;
var
  size: Int32;
begin
  Trace(TraceFunc.grTexDownloadMipMap);
  Store(tmu, sizeof(TGrChipID));
  Store(startAddress, sizeof(TFxU32));
  Store(evenOdd, sizeof(TFxU32));
  Store(info^, sizeof(TGrTexInfo));  //todo data pointer is useless, skip?

  //texture data
  size := glide2x.grTexCalcMemRequired(info^.smallLod, info^.largeLod, info^.aspectRatio, info^.format);
  Store(size, 4);
  Store(info^.Data^, size);

  glide2x.grTexDownloadMipMap(tmu, startAddress, evenOdd, info);
end;

procedure grTexDownloadMipMapLevel(tmu: TGrChipID; startAddress: TFxU32; thisLod: TGrLOD;
  largeLod: TGrLOD; aspectRatio: TGrAspectRatio; format: TGrTextureFormat; evenOdd: TFxU32; Data: Pointer);
  stdcall;
var
  size: Int32;
begin
  Trace(TraceFunc.grTexDownloadMipMapLevel);
  Store(tmu, sizeof(TGrChipID));
  Store(startAddress, sizeof(TFxU32));
  Store(thisLod, sizeof(TGrLOD));
  Store(largeLod, sizeof(TGrLOD));
  Store(aspectRatio, sizeof(TGrAspectRatio));
  Store(format, sizeof(TGrTextureFormat));
  Store(evenOdd, sizeof(TFxU32));

  size := glide2x.grTexCalcMemRequired(thisLod, thisLod, aspectRatio, format);
  Store(size, 4);
  Store(PByte(Data)^, size);

  glide2x.grTexDownloadMipMapLevel(tmu, startAddress, thisLod, largeLod, aspectRatio, format, evenOdd, Data);
end;

procedure grTexDownloadMipMapLevelPartial(tmu: TGrChipID; startAddress: TFxU32; thisLod: TGrLOD;
  largeLod: TGrLOD; aspectRatio: TGrAspectRatio; format: TGrTextureFormat; evenOdd: TFxU32; Data: Pointer;
  _start: TFxI32; _end: TFxI32); stdcall;
var
  size: Int32;
begin
  Trace(TraceFunc.grTexDownloadMipMapLevelPartial);
  Store(tmu, sizeof(TGrChipID));
  Store(startAddress, sizeof(TFxU32));
  Store(thisLod, sizeof(TGrLOD));
  Store(largeLod, sizeof(TGrLOD));
  Store(aspectRatio, sizeof(TGrAspectRatio));
  Store(format, sizeof(TGrTextureFormat));
  Store(evenOdd, sizeof(TFxU32));
  //store data as last
  Store(_start, sizeof(TFxI32));
  Store(_end, sizeof(TFxI32));

  //todo handle start-end properly. OpenGlide just ignores it, which is ok, if the app rewrites the original texture mem
  size := glide2x.grTexCalcMemRequired(thisLod, thisLod, aspectRatio, format);
  Store(size, 4);
  Store(PByte(Data)^, size);

  glide2x.grTexDownloadMipMapLevelPartial(tmu, startAddress, thisLod, largeLod, aspectRatio,
      format, evenOdd, Data, _start, _end);
end;

procedure grTexDownloadTable(tmu: TGrChipID; _type: TGrTexTable; Data: Pointer); stdcall;
var
  size: integer;
begin
  Trace(TraceFunc.grTexDownloadTable);
  Store(tmu, sizeof(TGrChipID));
  Store(_type, sizeof(TGrTexTable));

  size := sizeof(TGuNccTable);
  if _type = GR_TEXTABLE_PALETTE then
      size := sizeof(TGuTexPalette);
  Store(data^, size);

  glide2x.grTexDownloadTable(tmu, _type, Data);
end;

procedure grTexDownloadTablePartial(tmu: TGrChipID; _type: TGrTexTable; Data: Pointer; _start: TFxI32; _end: TFxI32);
  stdcall;
var
  size: TFxI32;
begin
  Trace(TraceFunc.grTexDownloadTablePartial);
  Store(tmu, sizeof(TGrChipID));
  Store(_type, sizeof(TGrTexTable));
  Store(_start, sizeof(TFxI32));
  Store(_end, sizeof(TFxI32));

  size := (_end + 1 - _start) * sizeof(TFxU32);
  Store(data^, size);

  glide2x.grTexDownloadTablePartial(tmu, _type, Data, _start, _end);
end;

procedure grTexMipMapMode(tmu: TGrChipID; mode: TGrMipMapMode; lodBlend: TFxBOOL); stdcall;
begin
  Trace(TraceFunc.grTexMipMapMode);
  Store(tmu, sizeof(TGrChipID));
  Store(mode, sizeof(TGrMipMapMode));
  Store(lodBlend, sizeof(TFxBOOL));
  glide2x.grTexMipMapMode(tmu, mode, lodBlend);
end;

procedure grTexMultibase(tmu: TGrChipID; enable: TFxBOOL); stdcall;
begin
  Trace(TraceFunc.grTexMultibase);
  glide2x.grTexMultibase(tmu, enable);
end;

procedure grTexMultibaseAddress(tmu: TGrChipID; range: TGrTexBaseRange; startAddress: TFxU32;
  evenOdd: TFxU32; var info: TGrTexInfo); stdcall;
begin
  Trace(TraceFunc.grTexMultibaseAddress);
  glide2x.grTexMultibaseAddress(tmu, range, startAddress, evenOdd, info);
end;

{ ================================================================================================ }
{ linear frame buffer functions }

function grLfbLock(_type: TGrLock; buffer: TGrBuffer; writeMode: TGrLFBWriteMode;
  origin: TGrOriginLocation; pixelPipeline: TFxBOOL; var info: TGrLFBInfo): TFxBOOL; stdcall;
var
  is_write_lock: boolean;
begin
  Trace(TraceFunc.grLfbLock);
  Result := glide2x.grLfbLock(_type, buffer, writeMode, origin, pixelPipeline, info);

  is_write_lock := ((_type and GR_LFB_WRITE_ONLY) > 0) and (buffer in [GR_BUFFER_FRONTBUFFER, GR_BUFFER_BACKBUFFER]);
  if is_write_lock and g_ctx.lfb_write_trace then begin
      with g_ctx.lfb_info do begin
          locked := true;
          ptr := info.lfbPtr;
          stride := info.strideInBytes;
      end;
      info.lfbPtr := g_ctx.lfb_write_buffer;
  end;

  g_ctx.lfb_locks += 1;
end;

function grLfbUnlock(_type: TGrLock; buffer: TGrBuffer): TFxBOOL; stdcall;
begin
  Trace(TraceFunc.grLfbUnlock);

  if g_ctx.lfb_write_trace and g_ctx.lfb_info.locked then begin
      g_ctx.lfb_info.locked := false;
      //todo copy only affected regions
      move(g_ctx.lfb_write_buffer^, g_ctx.lfb_info.ptr^, 480 * g_ctx.lfb_info.stride);

      SaveLfbPtr();
      //clear write buffer to see the changes when next write occurs
      //TODO if format allows, use transparent color for clearing?
      //FillByte(g_ctx.lfb_write_buffer^, 480 * g_ctx.lfb_info.stride, 0);
  end;

  Result := glide2x.grLfbUnlock(_type, buffer);
end;

procedure grLfbConstantAlpha(alpha: TGrAlpha); stdcall;
begin
  Trace(TraceFunc.grLfbConstantAlpha);
  glide2x.grLfbConstantAlpha(alpha);
end;

procedure grLfbConstantDepth(depth: TFxU16); stdcall;
begin
  Trace(TraceFunc.grLfbConstantDepth);
  glide2x.grLfbConstantDepth(depth);
end;

procedure grLfbWriteColorSwizzle(swizzleBytes: TFxBOOL; swapWords: TFxBOOL); stdcall;
begin
  Trace(TraceFunc.grLfbWriteColorSwizzle);
  glide2x.grLfbWriteColorSwizzle(swizzleBytes, swapWords);
end;

procedure grLfbWriteColorFormat(colorFormat: TGrColorFormat); stdcall;
begin
  Trace(TraceFunc.grLfbWriteColorFormat);
  glide2x.grLfbWriteColorFormat(colorFormat);
end;

function grLfbWriteRegion(dst_buffer: TGrBuffer; dst_x, dst_y: TFxU32; src_format: TGrLFBSrcFmt;
  src_width: TFxU32; src_height: TFxU32; src_stride: TFxI32; src_data: Pointer): TFxBOOL;
  stdcall;
begin
  Trace(TraceFunc.grLfbWriteRegion);
  Result := glide2x.grLfbWriteRegion(dst_buffer, dst_x, dst_y, src_format, src_width, src_height,
      src_stride, src_data);
end;

function grLfbReadRegion(src_buffer: TGrBuffer; src_x, src_y, src_width, src_height, dst_stride: TFxU32;
  dst_data: Pointer): TFxBOOL; stdcall;
begin
  Trace(TraceFunc.grLfbReadRegion);
  Result := glide2x.grLfbReadRegion(src_buffer, src_x, src_y, src_width, src_height, dst_stride, dst_data);
end;

{ ================================================================================================ }

procedure grHints(hintType: TGrHint; hintMask: TFxU32); stdcall;
begin
  Trace(TraceFunc.grHints);
  Store(hintType, sizeof(TGrHint));
  Store(hintMask, sizeof(TFxU32));
  glide2x.grHints(hintType, hintMask);
end;


function gu3dfGetInfo(const filename: PChar; info: PGu3dfInfo): TFxBool; stdcall;
begin
  Trace(TraceFunc.gu3dfGetInfo);
  Result := glide2x.gu3dfGetInfo(filename, info);
end;

function gu3dfLoad(const filename: PChar; info: PGu3dfInfo): TFxBool; stdcall;
begin
  Trace(TraceFunc.gu3dfLoad);
  Result := glide2x.gu3dfLoad(filename, info);
end;

procedure guAADrawTriangleWithClip(const a, b, c: PGrVertex); stdcall;
begin
  Trace(TraceFunc.guAADrawTriangleWithClip);
  glide2x.guAADrawTriangleWithClip(a, b, c);
end;

procedure guAlphaSource(mode: TGrAlphaSource); stdcall;
begin
  Trace(TraceFunc.guAlphaSource);
  Store(mode, sizeof(TGrAlphaSource));
  glide2x.guAlphaSource(mode);
end;

procedure guColorCombineFunction(func: TGrColorCombineFnc); stdcall;
begin
  Trace(TraceFunc.guColorCombineFunction);
  Store(func, sizeof(TGrColorCombineFnc));
  glide2x.guColorCombineFunction(func);
end;

procedure guDrawTriangleWithClip(const a, b, c: PGrVertex); stdcall;
begin
  Trace(TraceFunc.guDrawTriangleWithClip);
  Store(a^, sizeof(TGrVertex));
  Store(b^, sizeof(TGrVertex));
  Store(c^, sizeof(TGrVertex));
  glide2x.guDrawTriangleWithClip(a, b, c);
end;

procedure guFogGenerateExp(fogTable: PGrFog; density: single); stdcall;
begin
  Trace(TraceFunc.guFogGenerateExp);
  glide2x.guFogGenerateExp(fogTable, density);
end;

procedure guFogGenerateExp2(fogTable: PGrFog; density: single); stdcall;
begin
  Trace(TraceFunc.guFogGenerateExp2);
  glide2x.guFogGenerateExp2(fogTable, density);
end;

procedure guFogGenerateLinear(fogTable: PGrFog; nearW, farW: single); stdcall;
begin
  Trace(TraceFunc.guFogGenerateLinear);
  glide2x.guFogGenerateLinear(fogTable, nearW, farW);
end;

function guFogTableIndexToW(i: integer): single; stdcall;
begin
  Trace(TraceFunc.guFogTableIndexToW);
  Result := glide2x.guFogTableIndexToW(i);
end;

function guTexAllocateMemory(
  tmu: TGrChipID;
  evenOddMask: TFxU8;
  width, height: integer;
  format: TGrTextureFormat;
  mmMode: TGrMipMapMode;
  smallLod, largeLod: TGrLOD;
  aspectRatio: TGrAspectRatio;
  sClampMode, tClampMode: TGrTextureClampMode;
  minFilterMode, magFilterMode: TGrTextureFilterMode;
  lodBias: single;
  lodBlend: TFxBool
  ): TGrMipMapId; stdcall;
begin
  Trace(TraceFunc.guTexAllocateMemory);
  Store(tmu, sizeof(TGrChipID));
  Store(evenOddMask, sizeof(TFxU8));
  Store(width,  sizeof(integer));
  Store(height, sizeof(integer));
  Store(format, sizeof(TGrTextureFormat));
  Store(mmMode, sizeof(TGrMipMapMode));
  Store(smallLod, sizeof(TGrLOD));
  Store(largeLod, sizeof(TGrLOD));
  Store(aspectRatio, sizeof(TGrAspectRatio));
  Store(sClampMode, sizeof(TGrTextureClampMode));
  Store(tClampMode, sizeof(TGrTextureClampMode));
  Store(minFilterMode, sizeof(TGrTextureFilterMode));
  Store(magFilterMode, sizeof(TGrTextureFilterMode));
  Store(lodBias, sizeof(single));
  Store(lodBlend, sizeof(TFxBool));

  Result := glide2x.guTexAllocateMemory(tmu, evenOddMask, Width, Height, format, mmMode,
      smallLod, largeLod, aspectRatio, sClampMode, tClampMode, minFilterMode, magFilterMode, lodBias, lodBlend);

  //store result, it's used by other guTex functions
  Store(Result, sizeof(TGrMipMapId))
end;

function guTexChangeAttributes(
  mmid: TGrMipMapId;
  width, height: integer;
  format: TGrTextureFormat;
  mmMode: TGrMipMapMode;
  smallLod, largeLod: TGrLOD;
  aspectRatio: TGrAspectRatio;
  sClampMode, tClampMode: TGrTextureClampMode;
  minFilterMode, magFilterMode: TGrTextureFilterMode
  ): TFxBool; stdcall;
begin
  Trace(TraceFunc.guTexChangeAttributes);
  Store(mmid, sizeof(TGrMipMapId));
  Store(width, sizeof(integer));
  Store(height, sizeof(integer));
  Store(format, sizeof(TGrTextureFormat));
  Store(mmMode, sizeof(TGrMipMapMode));
  Store(smallLod, sizeof(TGrLOD));
  Store(largeLod, sizeof(TGrLOD));
  Store(aspectRatio, sizeof(TGrAspectRatio));
  Store(sClampMode, sizeof(TGrTextureClampMode));
  Store(tClampMode, sizeof(TGrTextureClampMode));
  Store(minFilterMode, sizeof(TGrTextureFilterMode));
  Store(magFilterMode, sizeof(TGrTextureFilterMode));

  Result := glide2x.guTexChangeAttributes(mmid, Width, Height, format, mmMode,
      smallLod, largeLod, aspectRatio, sClampMode, tClampMode, minFilterMode, magFilterMode);
end;

//guTexCombineFunction & grTexCombineFunction should match
procedure guTexCombineFunction(tmu: TGrChipID; func: TGrTextureCombineFnc); stdcall;
begin
  Trace(TraceFunc.guTexCombineFunction);
  Store(tmu, sizeof(TGrChipID));
  Store(func, sizeof(TGrTextureCombineFnc));
  glide2x.guTexCombineFunction(tmu, func);
end;

procedure grTexCombineFunction(tmu: TGrChipID; func: TGrTextureCombineFnc); stdcall;
begin
  Trace(TraceFunc.grTexCombineFunction);
  Store(tmu, sizeof(TGrChipID));
  Store(func, sizeof(TGrTextureCombineFnc));
  glide2x.grTexCombineFunction(tmu, func);
end;

procedure guTexDownloadMipMap(mmid: TGrMipMapId; const src: pointer; const nccTable: PGuNCCTable);
  stdcall;
var
  size: integer;
  info: PGrMipMapInfo;
begin
  Trace(TraceFunc.guTexDownloadMipMap);

  info := glide2x.guTexGetMipMapInfo(mmid);
  size := glide2x.grTexCalcMemRequired(info^.lod_min, info^.lod_max, info^.aspect_ratio, info^.format);
  //Trace(format('%dx%d, size: %d', [info^.width, info^.height, size]));

  Store(mmid, sizeof(TGrMipMapId));
  Store(size, 4);
  Store(pbyte(src)^, size);
  Store(nccTable^, sizeof(TGuNccTable));

  glide2x.guTexDownloadMipMap(mmid, src, nccTable);
end;

procedure guTexDownloadMipMapLevel(mmid: TGrMipMapId; lod: TGrLOD; const src: PPointer);
  stdcall;
begin
  Trace(TraceFunc.guTexDownloadMipMapLevel);
  glide2x.guTexDownloadMipMapLevel(mmid, lod, src);
end;

function guTexGetCurrentMipMap(tmu: TGrChipID): TGrMipMapId; stdcall;
begin
  Trace(TraceFunc.guTexGetCurrentMipMap);
  Result := glide2x.guTexGetCurrentMipMap(tmu);
end;

function guTexGetMipMapInfo(mmid: TGrMipMapId): PGrMipMapInfo; stdcall;
begin
  Trace(TraceFunc.guTexGetMipMapInfo);
  Result := glide2x.guTexGetMipMapInfo(mmid);
end;

function guTexMemQueryAvail(tmu: TGrChipID): TFxU32; stdcall;
begin
  Trace(TraceFunc.guTexMemQueryAvail);
  Result := glide2x.guTexMemQueryAvail(tmu);
end;

procedure guTexMemReset; stdcall;
begin
  Trace(TraceFunc.guTexMemReset);
  glide2x.guTexMemReset();
end;

procedure guTexSource(mmid: TGrMipMapId); stdcall;
begin
  Trace(TraceFunc.guTexSource);
  Store(mmid, SizeOf(TGrMipMapId));
  glide2x.guTexSource(mmid);
end;

{ functions exported from glide2x (FX_ENTRY) but not mentioned in ref. manual nor prog. guide }

procedure grCheckForRoom(n: TFxI32); stdcall;
begin
  Trace(TraceFunc.grCheckForRoom);
  glide2x.grCheckForRoom(n);
end;

procedure guDrawPolygonVertexListWithClip(nverts: integer; const vlist: PGrVertex); stdcall;
begin
  Trace(TraceFunc.guDrawPolygonVertexListWithClip);
  glide2x.guDrawPolygonVertexListWithClip(nverts, vlist);
end;

function guEndianSwapBytes(Value: TFxU32): TFxU32; stdcall;
begin
  Trace(TraceFunc.guEndianSwapBytes);
  Result := glide2x.guEndianSwapBytes(Value);
end;

function guEndianSwapWords(Value: TFxU32): TFxU32; stdcall;
begin
  Trace(TraceFunc.guEndianSwapWords);
  Result := glide2x.guEndianSwapWords(Value);
end;

function guEncodeRLE16(dst, src: pointer; Width, Height: TFxU32): integer; stdcall;
begin
  Trace(TraceFunc.guEncodeRLE16);
  Result := glide2x.guEncodeRLE16(dst, src, Width, Height);
end;

function guTexCreateColorMipMap(): PFxU16; stdcall;
begin
  Trace(TraceFunc.guTexCreateColorMipMap);
  Result := glide2x.guTexCreateColorMipMap();
end;

procedure ConvertAndDownloadRle(tmu: TGrChipID; startAddress: TFxU32; thisLod: TGrLOD;
  largeLod: TGrLOD; aspectRatio: TGrAspectRatio; format: TGrTextureFormat; evenOdd: TFxU32;
  bm_data: PFxU8; bm_h: longword; u0: TFxU32; v0: TFxU32; Width: TFxU32; Height: TFxU32;
  dest_width: TFxU32; dest_height: TFxU32; tlut: PFxU16); stdcall; assembler; nostackframe;
asm
    jmp glide2x.ConvertAndDownloadRle
end;

end.
