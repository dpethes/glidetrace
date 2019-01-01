unit funcreplay;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, glide2x, tracefile, display;

const
  MMID_TRANSLATION_TABLE_SIZE = $ffff;

var
  g_rep: record
      scratchpad: pbyte;  //multipurpose scratch buffer
      mmid_translation_table: PGrMipMapId;
      last_state: PGrState;

      //glide state
      hintmask: TFxU32;
      active_tmus: array[GR_TMU0..GR_TMU2] of boolean;

      //settings
      force_single_window: boolean;  //call sstWinOpen just once and don't close it
      window_opened: boolean;

      disable_tex: boolean;
      disable_gamma: boolean;
      disable_cull_mode: boolean;  //fixes debris in homeworld
      wireframe: boolean;
      force_tmu0: boolean;  //make all grTex/guTex calls use TMU0, can be useful for openglide

      frame_draw_call_skip: boolean;  //don't issue draw calls
  end;

procedure grSstWinOpen_do(disp: TDisplay);
procedure grSstWinClose_do(disp: TDisplay);
procedure grBufferClear_do;
procedure grRenderBuffer_do;
procedure grSstOrigin_do;
procedure grGlideGetState_do;
procedure grGlideSetState_do;

procedure grDrawPoint_do;
procedure grDrawLine_do;
procedure grDrawTriangle_do;
procedure grAADrawPoint_do;
procedure grAADrawLine_do;
procedure grAADrawTriangle_do;
procedure guDrawTriangleWithClip_do;
procedure grDrawPlanarPolygon_do;
procedure grDrawPlanarPolygonVertexList_do;
procedure grDrawPolygon_do;
procedure grDrawPolygonVertexList_do;

procedure grTexClampMode_do;
procedure grTexCombine_do;
procedure guTexCombineFunction_do;
procedure grTexDownloadMipMap_do;
procedure grTexDownloadMipMapLevel_do;
procedure grTexDownloadMipMapLevelPartial_do;
procedure grTexDownloadTable_do;
procedure grTexDownloadTablePartial_do;
procedure grTexFilterMode_do;
procedure grTexLodBiasValue_do;
procedure grTexMipMapMode_do;
procedure grTexSource_do;

procedure guTexAllocateMemory_do;
procedure guTexChangeAttributes_do;
procedure guTexDownloadMipMap_do;
procedure guTexMemReset_do;
procedure guTexSource_do;

procedure grChromakeyMode_do;
procedure grChromakeyValue_do;
procedure grClipWindow_do;
procedure grAlphaBlendFunction_do;
procedure grAlphaCombine_do;
procedure grAlphaTestFunction_do;
procedure grAlphaTestReferenceValue_do;
procedure grColorCombine_do;
procedure grColorMask_do;
procedure grConstantColorValue_do;
procedure grCullMode_do;
procedure grDepthBiasLevel_do;
procedure grDepthBufferFunction_do;
procedure grDepthBufferMode_do;
procedure grDepthMask_do;
procedure grDitherMode_do;

procedure grFogColorValue_do;
procedure grFogMode_do;
procedure grFogTable_do;

procedure grGammaCorrectionValue_do;
procedure grHints_do;

procedure guAlphaSource_do;
procedure guColorCombineFunction_do;

implementation

const
  //does something else besides 3dfx's opengl generate these large coords?
  VERTEX_SNAP_COMPARE = 4096.0;
  VERTEX_SNAP = single( 3 << 18 );  //see gdraw
  FORCE_RES_2X = false;

{ ================================================================================================ }
//mmid translation - just use a big enough buffer, nothing smart
procedure MmidStore(old_mmid, new_mmid: TGrMipMapId);
var
  i: integer;
begin
  i := old_mmid and MMID_TRANSLATION_TABLE_SIZE;
  g_rep.mmid_translation_table[i] := new_mmid;
  //writeln(old_mmid, ' -> ', new_mmid);
end;

function MmidTranslate(old_mmid: TGrMipMapId): TGrMipMapId;
var
  i: integer;
begin
  i := old_mmid and MMID_TRANSLATION_TABLE_SIZE;
  Result := g_rep.mmid_translation_table[i];
  //writeln(result, ' <- ', old_mmid);
end;


{ ================================================================================================ }
//parameter tracking & hooks
procedure TrackTMU(var tmu: TGrChipID);
begin
  if g_rep.force_tmu0 and (tmu <> GR_TMU0) then
      tmu := GR_TMU0;
  g_rep.active_tmus[tmu] := true;
end;

procedure VertexHook(var v: TGrVertex); inline;
begin
  if v.x > VERTEX_SNAP_COMPARE then begin
      v.x -= VERTEX_SNAP;
      v.y -= VERTEX_SNAP;
  end;
  if FORCE_RES_2X then begin
      v.x *= 2;
      v.y *= 2;
  end;
end;

procedure LoadVtx(out v: TGrVertex);
begin
  Load(v, sizeof(TGrVertex));
  VertexHook(v);
end;

procedure LoadVtxList(p: PGrVertex; count: integer);
var
  i: Integer;
begin
  Load(p^, count * sizeof(TGrVertex));
  for i := 0 to count - 1 do
      VertexHook(p[i]);
end;


{ ================================================================================================ }
{ SST routines }

procedure grSstWinOpen_do(disp: TDisplay);
const
  ResolutionList: array[0..$F] of array[0..1] of word = (
      (320, 200), (320, 240), (400, 256), (512, 384), (640, 200), (640, 350), (640, 400), (640, 480),
      (800, 600), (960, 720), (856, 480), (512, 256), (1024, 768), (1280, 1024), (1600, 1200), (400, 300)
      );
var
  resolution: TGrScreenResolution;
  refresh_rate: TGrScreenRefresh;
  color_format: TGrColorFormat;
  origin_location: TGrOriginLocation;
  nColBuffers: TFxI32;
  nAuxBuffers: TFxI32;
  Width, Height: word;
begin
  //hWnd is not stored
  Load(resolution, sizeof(TGrScreenResolution));
  Load(refresh_rate, sizeof(TGrScreenRefresh));
  Load(color_format, sizeof(TGrColorFormat));
  Load(origin_location, sizeof(TGrOriginLocation));
  Load(nColBuffers, sizeof(TFxI32));
  Load(nAuxBuffers, sizeof(TFxI32));

  if g_rep.window_opened and g_rep.force_single_window then
      exit;

  //not really a 2x, but ok for debugging lower res traces
  if FORCE_RES_2X then
      resolution := $d;

  Assert(resolution <> GR_RESOLUTION_NONE);
  Width  := ResolutionList[resolution][0];
  Height := ResolutionList[resolution][1];
  disp.InitDisplay(Width, Height);

  glide2x.grSstWinOpen(0, resolution, refresh_rate, color_format,
      origin_location, nColBuffers, nAuxBuffers);

  g_rep.window_opened := True;
end;

procedure grSstWinClose_do(disp: TDisplay);
begin
  if not g_rep.force_single_window then begin
      glide2x.grSstWinClose();
      disp.FreeDisplay;
      g_rep.window_opened := False;
  end;
end;

procedure grBufferClear_do;
var
  color: TGrColor;
  alpha: TGrAlpha;
  depth: TFxU32;
begin
  Load(color, sizeof(TGrColor));
  Load(alpha, sizeof(TGrAlpha));
  Load(depth, sizeof(TFxU32));
  grBufferClear(color, alpha, depth);
end;

procedure grRenderBuffer_do;
var
  buffer: TGrBuffer;
begin
  Load(buffer, sizeof(TGrBuffer));
  glide2x.grRenderBuffer(buffer);
end;

procedure grSstOrigin_do;
var
  origin: TGrOriginLocation;
begin
  Load(origin, sizeof(TGrOriginLocation));
  grSstOrigin(origin);
end;

procedure grGlideGetState_do;
begin
  glide2x.grGlideGetState(g_rep.last_state);
end;

procedure grGlideSetState_do;
begin
  glide2x.grGlideSetState(g_rep.last_state);
end;

{ ================================================================================================ }
{ rendering functions }

procedure grDrawPoint_do;
var
  a: TGrVertex;
begin
  LoadVtx(a);
  if g_rep.frame_draw_call_skip then
      exit;
  glide2x.grDrawPoint(@a);
end;

procedure grDrawLine_do;
var
  a, b: TGrVertex;
begin
  LoadVtx(a);
  LoadVtx(b);
  if g_rep.frame_draw_call_skip then
      exit;
  glide2x.grDrawLine(@a, @b);
end;

procedure grDrawTriangle_do;
var
  a, b, c: TGrVertex;
begin
  LoadVtx(a);
  LoadVtx(b);
  LoadVtx(c);

  if g_rep.frame_draw_call_skip then
      exit;
  if g_rep.wireframe then begin
      grDrawLine(@a, @b);
      grDrawLine(@b, @c);
      grDrawLine(@c, @a);
      exit;
  end;

  grDrawTriangle(@a, @b, @c);
end;

procedure guDrawTriangleWithClip_do;
var
  a, b, c: TGrVertex;
begin
  LoadVtx(a);
  LoadVtx(b);
  LoadVtx(c);

  if g_rep.frame_draw_call_skip then
      exit;
  if g_rep.wireframe then begin
      grDrawLine(@a, @b);
      grDrawLine(@b, @c);
      grDrawLine(@c, @a);
      exit;
  end;

  guDrawTriangleWithClip(@a, @b, @c);
end;

procedure grAADrawPoint_do;
var
  a: TGrVertex;
begin
  LoadVtx(a);
  if g_rep.frame_draw_call_skip then
      exit;
  glide2x.grAADrawPoint(@a);
end;

procedure grAADrawLine_do;
var
  a, b: TGrVertex;
begin
  LoadVtx(a);
  LoadVtx(b);
  if g_rep.frame_draw_call_skip then
      exit;
  glide2x.grAADrawLine(@a, @b);
end;

procedure grAADrawTriangle_do;
var
  a, b, c: TGrVertex;
  ab_antialias, bc_antialias, ca_antialias: TFxBOOL;
begin
  LoadVtx(a);
  LoadVtx(b);
  LoadVtx(c);
  Load(ab_antialias, sizeof(TFxBool));
  Load(bc_antialias, sizeof(TFxBool));
  Load(ca_antialias, sizeof(TFxBool));

  if g_rep.frame_draw_call_skip then
      exit;
  if g_rep.wireframe then begin
      grDrawLine(@a, @b);
      grDrawLine(@b, @c);
      grDrawLine(@c, @a);
      exit;
  end;

  glide2x.grAADrawTriangle(@a, @b, @c, ab_antialias, bc_antialias, ca_antialias);
end;

procedure grDrawPlanarPolygon_do;
var
  nverts: integer;
  ilist: PInteger;
  vlist: PGrVertex;
  i: integer;
begin
  Load(nverts, 4);
  ilist := PInteger(g_rep.scratchpad);
  vlist := PGrVertex(g_rep.scratchpad + nverts * 4);
  Load(ilist^, nverts * 4);
  Load(vlist^, nverts * sizeof(TGrVertex));

  if g_rep.frame_draw_call_skip then
      exit;
  //wrapper reorders the vlist, so index list can be skipped
  if g_rep.wireframe then begin
      for i := 0 to nverts - 2 do
          grDrawLine(@vlist[i], @vlist[i + 1]);
      exit;
  end;

  grDrawPlanarPolygon(nverts, ilist, vlist);
end;

procedure grDrawPlanarPolygonVertexList_do;
var
  nverts: integer;
  vlist: PGrVertex;
  i: integer;
begin
  vlist := PGrVertex(g_rep.scratchpad);
  Load(nverts, 4);
  LoadVtxList(vlist, nverts);

  if g_rep.frame_draw_call_skip then
      exit;
  if g_rep.wireframe then begin
      for i := 0 to nverts - 2 do
          grDrawLine(@vlist[i], @vlist[i + 1]);
      exit;
  end;

  grDrawPlanarPolygonVertexList(nverts, vlist);
end;

procedure grDrawPolygon_do;
var
  nverts: integer;
  ilist: PInteger;
  vlist: PGrVertex;
  i: integer;
begin
  Load(nverts, 4);
  ilist := PInteger(g_rep.scratchpad);
  vlist := PGrVertex(g_rep.scratchpad + nverts * 4);
  Load(ilist^, nverts * 4);
  LoadVtxList(vlist, nverts);

  if g_rep.frame_draw_call_skip then
      exit;
  //wrapper reorders the vlist, so index list can be skipped
  if g_rep.wireframe then begin
      for i := 0 to nverts - 2 do
          grDrawLine(@vlist[i], @vlist[i + 1]);
      exit;
  end;

  grDrawPolygon(nverts, ilist, vlist);
end;

procedure grDrawPolygonVertexList_do;
var
  nverts: integer;
  vlist: PGrVertex;
  i: integer;
begin
  vlist := PGrVertex(g_rep.scratchpad);
  Load(nverts, 4);
  LoadVtxList(vlist, nverts);

  if g_rep.frame_draw_call_skip then
      exit;
  if g_rep.wireframe then begin
      for i := 0 to nverts - 2 do
          grDrawLine(@vlist[i], @vlist[i + 1]);
      exit;
  end;

  grDrawPolygonVertexList(nverts, vlist);
end;

{ ================================================================================================ }
{ texture mapping & control + utility texture functions }

procedure grTexClampMode_do;
var
  tmu: TGrChipID;
  s_clampmode, t_clampmode: TGrTextureClampMode;
begin
  Load(tmu, sizeof(TGrChipID));
  Load(s_clampmode, sizeof(TGrTextureClampMode));
  Load(t_clampmode, sizeof(TGrTextureClampMode));
  TrackTMU(tmu);
  glide2x.grTexClampMode(tmu, s_clampmode, t_clampmode);
end;

procedure grTexCombine_do;
var
  tmu: TGrChipID;
  rgb_function: TGrCombineFunction;
  rgb_factor: TGrCombineFactor;
  alpha_function: TGrCombineFunction;
  alpha_factor: TGrCombineFactor;
  rgb_invert: TFxBOOL;
  alpha_invert: TFxBOOL;
begin
  Load(tmu, sizeof(TGrChipID));
  Load(rgb_function, sizeof(TGrCombineFunction));
  Load(rgb_factor, sizeof(TGrCombineFactor));
  Load(alpha_function, sizeof(TGrCombineLocal));
  Load(alpha_factor, sizeof(TGrCombineOther));
  Load(rgb_invert, sizeof(TFxBOOL));
  Load(alpha_invert, sizeof(TFxBOOL));

  if g_rep.disable_tex then
      exit;
  TrackTMU(tmu);
  glide2x.grTexCombine(tmu, rgb_function, rgb_factor, alpha_function, alpha_factor, rgb_invert, alpha_invert);
end;

procedure guTexCombineFunction_do;
var
  tmu: TGrChipID;
  fnc: TGrTextureCombineFnc;
begin
  Load(tmu, sizeof(TGrChipID));
  Load(fnc, sizeof(TGrTextureCombineFnc));
  if g_rep.disable_tex then
      exit;
  TrackTMU(tmu);
  glide2x.guTexCombineFunction(tmu, fnc);
end;

procedure grTexLodBiasValue_do;
var
  tmu: TGrChipID;
  bias: single;
begin
  Load(tmu, sizeof(TGrChipID));
  Load(bias, sizeof(single));
  TrackTMU(tmu);
  glide2x.grTexLodBiasValue(tmu, bias);
end;

procedure grTexDownloadMipMap_do;
var
  tmu: TGrChipID;
  startAddress, evenOdd: TFxU32;
  info: TGrTexInfo;
  size: Int32;
begin
  Load(tmu, sizeof(TGrChipID));
  Load(startAddress, sizeof(TFxU32));
  Load(evenOdd, sizeof(TFxU32));
  Load(info, sizeof(TGrTexInfo));

  info.Data := g_rep.scratchpad;
  Load(size, sizeof(Int32));
  Load(info.Data^, size);

  if g_rep.disable_tex then
      exit;
  TrackTMU(tmu);
  glide2x.grTexDownloadMipMap(tmu, startAddress, evenOdd, @info);
end;

procedure grTexDownloadMipMapLevel_do;
var
  tmu: TGrChipID;
  startAddress: TFxU32;
  thisLod: TGrLOD;
  largeLod: TGrLOD;
  aspectRatio: TGrAspectRatio;
  format: TGrTextureFormat;
  evenOdd: TFxU32;
  Data: Pointer;
  size: Int32;
begin
  Load(tmu, sizeof(TGrChipID));
  Load(startAddress, sizeof(TFxU32));
  Load(thisLod, sizeof(TGrLOD));
  Load(largeLod, sizeof(TGrLOD));
  Load(aspectRatio, sizeof(TGrAspectRatio));
  Load(format, sizeof(TGrTextureFormat));
  Load(evenOdd, sizeof(TFxU32));

  Data := g_rep.scratchpad;
  Load(size, 4);
  Load(PByte(Data)^, size);

  if g_rep.disable_tex then
      exit;
  TrackTMU(tmu);
  glide2x.grTexDownloadMipMapLevel(tmu, startAddress, thisLod, largeLod, aspectRatio, format, evenOdd, Data);
end;

{
OpenGlide ignores the start-end range and uploads the whole mip level, which is ok only if the game rewrites the original
texture data which it uploaded before, but doesn't work if it uses a scratch buffer for texture uploads.

Possible fixes:
- store all texture data, copy partial data into it and then pass to OpenGlide
- fix OpenGlide
Other wrappers seem to be ok
}
procedure grTexDownloadMipMapLevelPartial_do;
var
  tmu: TGrChipID;
  startAddress: TFxU32;
  thisLod: TGrLOD;
  largeLod: TGrLOD;
  aspectRatio: TGrAspectRatio;
  format: TGrTextureFormat;
  evenOdd: TFxU32;
  _start: TFxI32;
  _end: TFxI32;
  Data: Pointer;
  size: Int32;
begin
  Load(tmu, sizeof(TGrChipID));
  Load(startAddress, sizeof(TFxU32));
  Load(thisLod, sizeof(TGrLOD));
  Load(largeLod, sizeof(TGrLOD));
  Load(aspectRatio, sizeof(TGrAspectRatio));
  Load(format, sizeof(TGrTextureFormat));
  Load(evenOdd, sizeof(TFxU32));
  //load data as last
  Load(_start, sizeof(TFxI32));
  Load(_end, sizeof(TFxI32));

  Data := g_rep.scratchpad;
  Load(size, 4);
  Load(PByte(Data)^, size);

  if g_rep.disable_tex then
      exit;
  TrackTMU(tmu);
  glide2x.grTexDownloadMipMapLevelPartial(tmu, startAddress, thisLod, largeLod, aspectRatio, format, evenOdd,
      Data, _start, _end);
end;

procedure grTexDownloadTable_do;
var
  tmu: TGrChipID;
  _type: TGrTexTable;
  Data: Pointer;
  size: integer;
begin
  Load(tmu, sizeof(TGrChipID));
  Load(_type, sizeof(TGrTexTable));
  size := sizeof(TGuNccTable);
  if _type = GR_TEXTABLE_PALETTE then
      size := sizeof(TGuTexPalette);
  Data := g_rep.scratchpad;
  Load(Data^, size);

  TrackTMU(tmu);
  glide2x.grTexDownloadTable(tmu, _type, Data);
end;

procedure grTexDownloadTablePartial_do;
var
  tmu: TGrChipID;
  _type: TGrTexTable;
  Data: Pointer;
  _start: TFxI32;
  _end: TFxI32;
  size: integer;
begin
  Load(tmu, sizeof(TGrChipID));
  Load(_type, sizeof(TGrTexTable));
  Load(_start, sizeof(TGrChipID));
  Load(_end, sizeof(TGrChipID));

  Data := g_rep.scratchpad;
  size := (_end + 1 - _start) * sizeof(TFxU32);
  Load(Data^, size);

  TrackTMU(tmu);
  glide2x.grTexDownloadTablePartial(tmu, _type, Data, _start, _end);
end;


procedure grTexFilterMode_do;
var
  tmu: TGrChipID;
  minfilter_mode, magfilter_mode: TGrTextureFilterMode;
begin
  Load(tmu, sizeof(TGrChipID));
  Load(minfilter_mode, sizeof(TGrTextureFilterMode));
  Load(magfilter_mode, sizeof(TGrTextureFilterMode));
  TrackTMU(tmu);
  grTexFilterMode(tmu, minfilter_mode, magfilter_mode);
end;

procedure grTexMipMapMode_do;
var
  tmu: TGrChipID;
  mode: TGrMipMapMode;
  lodBlend: TFxBOOL;
begin
  Load(tmu, sizeof(TGrChipID));
  Load(mode, sizeof(TGrMipMapMode));
  Load(lodBlend, sizeof(TFxBOOL));
  TrackTMU(tmu);
  glide2x.grTexMipMapMode(tmu, mode, lodBlend);
end;

procedure grTexSource_do;
var
  tmu: TGrChipID;
  startAddress, evenOdd: TFxU32;
  info: TGrTexInfo;
begin
  Load(tmu, sizeof(TGrChipID));
  Load(startAddress, sizeof(TFxU32));
  Load(evenOdd, sizeof(TFxU32));
  Load(info, sizeof(TGrTexInfo));
  info.Data := nil;

  if g_rep.disable_tex then
      exit;
  TrackTMU(tmu);
  glide2x.grTexSource(tmu, startAddress, evenOdd, @info);
end;

procedure guTexAllocateMemory_do;
var
  tmu: TGrChipID;
  evenOddMask: TFxU8;
  Width, Height: integer;
  format: TGrTextureFormat;
  mmMode: TGrMipMapMode;
  smallLod, largeLod: TGrLOD;
  aspectRatio: TGrAspectRatio;
  sClampMode, tClampMode: TGrTextureClampMode;
  minFilterMode, magFilterMode: TGrTextureFilterMode;
  lodBias: single;
  lodBlend: TFxBool;
  mmid_old, mmid_new: TGrMipMapId;
begin
  Load(tmu, sizeof(TGrChipID));
  Load(evenOddMask, sizeof(TFxU8));
  Load(Width, sizeof(integer));
  Load(Height, sizeof(integer));
  Load(format, sizeof(TGrTextureFormat));
  Load(mmMode, sizeof(TGrMipMapMode));
  Load(smallLod, sizeof(TGrLOD));
  Load(largeLod, sizeof(TGrLOD));
  Load(aspectRatio, sizeof(TGrAspectRatio));
  Load(sClampMode, sizeof(TGrTextureClampMode));
  Load(tClampMode, sizeof(TGrTextureClampMode));
  Load(minFilterMode, sizeof(TGrTextureFilterMode));
  Load(magFilterMode, sizeof(TGrTextureFilterMode));
  Load(lodBias, sizeof(single));
  Load(lodBlend, sizeof(TFxBool));
  Load(mmid_old, sizeof(TGrMipMapId));

  if g_rep.disable_tex then
      exit;
  TrackTMU(tmu);

  mmid_new := glide2x.guTexAllocateMemory(tmu, evenOddMask, Width, Height, format, mmMode,
      smallLod, largeLod, aspectRatio, sClampMode, tClampMode, minFilterMode, magFilterMode, lodBias, lodBlend);

  MmidStore(mmid_old, mmid_new);
end;

procedure guTexChangeAttributes_do;
var
  mmid: TGrMipMapId;
  Width, Height: integer;
  format: TGrTextureFormat;
  mmMode: TGrMipMapMode;
  smallLod, largeLod: TGrLOD;
  aspectRatio: TGrAspectRatio;
  sClampMode, tClampMode: TGrTextureClampMode;
  minFilterMode, magFilterMode: TGrTextureFilterMode;
begin
  Load(mmid, sizeof(TGrMipMapId));
  Load(Width, sizeof(integer));
  Load(Height, sizeof(integer));
  Load(format, sizeof(TGrTextureFormat));
  Load(mmMode, sizeof(TGrMipMapMode));
  Load(smallLod, sizeof(TGrLOD));
  Load(largeLod, sizeof(TGrLOD));
  Load(aspectRatio, sizeof(TGrAspectRatio));
  Load(sClampMode, sizeof(TGrTextureClampMode));
  Load(tClampMode, sizeof(TGrTextureClampMode));
  Load(minFilterMode, sizeof(TGrTextureFilterMode));
  Load(magFilterMode, sizeof(TGrTextureFilterMode));

  if g_rep.disable_tex then
      exit;

  mmid := MmidTranslate(mmid);
  glide2x.guTexChangeAttributes(mmid, Width, Height, format, mmMode,
      smallLod, largeLod, aspectRatio, sClampMode, tClampMode, minFilterMode, magFilterMode);
end;

procedure guTexDownloadMipMap_do;
var
  mmid: TGrMipMapId;
  src: pbyte;
  nccTable: PGuNCCTable;
  size: integer;
begin
  Load(mmid, sizeof(TGrMipMapId));
  Load(size, 4);

  src := g_rep.scratchpad;
  nccTable := PGuNCCTable(g_rep.scratchpad + size + 64);
  Load(src^, size);
  Load(nccTable^, sizeof(TGuNccTable));

  if g_rep.disable_tex then
      exit;

  mmid := MmidTranslate(mmid);
  glide2x.guTexDownloadMipMap(mmid, src, nccTable);
end;

procedure guTexMemReset_do;
begin
  glide2x.guTexMemReset();
end;

procedure guTexSource_do;
var
  mmid: TGrMipMapId;
begin
  Load(mmid, SizeOf(TGrMipMapId));
  if g_rep.disable_tex then
      exit;

  mmid := MmidTranslate(mmid);
  glide2x.guTexSource(mmid);
end;

{ ================================================================================================ }
{ Glide configuration and special effect maintenance functions }

procedure grChromakeyMode_do;
var
  mode: TGrChromaKeyMode;
begin
  Load(mode, sizeof(TGrChromakeyMode));
  glide2x.grChromakeyMode(mode);
end;

procedure grChromakeyValue_do;
var
  Value: TGrColor;
begin
  Load(Value, sizeof(TGrColor));
  glide2x.grChromakeyValue(Value);
end;

procedure grClipWindow_do;
var
  minx, miny, maxx, maxy: TFxU32;
begin
  Load(minx, sizeof(TFxU32));
  Load(miny, sizeof(TFxU32));
  Load(maxx, sizeof(TFxU32));
  Load(maxy, sizeof(TFxU32));

  if FORCE_RES_2X then
      exit;

  grClipWindow(minx, miny, maxx, maxy);
end;

procedure grAlphaBlendFunction_do;
var
  rgb_sf, rgb_df, alpha_sf, alpha_df: TGrAlphaBlendFnc;
begin
  Load(rgb_sf, sizeof(TGrAlphaBlendFnc));
  Load(rgb_df, sizeof(TGrAlphaBlendFnc));
  Load(alpha_sf, sizeof(TGrAlphaBlendFnc));
  Load(alpha_df, sizeof(TGrAlphaBlendFnc));
  grAlphaBlendFunction(rgb_sf, rgb_df, alpha_sf, alpha_df);
end;

procedure grAlphaCombine_do;
var
  func: TGrCombineFunction;
  factor: TGrCombineFactor;
  local: TGrCombineLocal;
  other: TGrCombineOther;
  invert: TFxBOOL;
begin
  Load(func, sizeof(TGrCombineFunction));
  Load(factor, sizeof(TGrCombineFactor));
  Load(local, sizeof(TGrCombineLocal));
  Load(other, sizeof(TGrCombineOther));
  Load(invert, sizeof(TFxBOOL));
  grAlphaCombine(func, factor, local, other, invert);
end;

procedure grAlphaTestFunction_do;
var
  func: TGrCmpFnc;
begin
  Load(func, sizeof(TGrCmpFnc));
  glide2x.grAlphaTestFunction(func);
end;

procedure grAlphaTestReferenceValue_do;
var
  Value: TGrAlpha;
begin
  Load(Value, sizeof(TGrAlpha));
  glide2x.grAlphaTestReferenceValue(Value);
end;

procedure grColorCombine_do;
var
  func: TGrCombineFunction;
  factor: TGrCombineFactor;
  local: TGrCombineLocal;
  other: TGrCombineOther;
  invert: TFxBOOL;
begin
  Load(func, sizeof(TGrCombineFunction));
  Load(factor, sizeof(TGrCombineFactor));
  Load(local, sizeof(TGrCombineLocal));
  Load(other, sizeof(TGrCombineOther));
  Load(invert, sizeof(TFxBOOL));
  grColorCombine(func, factor, local, other, invert);
end;

procedure grColorMask_do;
var
  rgb, a: TFxBOOL;
begin
  Load(rgb, sizeof(TFxBOOL));
  Load(a, sizeof(TFxBOOL));
  grColorMask(rgb, a);
end;

procedure grConstantColorValue_do;
var
  Value: TGrColor;
begin
  Load(Value, sizeof(TGrColor));
  grConstantColorValue(Value);
end;

procedure grCullMode_do;
var
  mode: TGrCullMode;
begin
  Load(mode, sizeof(TGrCullMode));
  if g_rep.disable_cull_mode then
      exit;
  grCullMode(mode);
end;

procedure grDepthBiasLevel_do;
var
  level: TFxI32;
begin
  Load(level, sizeof(TFxI32));
  grDepthBiasLevel(level);
end;

procedure grDepthBufferFunction_do;
var
  func: TGrCmpFnc;
begin
  Load(func, sizeof(TGrCmpFnc));
  grDepthBufferFunction(func);
end;

procedure grDepthBufferMode_do;
var
  mode: TGrDepthBufferMode;
begin
  Load(mode, sizeof(TGrDepthBufferMode));
  grDepthBufferMode(mode);
end;

procedure grDepthMask_do;
var
  mask: TFxBOOL;
begin
  Load(mask, sizeof(TFxBOOL));
  grDepthMask(mask);
end;

procedure grDitherMode_do;
var
  mode: TGrDitherMode;
begin
  Load(mode, sizeof(TGrDitherMode));
  grDitherMode(mode);
end;

procedure grFogColorValue_do;
var
  fogcolor: TGrColor;
begin
  Load(fogcolor, sizeof(TGrColor));
  glide2x.grFogColorValue(fogcolor);
end;

procedure grFogMode_do;
var
  mode: TGrFogMode;
begin
  Load(mode, sizeof(TGrFogMode));
  glide2x.grFogMode(mode);
end;

procedure grFogTable_do;
var
  ft: PGrFog;
begin
  ft := g_rep.scratchpad;
  Load(ft^, GR_FOG_TABLE_SIZE);
  glide2x.grFogTable(ft);
end;

procedure grGammaCorrectionValue_do;
var
  Value: single;
begin
  Load(Value, sizeof(single));
  if not g_rep.disable_gamma then
      grGammaCorrectionValue(Value);
end;

procedure grHints_do;
var
  hintType: TGrHint;
  hintMask: TFxU32;
begin
  Load(hintType, sizeof(TGrHint));
  Load(hintMask, sizeof(TFxU32));
  grHints(hintType, hintMask);
  g_rep.hintmask := hintmask;
end;

procedure guAlphaSource_do;
var
  mode: TGrAlphaSource;
begin
  Load(mode, sizeof(TGrAlphaSource));
  glide2x.guAlphaSource(mode);
end;

procedure guColorCombineFunction_do;
var
  func: TGrColorCombineFnc;
begin
  Load(func, sizeof(TGrColorCombineFnc));
  guColorCombineFunction(func);
end;


end.
