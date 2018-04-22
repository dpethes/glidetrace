unit gli_common;

{$mode objfpc}{$H+}

interface

const
  //increase after incompatible trace format changes
  TRACE_VERSION = 12;

type
  //when adding traced functions add names in the same order as well (wrapped to 100 chars not including indentation)
  TraceFunc = (
      grAADrawLine, grAADrawPoint, grAADrawPolygon, grAADrawPolygonVertexList,
      grAADrawTriangle, grAlphaBlendFunction, grAlphaCombine, grAlphaControlsITRGBLighting,
      grAlphaTestFunction, grAlphaTestReferenceValue, grBufferClear, grBufferNumPending, grBufferSwap,
      grCheckForRoom, grChromakeyMode, grChromakeyValue, grClipWindow, grColorCombine, grColorMask,
      grConstantColorValue, grConstantColorValue4, grCullMode, grDepthBiasLevel, grDepthBufferFunction,
      grDepthBufferMode, grDepthMask, grDisableAllEffects, grDitherMode, grDrawLine, grDrawPlanarPolygon,
      grDrawPlanarPolygonVertexList, grDrawPoint, grDrawPolygon, grDrawPolygonVertexList, grDrawTriangle,
      grErrorSetCallback, grFogColorValue, grFogMode, grFogTable, grGammaCorrectionValue, grGlideGetState,
      grGlideGetVersion, grGlideInit, grGlideSetState, grGlideShamelessPlug, grGlideShutdown, grHints,
      grLfbConstantAlpha, grLfbConstantDepth, grLfbLock, grLfbReadRegion, grLfbUnlock,
      grLfbWriteColorFormat, grLfbWriteColorSwizzle, grLfbWriteRegion, grRenderBuffer, grResetTriStats,
      grSplash, grSstControl, grSstIdle, grSstIsBusy, grSstOrigin, grSstPerfStats, grSstQueryBoards,
      grSstQueryHardware, grSstResetPerfStats, grSstScreenHeight, grSstScreenWidth, grSstSelect,
      grSstStatus, grSstVRetraceOn, grSstVideoLine, grSstWinClose, grSstWinOpen, grTexCalcMemRequired,
      grTexClampMode, grTexCombine, grTexCombineFunction, grTexDetailControl, grTexDownloadMipMap,
      grTexDownloadMipMapLevel, grTexDownloadMipMapLevelPartial, grTexDownloadTable,
      grTexDownloadTablePartial, grTexFilterMode, grTexLodBiasValue, grTexMaxAddress, grTexMinAddress,
      grTexMipMapMode, grTexMultibase, grTexMultibaseAddress, grTexNCCTable, grTexSource,
      grTexTextureMemRequired, grTriStats,

      gu3dfGetInfo,
      gu3dfLoad,
      guAADrawTriangleWithClip,
      guAlphaSource,
      guColorCombineFunction,
      guDrawTriangleWithClip,
      guFogGenerateExp,
      guFogGenerateExp2,
      guFogGenerateLinear,
      guFogTableIndexToW,
      guTexAllocateMemory,
      guTexChangeAttributes,
      guTexCombineFunction,
      guTexDownloadMipMap,
      guTexDownloadMipMapLevel,
      guTexGetCurrentMipMap,
      guTexGetMipMapInfo,
      guTexMemQueryAvail,
      guTexMemReset,
      guTexSource,

      guDrawPolygonVertexListWithClip,
      guEncodeRLE16,
      guEndianSwapBytes,
      guEndianSwapWords,
      guTexCreateColorMipMap,
      ConvertAndDownloadRle
      );

const
  TraceFuncNames: array[TraceFunc] of PChar = (
      'grAADrawLine', 'grAADrawPoint', 'grAADrawPolygon',
      'grAADrawPolygonVertexList', 'grAADrawTriangle', 'grAlphaBlendFunction', 'grAlphaCombine',
      'grAlphaControlsITRGBLighting', 'grAlphaTestFunction', 'grAlphaTestReferenceValue', 'grBufferClear',
      'grBufferNumPending', 'grBufferSwap', 'grCheckForRoom', 'grChromakeyMode', 'grChromakeyValue',
      'grClipWindow', 'grColorCombine', 'grColorMask', 'grConstantColorValue', 'grConstantColorValue4',
      'grCullMode', 'grDepthBiasLevel', 'grDepthBufferFunction', 'grDepthBufferMode', 'grDepthMask',
      'grDisableAllEffects', 'grDitherMode', 'grDrawLine', 'grDrawPlanarPolygon',
      'grDrawPlanarPolygonVertexList', 'grDrawPoint', 'grDrawPolygon', 'grDrawPolygonVertexList',
      'grDrawTriangle', 'grErrorSetCallback', 'grFogColorValue', 'grFogMode', 'grFogTable',
      'grGammaCorrectionValue', 'grGlideGetState', 'grGlideGetVersion', 'grGlideInit', 'grGlideSetState',
      'grGlideShamelessPlug', 'grGlideShutdown', 'grHints', 'grLfbConstantAlpha', 'grLfbConstantDepth',
      'grLfbLock', 'grLfbReadRegion', 'grLfbUnlock', 'grLfbWriteColorFormat', 'grLfbWriteColorSwizzle',
      'grLfbWriteRegion', 'grRenderBuffer', 'grResetTriStats', 'grSplash', 'grSstControl', 'grSstIdle',
      'grSstIsBusy', 'grSstOrigin', 'grSstPerfStats', 'grSstQueryBoards', 'grSstQueryHardware',
      'grSstResetPerfStats', 'grSstScreenHeight', 'grSstScreenWidth', 'grSstSelect', 'grSstStatus',
      'grSstVRetraceOn', 'grSstVideoLine', 'grSstWinClose', 'grSstWinOpen', 'grTexCalcMemRequired',
      'grTexClampMode', 'grTexCombine', 'grTexCombineFunction', 'grTexDetailControl',
      'grTexDownloadMipMap', 'grTexDownloadMipMapLevel', 'grTexDownloadMipMapLevelPartial',
      'grTexDownloadTable', 'grTexDownloadTablePartial', 'grTexFilterMode', 'grTexLodBiasValue',
      'grTexMaxAddress', 'grTexMinAddress', 'grTexMipMapMode', 'grTexMultibase', 'grTexMultibaseAddress',
      'grTexNCCTable', 'grTexSource', 'grTexTextureMemRequired', 'grTriStats',

      'gu3dfGetInfo',
      'gu3dfLoad',
      'guAADrawTriangleWithClip',
      'guAlphaSource',
      'guColorCombineFunction',
      'guDrawTriangleWithClip',
      'guFogGenerateExp',
      'guFogGenerateExp2',
      'guFogGenerateLinear',
      'guFogTableIndexToW',
      'guTexAllocateMemory',
      'guTexChangeAttributes',
      'guTexCombineFunction',
      'guTexDownloadMipMap',
      'guTexDownloadMipMapLevel',
      'guTexGetCurrentMipMap',
      'guTexGetMipMapInfo',
      'guTexMemQueryAvail',
      'guTexMemReset',
      'guTexSource',

      'guDrawPolygonVertexListWithClip',
      'guEncodeRLE16',
      'guEndianSwapBytes',
      'guEndianSwapWords',
      'guTexCreateColorMipMap',
      'ConvertAndDownloadRle');


implementation

end.


