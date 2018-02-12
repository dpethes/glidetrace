{ Adapted to Glide2x from Glide3x.pas by Eric Unger and Marko Peric.
}
unit Glide2x;
{$mode delphi}
{$MINENUMSIZE 4}
{$ALIGN ON}

interface

uses
  dynlibs;
  
const
  GlideLibName = 'glide2x.dll';

{ 3dfx.h }

type
  TFxU8 = Byte;
  PFxU8 = ^TFxU8;
  TFxI8 = Int8;
  PFxI8 = ^TFxI8;
  TFxU16 = UInt16;
  PFxU16 = ^TFxU16;
  TFxI16 = Int16;
  PFxI16 = ^TFxI16;
  TFxI32 = Int32;
  PFxI32 = ^TFxI32;
  TFxU32 = UInt32;
  PFxU32 = ^TFxU32;
  TFxBool = LongBool;
  PFxBool = ^TFxBool;
  TFxFloat = Single;
  PFxFloat = ^TFxFloat;
  TFxDouble = Double;
  PFxDouble = ^TFxDouble;

  TFxColor = LongWord;
  PFxColor = ^TfxColor;
  
  PFxColor4 = ^TFxColor4;
  TFxColor4 = packed record
    r, g, b, a : single;
  end;

const
  FXTRUE = True;
  FXFALSE = False;

{ sst1vid.h }

type
  TGrScreenRefresh = TFxI32;
  TGrScreenResolution = TFxI32;
  
const
  GR_REFRESH_60Hz = $0;
  GR_REFRESH_70Hz = $1;
  GR_REFRESH_72Hz = $2;
  GR_REFRESH_75Hz = $3;
  GR_REFRESH_80Hz = $4;
  GR_REFRESH_90Hz = $5;
  GR_REFRESH_100Hz = $6;
  GR_REFRESH_85Hz = $7;
  GR_REFRESH_120Hz = $8;
  GR_REFRESH_NONE = $ff;

  GR_RESOLUTION_320x200 = $0;
  GR_RESOLUTION_320x240 = $1;
  GR_RESOLUTION_400x256 = $2;
  GR_RESOLUTION_512x384 = $3;
  GR_RESOLUTION_640x200 = $4;
  GR_RESOLUTION_640x350 = $5;
  GR_RESOLUTION_640x400 = $6;
  GR_RESOLUTION_640x480 = $7;
  GR_RESOLUTION_800x600 = $8;
  GR_RESOLUTION_960x720 = $9;
  GR_RESOLUTION_856x480 = $a;
  GR_RESOLUTION_512x256 = $b;
  GR_RESOLUTION_1024x768 = $C;
  GR_RESOLUTION_1280x1024 = $D;
  GR_RESOLUTION_1600x1200 = $E;
  GR_RESOLUTION_400x300 = $F;
  GR_RESOLUTION_NONE = $FF;
  //DP: there were some more resolutions added later in '99, but most likely nothing uses them

  GR_RESOLUTION_MIN = GR_RESOLUTION_320x200;
  GR_RESOLUTION_MAX = GR_RESOLUTION_1600x1200;

{ glidesys.h - build time configs }
  GLIDE_NUM_TMU  = 2;

{ glidesys.h }
{
-----------------------------------------------------------------------
TYPE DEFINITIONS
-----------------------------------------------------------------------
}
type
  TGrColor = TFxU32;
  PGrColor = PFxU32;
  TGrAlpha = TFxU8;
  PGrAlpha = PFxU8;
  TGrMipMapId = TFxU32;
  PGrMipMapId = PFxU32;
  TGrFog = TFxU8;
  PGrFog = PFxU8;
  TGrProc = Pointer;

{
-----------------------------------------------------------------------
CONSTANTS AND TYPES
-----------------------------------------------------------------------
}
const
  MAX_NUM_SST         = 4;
  MAX_MIPMAPS_PER_SST = 1024;

  GR_FOG_TABLE_SIZE   = 64;

  GR_NULL_MIPMAP_HANDLE = -1;
  GR_MIPMAPLEVELMASK_EVEN = 1 shl 0;
  GR_MIPMAPLEVELMASK_ODD = 1 shl 1;
  GR_MIPMAPLEVELMASK_BOTH = GR_MIPMAPLEVELMASK_EVEN or GR_MIPMAPLEVELMASK_ODD;

  GR_ZDEPTHVALUE_NEAREST  = $FFFF;
  GR_ZDEPTHVALUE_FARTHEST = $0000;
  GR_WDEPTHVALUE_NEAREST  = $0000;
  GR_WDEPTHVALUE_FARTHEST = $FFFF;

  GR_LODBIAS_BILINEAR  = 0.5;
  GR_LODBIAS_TRILINEAR = 0.0;

type
  TGrChipID = TFxI32;
const
  GR_TMU0 = $0;
  GR_TMU1 = $1;
  GR_TMU2 = $2;
  GR_FBI  = $3;

type
  TGrCombineFunction = TFxI32;
const
  GR_COMBINE_FUNCTION_ZERO = $0;
  GR_COMBINE_FUNCTION_NONE = GR_COMBINE_FUNCTION_ZERO;
  GR_COMBINE_FUNCTION_LOCAL = $1;
  GR_COMBINE_FUNCTION_LOCAL_ALPHA = $2;
  GR_COMBINE_FUNCTION_SCALE_OTHER = $3;
  GR_COMBINE_FUNCTION_BLEND_OTHER = GR_COMBINE_FUNCTION_SCALE_OTHER;
  GR_COMBINE_FUNCTION_SCALE_OTHER_ADD_LOCAL = $4;
  GR_COMBINE_FUNCTION_SCALE_OTHER_ADD_LOCAL_ALPHA = $5;
  GR_COMBINE_FUNCTION_SCALE_OTHER_MINUS_LOCAL = $6;
  GR_COMBINE_FUNCTION_SCALE_OTHER_MINUS_LOCAL_ADD_LOCAL = $7;
  GR_COMBINE_FUNCTION_BLEND = GR_COMBINE_FUNCTION_SCALE_OTHER_MINUS_LOCAL_ADD_LOCAL;
  GR_COMBINE_FUNCTION_SCALE_OTHER_MINUS_LOCAL_ADD_LOCAL_ALPHA = $8;
  GR_COMBINE_FUNCTION_SCALE_MINUS_LOCAL_ADD_LOCAL = $9;
  GR_COMBINE_FUNCTION_BLEND_LOCAL = GR_COMBINE_FUNCTION_SCALE_MINUS_LOCAL_ADD_LOCAL;
  GR_COMBINE_FUNCTION_SCALE_MINUS_LOCAL_ADD_LOCAL_ALPHA = $10;

type
  TGrCombineFactor = TFxI32;
const
  GR_COMBINE_FACTOR_ZERO = $0;
  GR_COMBINE_FACTOR_NONE = GR_COMBINE_FACTOR_ZERO;
  GR_COMBINE_FACTOR_LOCAL = $1;
  GR_COMBINE_FACTOR_OTHER_ALPHA = $2;
  GR_COMBINE_FACTOR_LOCAL_ALPHA = $3;
  GR_COMBINE_FACTOR_TEXTURE_ALPHA = $4;
  GR_COMBINE_FACTOR_TEXTURE_RGB = $5;
  GR_COMBINE_FACTOR_DETAIL_FACTOR = GR_COMBINE_FACTOR_TEXTURE_ALPHA;
  GR_COMBINE_FACTOR_LOD_FRACTION = $5;
  GR_COMBINE_FACTOR_ONE = $8;
  GR_COMBINE_FACTOR_ONE_MINUS_LOCAL = $9;
  GR_COMBINE_FACTOR_ONE_MINUS_OTHER_ALPHA = $a;
  GR_COMBINE_FACTOR_ONE_MINUS_LOCAL_ALPHA = $b;
  GR_COMBINE_FACTOR_ONE_MINUS_TEXTURE_ALPHA = $c;
  GR_COMBINE_FACTOR_ONE_MINUS_DETAIL_FACTOR = GR_COMBINE_FACTOR_ONE_MINUS_TEXTURE_ALPHA;
  GR_COMBINE_FACTOR_ONE_MINUS_LOD_FRACTION = $d;

type
  TGrCombineLocal = TFxI32;
const
  GR_COMBINE_LOCAL_ITERATED = $0;
  GR_COMBINE_LOCAL_CONSTANT = $1;
  GR_COMBINE_LOCAL_NONE = GR_COMBINE_LOCAL_CONSTANT;
  GR_COMBINE_LOCAL_DEPTH = $2;

type
  TGrCombineOther = TFxI32;
const
  GR_COMBINE_OTHER_ITERATED = $0;
  GR_COMBINE_OTHER_TEXTURE  = $1;
  GR_COMBINE_OTHER_CONSTANT = $2;
  GR_COMBINE_OTHER_NONE = GR_COMBINE_OTHER_CONSTANT;

type
  TGrAlphaSource = TFxI32;  //also GrAlphaSourceMode_t
const
  GR_ALPHASOURCE_CC_ALPHA = $0;
  GR_ALPHASOURCE_ITERATED_ALPHA = $1;
  GR_ALPHASOURCE_TEXTURE_ALPHA = $2;
  GR_ALPHASOURCE_TEXTURE_ALPHA_TIMES_ITERATED_ALPHA = $3;

type
  TGrColorCombineFnc = TFxI32; //also GrColorCombineFunction_t
const
  GR_COLORCOMBINE_ZERO = $0;
  GR_COLORCOMBINE_CCRGB = $1;
  GR_COLORCOMBINE_ITRGB = $2;
  GR_COLORCOMBINE_ITRGB_DELTA0 = $3;
  GR_COLORCOMBINE_DECAL_TEXTURE = $4;
  GR_COLORCOMBINE_TEXTURE_TIMES_CCRGB = $5;
  GR_COLORCOMBINE_TEXTURE_TIMES_ITRGB = $6;
  GR_COLORCOMBINE_TEXTURE_TIMES_ITRGB_DELTA0 = $7;
  GR_COLORCOMBINE_TEXTURE_TIMES_ITRGB_ADD_ALPHA = $8;
  GR_COLORCOMBINE_TEXTURE_TIMES_ALPHA = $9;
  GR_COLORCOMBINE_TEXTURE_TIMES_ALPHA_ADD_ITRGB = $a;
  GR_COLORCOMBINE_TEXTURE_ADD_ITRGB = $b;
  GR_COLORCOMBINE_TEXTURE_SUB_ITRGB = $c;
  GR_COLORCOMBINE_CCRGB_BLEND_ITRGB_ON_TEXALPHA = $d;
  GR_COLORCOMBINE_DIFF_SPEC_A = $e;
  GR_COLORCOMBINE_DIFF_SPEC_B = $f;
  GR_COLORCOMBINE_ONE = $10;

type
  TGrAlphaBlendFnc = TFxI32;
const
  GR_BLEND_ZERO = $0;
  GR_BLEND_SRC_ALPHA = $1;
  GR_BLEND_SRC_COLOR = $2;
  GR_BLEND_DST_COLOR = GR_BLEND_SRC_COLOR;
  GR_BLEND_DST_ALPHA = $3;
  GR_BLEND_ONE = $4;
  GR_BLEND_ONE_MINUS_SRC_ALPHA = $5;
  GR_BLEND_ONE_MINUS_SRC_COLOR = $6;
  GR_BLEND_ONE_MINUS_DST_COLOR = GR_BLEND_ONE_MINUS_SRC_COLOR;
  GR_BLEND_ONE_MINUS_DST_ALPHA = $7;
  GR_BLEND_RESERVED_8 = $8;
  GR_BLEND_RESERVED_9 = $9;
  GR_BLEND_RESERVED_A = $a;
  GR_BLEND_RESERVED_B = $b;
  GR_BLEND_RESERVED_C = $c;
  GR_BLEND_RESERVED_D = $d;
  GR_BLEND_RESERVED_E = $e;
  GR_BLEND_ALPHA_SATURATE = $f;
  GR_BLEND_PREFOG_COLOR = GR_BLEND_ALPHA_SATURATE;

type
  TGrAspectRatio = TFxI32;
const
  GR_ASPECT_8x1 = 0;
  GR_ASPECT_4x1 = 1;
  GR_ASPECT_2x1 = 2;
  GR_ASPECT_1x1 = 3;
  GR_ASPECT_1x2 = 4;
  GR_ASPECT_1x4 = 5;
  GR_ASPECT_1x8 = 6;

type
  TGrBuffer = TFxI32;
const
  GR_BUFFER_FRONTBUFFER = $0;
  GR_BUFFER_BACKBUFFER  = $1;
  GR_BUFFER_AUXBUFFER   = $2;
  GR_BUFFER_DEPTHBUFFER = $3;
  GR_BUFFER_ALPHABUFFER = $4;
  GR_BUFFER_TRIPLEBUFFER = $5;

type
  TGrChromakeyMode = TFxI32;
const
  GR_CHROMAKEY_DISABLE = $0;
  GR_CHROMAKEY_ENABLE = $1;

type
  TGrCmpFnc = TFxI32;
const
  GR_CMP_NEVER = $0;
  GR_CMP_LESS  = $1;
  GR_CMP_EQUAL = $2;
  GR_CMP_LEQUAL   = $3;
  GR_CMP_GREATER  = $4;
  GR_CMP_NOTEQUAL = $5;
  GR_CMP_GEQUAL = $6;
  GR_CMP_ALWAYS = $7;

type
  TGrColorFormat = TFxI32;
const
  GR_COLORFORMAT_ARGB = $0;
  GR_COLORFORMAT_ABGR = $1;
  GR_COLORFORMAT_RGBA = $2;
  GR_COLORFORMAT_BGRA = $3;

type
  TGrCullMode = TFxI32;
const
  GR_CULL_DISABLE = $0;  //also called GR_CULL_NONE in Glide PGM
  GR_CULL_NEGATIVE = $1;
  GR_CULL_POSITIVE = $2;

type
  TGrDepthBufferMode = TFxI32;
const
  GR_DEPTHBUFFER_DISABLE = $0;
  GR_DEPTHBUFFER_ZBUFFER = $1;
  GR_DEPTHBUFFER_WBUFFER = $2;
  GR_DEPTHBUFFER_ZBUFFER_COMPARE_TO_BIAS = $3;
  GR_DEPTHBUFFER_WBUFFER_COMPARE_TO_BIAS = $4;

type
  TGrDitherMode = TFxI32;
const
  GR_DITHER_DISABLE = $0;
  GR_DITHER_2x2 = $1;
  GR_DITHER_4x4 = $2;

type
  TGrFogMode = TFxI32;
const
  GR_FOG_DISABLE = $0;
  GR_FOG_WITH_ITERATED_ALPHA = $1;
  GR_FOG_WITH_TABLE          = $2;
  GR_FOG_WITH_ITERATED_Z     = $3;
  GR_FOG_MULT2 = $100;
  GR_FOG_ADD2  = $200;

type
  TGrLock = TFxU32;
const
  GR_LFB_READ_ONLY = $00;
  GR_LFB_WRITE_ONLY = $01;
  GR_LFB_IDLE = $00;
  GR_LFB_NOIDLE = $10;

type
  TGrLfbBypassMode = TFxI32;
const
  GR_LFBBYPASS_DISABLE = $0;
  GR_LFBBYPASS_ENABLE = $1;

type
  TGrLfbWriteMode = TFxI32;
const
  GR_LFBWRITEMODE_565 = $0; {/* RGB:RGB*/}
  GR_LFBWRITEMODE_555 = $1; {/* RGB:RGB*/}
  GR_LFBWRITEMODE_1555 = $2; {/* ARGB:ARGB*/}
  GR_LFBWRITEMODE_RESERVED1 = $3;
  GR_LFBWRITEMODE_888 = $4; {/* RGB*/}
  GR_LFBWRITEMODE_8888 = $5; {/* ARGB*/}
  GR_LFBWRITEMODE_RESERVED2 = $6;
  GR_LFBWRITEMODE_RESERVED3 = $7;
  GR_LFBWRITEMODE_RESERVED4 = $8;
  GR_LFBWRITEMODE_RESERVED5 = $9;
  GR_LFBWRITEMODE_RESERVED6 = $a;
  GR_LFBWRITEMODE_RESERVED7 = $b;
  GR_LFBWRITEMODE_565_DEPTH = $c; {/* RGB:DEPTH*/}
  GR_LFBWRITEMODE_555_DEPTH = $d; {/* RGB:DEPTH*/}
  GR_LFBWRITEMODE_1555_DEPTH = $e; {/* ARGB:DEPTH*/}
  GR_LFBWRITEMODE_ZA16 = $f; {/* DEPTH:DEPTH*/}
  GR_LFBWRITEMODE_ANY = $ff;


type
  TGrOriginLocation = TFxI32;
const
  GR_ORIGIN_UPPER_LEFT = $0;
  GR_ORIGIN_LOWER_LEFT = $1;
  GR_ORIGIN_ANY = $F;

type
  TGrLfbInfo = packed record
    size : Integer;
    lfbPtr : Pointer;
    strideInBytes : TFxU32;
    writeMode : TGrLfbWriteMode;
    origin : TGrOriginLocation;
  end {TGrLfbInfo};

type
  TGrLOD = TFxI32;
const
  GR_LOD_256 = $0;
  GR_LOD_128 = $1;
  GR_LOD_64  = $2;
  GR_LOD_32  = $3;
  GR_LOD_16  = $4;
  GR_LOD_8   = $5;
  GR_LOD_4   = $6;
  GR_LOD_2   = $7;
  GR_LOD_1   = $8;

type
  TGrMipMapMode = TFxI32;
const
  GR_MIPMAP_DISABLE = $0; {/* no mip mapping*/}
  GR_MIPMAP_NEAREST = $1; {/* use nearest mipmap*/}
  GR_MIPMAP_NEAREST_DITHER = $2; {/* GR_MIPMAP_NEAREST + LOD dith*/}

type
  TGrSmoothingMode = TFxI32;
const
  GR_SMOOTHING_DISABLE = $0;
  GR_SMOOTHING_ENABLE  = $1;

type
  TGrTextureClampMode = TFxI32;
const
  GR_TEXTURECLAMP_WRAP  = $0;
  GR_TEXTURECLAMP_CLAMP = $1;

type
  TGrTextureCombineFnc = TFxI32;
const
  GR_TEXTURECOMBINE_ZERO = $0; {/* texout = 0*/}
  GR_TEXTURECOMBINE_DECAL = $1; {/* texout = texthis*/}
  GR_TEXTURECOMBINE_OTHER = $2; {/* this TMU in passthru mode*/}
  GR_TEXTURECOMBINE_ADD = $3; {/* tout = tthis + t(this+1)*/}
  GR_TEXTURECOMBINE_MULTIPLY = $4; {/* texout = tthis* t(this+1)*/}
  GR_TEXTURECOMBINE_SUBTRACT = $5; {/* Subtract from upstream TMU*/}
  GR_TEXTURECOMBINE_DETAIL = $6; {/* detail--detail on tthis*/}
  GR_TEXTURECOMBINE_DETAIL_OTHER = $7; {/* detail--detail on tthis+1*/}
  GR_TEXTURECOMBINE_TRILINEAR_ODD = $8; {/* trilinear--odd levels tthis*/}
  GR_TEXTURECOMBINE_TRILINEAR_EVEN = $9; {/*trilinear--even levels tthis*/}
  GR_TEXTURECOMBINE_ONE = $a; {/* texout = 0xFFFFFFFF*/}

type
  TGrTextureFilterMode = TFxI32;
const
  GR_TEXTUREFILTER_POINT_SAMPLED = $0;
  GR_TEXTUREFILTER_BILINEAR      = $1;

type
  TGrTextureFormat = TFxI32;
const
  GR_TEXFMT_8BIT = $0;
  GR_TEXFMT_RGB_332 = GR_TEXFMT_8BIT;
  GR_TEXFMT_YIQ_422 = $1;
  GR_TEXFMT_ALPHA_8 = $2; {/* (0..0xFF) alpha*/}
  GR_TEXFMT_INTENSITY_8 = $3; {/* (0..0xFF) intensity*/}
  GR_TEXFMT_ALPHA_INTENSITY_44 = $4;
  GR_TEXFMT_P_8 = $5; {/* 8-bit palette*/}
  GR_TEXFMT_RSVD0 = $6;
  GR_TEXFMT_RSVD1 = $7;
  GR_TEXFMT_16BIT = $8;
  GR_TEXFMT_ARGB_8332 = GR_TEXFMT_16BIT;
  GR_TEXFMT_AYIQ_8422 = $9;
  GR_TEXFMT_RGB_565 = $a;
  GR_TEXFMT_ARGB_1555 = $b;
  GR_TEXFMT_ARGB_4444 = $c;
  GR_TEXFMT_ALPHA_INTENSITY_88 = $d;
  GR_TEXFMT_AP_88 = $e; {/* 8-bit alpha 8-bit palette*/}
  GR_TEXFMT_RSVD2 = $f;

type
  TGrTexTable = TFxU32;
const
  GR_TEXTABLE_NCC0 = $0;
  GR_TEXTABLE_NCC1 = $1;
  GR_TEXTABLE_PALETTE = $2;
  GR_TEX_NCC0 = GR_TEXTABLE_NCC0;  //same, with different names in PGM
  GR_TEX_NCC1 = GR_TEXTABLE_NCC1;
  GR_TEX_PALETTE = GR_TEXTABLE_PALETTE;

type
  TGrNCCTable = TFxU32;
  PGrNCCTable = ^TGrNCCTable;
const
  GR_NCCTABLE_NCC0 = $0;
  GR_NCCTABLE_NCC1 = $1;

type
  TGrTexBaseRange = TFxU32;
const
  GR_TEXBASE_256 = $0;
  GR_TEXBASE_128 = $1;
  GR_TEXBASE_64  = $2;
  GR_TEXBASE_32_TO_1 = $3;

const
  GLIDE_STATE_PAD_SIZE = 312;
type
  PGrState = ^TGrState;
  TGrState = array[0..GLIDE_STATE_PAD_SIZE-1] of byte;

{
-----------------------------------------------------------------------
STRUCTURES
-----------------------------------------------------------------------
}

type
  PGrTexInfo = ^TGrTexInfo;
  TGrTexInfo = packed record
    smallLod: TGrLOD;
    largeLod: TGrLOD;
    aspectRatio: TGrAspectRatio;
    format: TGrTextureFormat;
    data: Pointer;
  end;

  PGu3dfHeader = ^TGu3dfHeader;
  TGu3dfHeader = record
    width : TFxU32;
    height : TFxU32;
    small_lod : longint;
    large_lod : longint;
    aspect_ratio : TGrAspectRatio;
    format : TGrTextureFormat;
  end;

  PGuNccTable = ^TGuNccTable;
  TGuNccTable = record
    yRGB : array[0..15] of TFxU8;
    iRGB : array[0..3] of array[0..2] of TFxI16;
    qRGB : array[0..3] of array[0..2] of TFxI16;
    packed_data : array[0..11] of TFxU32;
  end;

  PGuTexPalette = ^TGuTexPalette;
  TGuTexPalette = record
    data : array[0..255] of TFxU32;
  end;

  PGuTexTable = ^TGuTexTable;
  TGuTexTable = record
    case longint of
      0 : ( nccTable : TGuNccTable );
      1 : ( palette : TGuTexPalette );
    end;

  PGu3dfInfo = ^TGu3dfInfo;
  TGu3dfInfo = record
    header : TGu3dfHeader;
    table : TGuTexTable;
    data : pointer;
    mem_required : TFxU32;
  end;

  PGrMipMapInfo = ^TGrMipMapInfo;
  TGrMipMapInfo = record
    sst : longint;
    valid : TFxBool;
    width : integer;
    height : integer;
    aspect_ratio : TGrAspectRatio;
    data : pointer;
    format : TGrTextureFormat;
    mipmap_mode : TGrMipMapMode;
    magfilter_mode : TGrTextureFilterMode;
    minfilter_mode : TGrTextureFilterMode;
    s_clamp_mode : TGrTextureClampMode;
    t_clamp_mode : TGrTextureClampMode;
    tLOD : TFxU32;
    tTextureMode : TFxU32;
    lod_bias : TFxU32;
    lod_min : TGrLOD;
    lod_max : TGrLOD;
    tmu : integer;
    odd_even_mask : TFxU32;
    tmu_base_address : TFxU32;
    trilinear : TFxBool;
    ncc_table : TGuNccTable;
  end;

type
  TGrSstType = integer;
const
  GR_SSTTYPE_VOODOO   = 0;
  GR_SSTTYPE_SST96    = 1;  //Voodoo Rush
  GR_SSTTYPE_AT3D     = 2;  //Rush + Alliance Semiconductor AT25/AT3D 2D?
  GR_SSTTYPE_Voodoo2  = 3;

type
  TGrTMUConfig = record
    tmuRev: integer;
    tmuRam: integer;
  end;

  TGrVoodooConfig = record
    fbRam: integer;
    fbiRev: integer;
    nTexelFx: integer;
    sliDetect: integer;  //FXBool
    tmuConfig: array[0.. GLIDE_NUM_TMU-1] of TGrTMUConfig;
  end;

  TGrSst96Config = record
    fbRam: integer;
    nTexelFx: integer;
    tmuConfig: TGrTMUConfig;
  end;

  TGrVoodoo2Config = TGrVoodooConfig;

  TGrAT3DConfig = record
    rev: integer;
  end;

  TSstBoard = record
    case byte of
      0: (VoodooConfig: TGrVoodooConfig);
      1: (SST96Config: TGrSst96Config);
      2: (AT3DConfig: TGrAT3DConfig);
      3: (Voodoo2Config: TGrVoodoo2Config);
  end;

  TSstHw = record
    type_: TGrSstType;
    sstBoard: TSstBoard;
  end;

  TGrHwConfiguration = record
    num_sst: integer;
    SSTs: array[0..MAX_NUM_SST] of TSstHw;
  end;
  PGrHwConfiguration = ^TGrHwConfiguration;

  PGrSstPerfStats = ^TGrSstPerfStats;
  TGrSstPerfStats = record
    pixelsIn : TFxU32; {/* # pixels processed (minus buffer clears)*/ }
    chromaFail : TFxU32; {/* # pixels not drawn due to chroma key*/ }
    zFuncFail : TFxU32; {/* # pixels not drawn due to Z comparison*/ }
    aFuncFail : TFxU32; {/* # pixels not drawn due to alpha comparison*/ }
    pixelsOut : TFxU32; {/* # pixels drawn (including buffer clears)*/ }
  end;

  TGrTmuVertex = record
    sow: single;       (* s texture ordinate (s over w) *)
    tow: single;       (* t texture ordinate (t over w) *)
    oow: single;       (* 1/w (used mipmapping - really 0xfff/w) *)
  end;

  TGrVertex = record
    x, y, z: single;                (* X, Y, and Z of scrn space -- Z is ignored *)
    r, g, b: single;                (* R, G, B, ([0..255.0]) *)
    ooz: single;                    (* 65535/Z (used for Z-buffering) *)
    a: single;                      (* Alpha [0..255.0] *)
    oow: single;                    (* 1/W (used for W-buffering, texturing) *)
    tmuvtx: array [0..GLIDE_NUM_TMU-1] of TGrTmuVertex;
  end;
  PGrVertex = ^TGrVertex;


type
  TGrLfbSrcFmt = TFxU32;
const
  GR_LFB_SRC_FMT_565        = $00;
  GR_LFB_SRC_FMT_555        = $01;
  GR_LFB_SRC_FMT_1555       = $02;
  GR_LFB_SRC_FMT_888        = $04;
  GR_LFB_SRC_FMT_8888       = $05;
  GR_LFB_SRC_FMT_565_DEPTH  = $0c;
  GR_LFB_SRC_FMT_555_DEPTH  = $0d;
  GR_LFB_SRC_FMT_1555_DEPTH = $0e;
  GR_LFB_SRC_FMT_ZA16       = $0f;
  GR_LFB_SRC_FMT_RLE16      = $80;

type
  TGrHint = TFxU32;
const
  GR_HINTTYPE_MIN             = 0;
  GR_HINT_STWHINT             = 0;
  GR_HINT_FIFOCHECKHINT       = 1;
  GR_HINT_FPUPRECISION        = 2;
  GR_HINT_ALLOW_MIPMAP_DITHER = 3;
  GR_HINT_LFB_WRITE           = 4;
  GR_HINT_LFB_PROTECT         = 5;
  GR_HINT_LFB_RESET           = 6;
  GR_HINTTYPE_MAX             = GR_HINT_LFB_RESET;

type
  TGrSTWHint = TFxU32;
const
  GR_STWHINT_W_DIFF_FBI   = 1 << 0;
  GR_STWHINT_W_DIFF_TMU0  = 1 << 1;
  GR_STWHINT_ST_DIFF_TMU0 = 1 << 2;
  GR_STWHINT_W_DIFF_TMU1  = 1 << 3;
  GR_STWHINT_ST_DIFF_TMU1 = 1 << 4;
  GR_STWHINT_W_DIFF_TMU2  = 1 << 5;
  GR_STWHINT_ST_DIFF_TMU2 = 1 << 6;

type
  TGrControl = TFxU32;
const
  GR_CONTROL_ACTIVATE   = $1;
  GR_CONTROL_DEACTIVATE = $2;
  GR_CONTROL_RESIZE     = $3;
  GR_CONTROL_MOVE       = $4;

{
-----------------------------------------------------------------------
FUNCTION PROTOTYPES
-----------------------------------------------------------------------
}
type
  TGrErrorCallbackFnc = procedure(str : PChar; Fatal : TFxBool); stdcall;

var
{ rendering functions }
  grDrawPlanarPolygon: procedure(nverts: integer; const ilist: PInteger; const vlist: PGrVertex); stdcall;
  grDrawPlanarPolygonVertexList: procedure(nverts: integer; const vlist: PGrVertex); stdcall;
  grDrawPolygon: procedure(nverts: integer; const ilist: PInteger; const vlist: PGrVertex); stdcall;
  grDrawPolygonVertexList: procedure(nverts: integer; const vlist: PGrVertex); stdcall;
  grDrawPoint: procedure(const pt: PGrVertex); stdcall;
  grDrawLine: procedure(const v1, v2: PGrVertex); stdcall;
  grDrawTriangle: procedure(const a, b, c: PGrVertex); stdcall;

{ buffer management }
  grBufferClear: procedure(color: TGrColor; alpha: TGrAlpha; depth: TFxU32); stdcall;
  grBufferNumPending: procedure; stdcall;
  grBufferSwap: procedure(swap_interval: TFxU32); stdcall;
  grRenderBuffer: procedure(buffer: TGrBuffer); stdcall;

{ error management }
  grErrorSetCallback: procedure(fnc: TGrErrorCallbackFnc); stdcall;

{ SST routines }
  grSstIdle: procedure; stdcall;
  grSstVideoLine: function: TFxU32; stdcall;
  grSstVRetraceOn: function: TFxBool; stdcall;
  grSstIsBusy: function: TFxBool; stdcall;

  grSstWinOpen: function(
      hWnd : TFxU32;
      screen_resolution : TGrScreenResolution;
      refresh_rate : TGrScreenRefresh;
      color_format : TGrColorFormat;
      origin_location : TGrOriginLocation;
      nColBuffers : TFxI32;
      nAuxBuffers : TFxI32): TFxBool; stdcall;

  grSstWinClose: procedure; stdcall;
  grSstControl: function(code: TGrControl): TFxBOOL; stdcall;
  grSstQueryHardware: function(hwconfig: PGrHwConfiguration): TFxBOOL; stdcall;
  grSstQueryBoards: function(hwconfig: PGrHwConfiguration): TFxBOOL; stdcall;
  grSstOrigin: procedure(origin: TGrOriginLocation); stdcall;
  grSstSelect: procedure(which_sst: TFxI32); stdcall;
  grSstScreenHeight: function: TFxU32; stdcall;
  grSstScreenWidth: function: TFxU32; stdcall;
  grSstStatus: function: TFxU32; stdcall;

{ Drawing Statistics }
  grSstPerfStats: procedure(pStats: PGrSstPerfStats); stdcall;
  grSstResetPerfStats: procedure; stdcall;
  grResetTriStats: procedure; stdcall;
  grTriStats: procedure(trisProcessed: PFxU32; trisDrawn: PFxU32); stdcall;

{ Glide configuration and special effect maintenance functions }
  grAlphaBlendFunction : procedure(rgb_sf, rgb_df, alpha_sf, alpha_df: TGrAlphaBlendFnc); stdcall;
  grAlphaCombine : procedure(func : TGrCombineFunction;
                             factor : TGrCombineFactor;
                             local : TGrCombineLocal;
                             other : TGrCombineOther;
                             invert : TFxBOOL); stdcall;
  grAlphaControlsITRGBLighting : procedure(enable : TFxBOOL); stdcall;
  grAlphaTestFunction : procedure(func : TGrCmpFnc); stdcall;
  grAlphaTestReferenceValue : procedure(value : TGrAlpha); stdcall;
  grChromakeyMode : procedure(mode : TGrChromaKeyMode); stdcall;
  grChromakeyValue : procedure(value : TGrColor); stdcall;
  grClipWindow : procedure(minx, miny, maxx, maxy : TFxU32); stdcall;
  grColorCombine : procedure(func : TGrCombineFunction;
                             factor : TGrCombineFactor;
                             local : TGrCombineLocal;
                             other : TGrCombineOther;
                             invert : TFxBOOL); stdcall;
  grColorMask : procedure(rgb, a : TFxBOOL); stdcall;
  grCullMode : procedure(mode : TGrCullMode); stdcall;
  grConstantColorValue : procedure(value : TGrColor); stdcall;
  grConstantColorValue4 : procedure(a, r, g, b: single); stdcall;
  grDepthBiasLevel : procedure(level : TFxI32); stdcall;
  grDepthBufferFunction : procedure(func : TGrCmpFnc); stdcall;
  grDepthBufferMode : procedure(mode : TGrDepthBufferMode); stdcall;
  grDepthMask : procedure(mask : TFxBOOL); stdcall;
  grDisableAllEffects : procedure; stdcall;
  grDitherMode : procedure(mode : TGrDitherMode); stdcall;
  grFogColorValue : procedure(fogcolor : TGrColor); stdcall;
  grFogMode : procedure(mode : TGrFogMode); stdcall;
  grFogTable : procedure(const ft : PGrFog); stdcall;
  grGammaCorrectionValue: procedure(value: single); stdcall;
  grSplash : procedure(x, y, width, height : Single; frame : TFxU32); stdcall;

{ texture mapping control functions }
  grTexCalcMemRequired : function(lodmin, lodmax : TGrLOD;
                                  aspect : TGrAspectRatio;
                                  fmt : TGrTextureFormat) : TFxU32; stdcall;
  grTexTextureMemRequired: function(evenOdd: TFxU32; info: PGrTexInfo): TFxU32; stdcall;
  grTexMinAddress : function(tmu: TGrChipID) : TFxU32; stdcall;
  grTexMaxAddress : function(tmu: TGrChipID) : TFxU32; stdcall;
  grTexNCCTable: procedure(tmu: TGrChipID; table : TGrNccTable); stdcall;
  grTexSource: procedure(tmu: TGrChipID; startAddress, evenOdd: TFxU32; info: PGrTexInfo); stdcall;
  grTexClampMode : procedure(tmu : TGrChipID; s_clampmode, t_clampmode: TGrTextureClampMode); stdcall;
  grTexCombine : procedure(tmu : TGrChipID;
                           rgb_function : TGrCombineFunction;
                           rgb_factor : TGrCombineFactor;
                           alpha_function : TGrCombineFunction;
                           alpha_factor : TGrCombineFactor;
                           rgb_invert : TFxBOOL;
                           alpha_invert : TFxBOOL); stdcall;
  grTexDetailControl : procedure(tmu : TGrChipID;
                                 lod_bias : Integer;
                                 detail_scale : TFxU8;
                                 detail_max : Single); stdcall;
  grTexFilterMode : procedure(tmu : TGrChipID; minfilter_mode, magfilter_mode : TGrTextureFilterMode); stdcall;
  grTexLodBiasValue : procedure(tmu : TGrChipID; bias : Single); stdcall;
  grTexDownloadMipMap: procedure(tmu: TGrChipID; startAddress, evenOdd: TFxU32; info: PGrTexInfo); stdcall;
  grTexDownloadMipMapLevel : procedure(tmu : TGrChipID;
                                       startAddress : TFxU32;
                                       thisLod : TGrLOD;
                                       largeLod : TGrLOD;
                                       aspectRatio : TGrAspectRatio;
                                       format : TGrTextureFormat;
                                       evenOdd : TFxU32;
                                       data : Pointer); stdcall;
  grTexDownloadMipMapLevelPartial : procedure(
      tmu : TGrChipID;
      startAddress : TFxU32;
      thisLod : TGrLOD;
      largeLod : TGrLOD;
      aspectRatio : TGrAspectRatio;
      format : TGrTextureFormat;
      evenOdd : TFxU32;
      data : Pointer;
      _start : TFxI32;
      _end : TFxI32); stdcall;
  grTexDownloadTable: procedure(tmu: TGrChipID; _type: TGrTexTable; data: Pointer); stdcall;
  grTexDownloadTablePartial: procedure(
      tmu: TGrChipID;
      _type: TGrTexTable;
      data: Pointer;
      _start: TFxI32;
      _end: TFxI32); stdcall;
  grTexMipMapMode : procedure(tmu : TGrChipID;
                              mode : TGrMipMapMode;
                              lodBlend : TFxBOOL); stdcall;
  grTexMultibase : procedure(tmu : TGrChipID;
                           enable : TFxBOOL); stdcall;
  grTexMultibaseAddress : procedure(tmu : TGrChipID;
                                    range : TGrTexBaseRange;
                                    startAddress : TFxU32;
                                    evenOdd : TFxU32;
                                    var info : TGrTexInfo); stdcall;

{ utility texture functions }
  guTexAllocateMemory: function(
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
      lodBlend: TFxBool): TGrMipMapId; stdcall;
  guTexChangeAttributes: function(
      mmid: TGrMipMapId;
      width, height: integer;
      format: TGrTextureFormat;
      mmMode: TGrMipMapMode;
      smallLod, largeLod: TGrLOD;
      aspectRatio: TGrAspectRatio;
      sClampMode, tClampMode: TGrTextureClampMode;
      minFilterMode, magFilterMode: TGrTextureFilterMode): TFxBool; stdcall;
  guTexCombineFunction: procedure(tmu: TGrChipID; func: TGrTextureCombineFnc); stdcall;
  guTexDownloadMipMap: procedure(mmid: TGrMipMapId; const src: pointer; const nccTable: PGuNccTable); stdcall;
  guTexDownloadMipMapLevel: procedure(mmid: TGrMipMapId; lod: TGrLOD; const src: PPointer); stdcall;
  guTexGetCurrentMipMap: function(tmu: TGrChipID): TGrMipMapId; stdcall;
  guTexGetMipMapInfo: function(mmid: TGrMipMapId): PGrMipMapInfo; stdcall;
  guTexMemQueryAvail: function(tmu: TGrChipID): TFxU32; stdcall;
  guTexMemReset: procedure; stdcall;
  guTexSource: procedure(mmid: TGrMipMapId); stdcall;


{ linear frame buffer functions }
  grLfbLock : function(_type : TGrLock;
                       buffer : TGrBuffer;
                       writeMode : TGrLFBWriteMode;
                       origin : TGrOriginLocation;
                       pixelPipeline : TFxBOOL;
                       var info : TGrLFBInfo) : TFxBOOL; stdcall;
  grLfbUnlock : function(_type : TGrLock;
                         buffer : TGrBuffer) : TFxBOOL; stdcall;
  grLfbConstantAlpha : procedure(alpha : TGrAlpha); stdcall;
  grLfbConstantDepth: procedure(depth: TFxU16); stdcall;
  grLfbWriteColorSwizzle : procedure(swizzleBytes : TFxBOOL;
                                     swapWords : TFxBOOL); stdcall;
  grLfbWriteColorFormat : procedure(colorFormat : TGrColorFormat); stdcall;
  grLfbWriteRegion : function(dst_buffer : TGrBuffer;
                              dst_x, dst_y : TFxU32;
                              src_format : TGrLFBSrcFmt;
                              src_width : TFxU32;
                              src_height : TFxU32;
                              src_stride : TFxI32;
                              src_data : Pointer) : TFxBOOL; stdcall;
  grLfbReadRegion : function(src_buffer : TGrBuffer;
                             src_x, src_y, src_width, src_height, dst_stride : TFxU32;
                             dst_data : Pointer): TFxBOOL; stdcall;

{ Antialiasing Functions }
  grAADrawLine: procedure(const v1, v2: PGrVertex); stdcall;
  grAADrawPoint: procedure(const pt: PGrVertex); stdcall;
  grAADrawPolygon: procedure(const nverts: integer; const ilist: PInteger; const vlist: PGrVertex); stdcall;
  grAADrawPolygonVertexList: procedure(const nverts: integer; const vlist: PGrVertex); stdcall;
  grAADrawTriangle: procedure(const a, b, c: PGrVertex; ab_antialias, bc_antialias, ca_antialias: TFxBOOL); stdcall;

{ glide management functions }
  grGlideInit: procedure; stdcall;
  grGlideShutdown: procedure; stdcall;
  grGlideGetVersion: procedure(version: pchar); stdcall;  //expects char[80] buffer
  grGlideGetState: procedure(state: PGrState); stdcall;
  grGlideSetState: procedure(const state: PGrState); stdcall;
  grGlideShamelessPlug: procedure(on_: TFxBool); stdcall;
  grHints: procedure(hintType: TGrHint; hintMask:TFxU32); stdcall;

{ utility functions }
  gu3dfGetInfo: function(const filename: pchar; info: PGu3dfInfo): TFxBool; stdcall;
  gu3dfLoad: function(const filename: pchar; info: PGu3dfInfo): TFxBool; stdcall;
  guAADrawTriangleWithClip: procedure(const a, b, c: PGrVertex); stdcall;
  guAlphaSource: procedure(mode: TGrAlphaSource); stdcall;
  guColorCombineFunction: procedure(func: TGrColorCombineFnc); stdcall;
  guDrawTriangleWithClip: procedure(const a, b, c: PGrVertex); stdcall;
  guFogGenerateExp: procedure(fogTable: PGrFog; density: single); stdcall;  //expects fogTable[GR_FOG_TABLE_SIZE]
  guFogGenerateExp2: procedure(fogTable: PGrFog; density: single); stdcall;
  guFogGenerateLinear: procedure(fogTable: PGrFog; nearW, farW: single); stdcall;
  guFogTableIndexToW: function(i: integer): single; stdcall;

{ functions exported from glide2x (FX_ENTRY) but not mentioned in ref. manual nor prog. guide }
  grTexCombineFunction: procedure(tmu : TGrChipID; fnc: TGrTextureCombineFnc); stdcall;  //obsoleted, use guTexCombineFunction
  grCheckForRoom: procedure(n: TFxI32); stdcall;  //most likely meant for internal usage only
  guDrawPolygonVertexListWithClip: procedure(nverts: integer; const vlist: PGrVertex); stdcall;
  guEndianSwapBytes: function(value: TFxU32): TFxU32; stdcall;
  guEndianSwapWords: function(value: TFxU32): TFxU32; stdcall;
  guEncodeRLE16: function(dst, src: pointer; width, height: TFxU32): integer; stdcall;
  guTexCreateColorMipMap: function(): PFxU16; stdcall;
  ConvertAndDownloadRle: procedure(
      tmu : TGrChipID;
      startAddress :TFxU32;
      thisLod      :TGrLOD;
      largeLod     :TGrLOD;
      aspectRatio  :TGrAspectRatio;
      format       :TGrTextureFormat;
      evenOdd      :TFxU32;
      bm_data      :PFxU8;
      bm_h         :LongWord;
      u0           :TFxU32;
      v0           :TFxU32;
      width        :TFxU32;
      height       :TFxU32;
      dest_width   :TFxU32;
      dest_height  :TFxU32;
      tlut         :PFxU16
      ); stdcall;

{ The following APIs are obsolete in Glide 2.2:
  grLfbBegin, grLfbEnd, grLfbGetReadPtr, grLfbGetWritePtr, grLfbBypassMode, grLfbWriteMode, grLfbOrigin,
  guFbReadRegion, and guFbWriteRegion.
}

const
  GlideHandle : THandle = 0;

function InitGlide : Boolean;
function InitGlideFromLibrary(PathDLL: string): Boolean;
procedure CloseGlide;

////////////////////////////////////////////////////////////////////////////////////////////////////
implementation

procedure ClearProcAddresses;
begin
  grAADrawLine := nil;
  grAADrawPoint := nil;
  grAADrawPolygon := nil;
  grAADrawPolygonVertexList := nil;
  grAADrawTriangle := nil;
  grAlphaBlendFunction := nil;
  grAlphaCombine := nil;
  grAlphaControlsITRGBLighting := nil;
  grAlphaTestFunction := nil;
  grAlphaTestReferenceValue := nil;
  grBufferClear := nil;
  grBufferNumPending := nil;
  grBufferSwap := nil;
  grCheckForRoom := nil;
  grChromakeyMode := nil;
  grChromakeyValue := nil;
  grClipWindow := nil;
  grColorCombine := nil;
  grColorMask := nil;
  grConstantColorValue4 := nil;
  grConstantColorValue := nil;
  grCullMode := nil;
  grDepthBiasLevel := nil;
  grDepthBufferFunction := nil;
  grDepthBufferMode := nil;
  grDepthMask := nil;
  grDisableAllEffects := nil;
  grDitherMode := nil;
  grDrawLine := nil;
  grDrawPlanarPolygon := nil;
  grDrawPlanarPolygonVertexList := nil;
  grDrawPoint := nil;
  grDrawPolygon := nil;
  grDrawPolygonVertexList := nil;
  grDrawTriangle := nil;
  grErrorSetCallback := nil;
  grFogColorValue := nil;
  grFogMode := nil;
  grFogTable := nil;
  grGammaCorrectionValue := nil;
  grGlideGetState := nil;
  grGlideGetVersion := nil;
  grGlideInit := nil;
  grGlideSetState := nil;
  grGlideShamelessPlug := nil;
  grGlideShutdown := nil;
  grHints := nil;
  grLfbConstantAlpha := nil;
  grLfbConstantDepth := nil;
  grLfbLock := nil;
  grLfbReadRegion := nil;
  grLfbUnlock := nil;
  grLfbWriteColorFormat := nil;
  grLfbWriteColorSwizzle := nil;
  grLfbWriteRegion := nil;
  grRenderBuffer := nil;
  grResetTriStats := nil;
  grSplash := nil;
  grSstControl := nil;
  grSstIdle := nil;
  grSstIsBusy := nil;
  grSstOrigin := nil;
  grSstPerfStats := nil;
  grSstQueryBoards := nil;
  grSstQueryHardware := nil;
  grSstResetPerfStats := nil;
  grSstScreenHeight := nil;
  grSstScreenWidth := nil;
  grSstSelect := nil;
  grSstStatus := nil;
  grSstVRetraceOn := nil;
  grSstVideoLine := nil;
  grSstWinClose := nil;
  grSstWinOpen := nil;
  grTexCalcMemRequired := nil;
  grTexClampMode := nil;
  grTexCombine := nil;
  grTexCombineFunction := nil;
  grTexDetailControl := nil;
  grTexDownloadMipMap := nil;
  grTexDownloadMipMapLevel := nil;
  grTexDownloadMipMapLevelPartial := nil;
  grTexDownloadTable := nil;
  grTexDownloadTablePartial := nil;
  grTexFilterMode := nil;
  grTexLodBiasValue := nil;
  grTexMaxAddress := nil;
  grTexMinAddress := nil;
  grTexMipMapMode := nil;
  grTexMultibase := nil;
  grTexMultibaseAddress := nil;
  grTexNCCTable := nil;
  grTexSource := nil;
  grTexTextureMemRequired := nil;
  grTriStats := nil;

  gu3dfGetInfo := nil;
  gu3dfLoad := nil;
  guAADrawTriangleWithClip := nil;
  guAlphaSource := nil;
  guColorCombineFunction := nil;
  guDrawTriangleWithClip := nil;
  guFogGenerateExp := nil;
  guFogGenerateExp2 := nil;
  guFogGenerateLinear := nil;
  guFogTableIndexToW := nil;
  guTexAllocateMemory	:= nil;
  guTexChangeAttributes	:= nil;
  guTexCombineFunction := nil;
  guTexDownloadMipMap := nil;
  guTexDownloadMipMapLevel := nil;
  guTexGetCurrentMipMap := nil;
  guTexGetMipMapInfo := nil;
  guTexMemQueryAvail := nil;
  guTexMemReset := nil;
  guTexSource := nil;

  guDrawPolygonVertexListWithClip := nil;
  guEncodeRLE16 := nil;
  guEndianSwapBytes := nil;
  guEndianSwapWords := nil;
  guTexCreateColorMipMap := nil;
  ConvertAndDownloadRle := nil;
end;


procedure LoadProcAddresses;
  function Load(const s: pchar): pointer;
  begin
    result := GetProcAddress (GlideHandle, s);
    Assert(result <> nil, 'couldn''t load function: ' + s);
  end;
begin
  Assert(GlideHandle <> 0, 'Glide not loaded!');
  grAADrawLine	:= Load('_grAADrawLine@8');
  grAADrawPoint	:= Load('_grAADrawPoint@4');
  grAADrawPolygon	:= Load('_grAADrawPolygon@12');
  grAADrawPolygonVertexList	:= Load('_grAADrawPolygonVertexList@8');
  grAADrawTriangle	:= Load('_grAADrawTriangle@24');
  grAlphaBlendFunction	:= Load('_grAlphaBlendFunction@16');
  grAlphaCombine	:= Load('_grAlphaCombine@20');
  grAlphaControlsITRGBLighting	:= Load('_grAlphaControlsITRGBLighting@4');
  grAlphaTestFunction	:= Load('_grAlphaTestFunction@4');
  grAlphaTestReferenceValue	:= Load('_grAlphaTestReferenceValue@4');
  grBufferClear	:= Load('_grBufferClear@12');
  grBufferNumPending	:= Load('_grBufferNumPending@0');
  grBufferSwap	:= Load('_grBufferSwap@4');
  grCheckForRoom	:= Load('_grCheckForRoom@4');
  grChromakeyMode	:= Load('_grChromakeyMode@4');
  grChromakeyValue	:= Load('_grChromakeyValue@4');
  grClipWindow	:= Load('_grClipWindow@16');
  grColorCombine	:= Load('_grColorCombine@20');
  grColorMask	:= Load('_grColorMask@8');
  grConstantColorValue4	:= Load('_grConstantColorValue4@16');
  grConstantColorValue	:= Load('_grConstantColorValue@4');
  grCullMode	:= Load('_grCullMode@4');
  grDepthBiasLevel	:= Load('_grDepthBiasLevel@4');
  grDepthBufferFunction	:= Load('_grDepthBufferFunction@4');
  grDepthBufferMode	:= Load('_grDepthBufferMode@4');
  grDepthMask	:= Load('_grDepthMask@4');
  grDisableAllEffects	:= Load('_grDisableAllEffects@0');
  grDitherMode	:= Load('_grDitherMode@4');
  grDrawLine	:= Load('_grDrawLine@8');
  grDrawPlanarPolygon	:= Load('_grDrawPlanarPolygon@12');
  grDrawPlanarPolygonVertexList	:= Load('_grDrawPlanarPolygonVertexList@8');
  grDrawPoint	:= Load('_grDrawPoint@4');
  grDrawPolygon	:= Load('_grDrawPolygon@12');
  grDrawPolygonVertexList	:= Load('_grDrawPolygonVertexList@8');
  grDrawTriangle	:= Load('_grDrawTriangle@12');
  grErrorSetCallback	:= Load('_grErrorSetCallback@4');
  grFogColorValue	:= Load('_grFogColorValue@4');
  grFogMode	:= Load('_grFogMode@4');
  grFogTable	:= Load('_grFogTable@4');
  grGammaCorrectionValue	:= Load('_grGammaCorrectionValue@4');
  grGlideGetState	:= Load('_grGlideGetState@4');
  grGlideGetVersion	:= Load('_grGlideGetVersion@4');
  grGlideInit	:= Load('_grGlideInit@0');
  grGlideSetState	:= Load('_grGlideSetState@4');
  grGlideShamelessPlug	:= Load('_grGlideShamelessPlug@4');
  grGlideShutdown	:= Load('_grGlideShutdown@0');
  grHints	:= Load('_grHints@8');
  grLfbConstantAlpha	:= Load('_grLfbConstantAlpha@4');
  grLfbConstantDepth	:= Load('_grLfbConstantDepth@4');
  grLfbLock	:= Load('_grLfbLock@24');
  grLfbReadRegion	:= Load('_grLfbReadRegion@28');
  grLfbUnlock	:= Load('_grLfbUnlock@8');
  grLfbWriteColorFormat	:= Load('_grLfbWriteColorFormat@4');
  grLfbWriteColorSwizzle	:= Load('_grLfbWriteColorSwizzle@8');
  grLfbWriteRegion	:= Load('_grLfbWriteRegion@32');
  grRenderBuffer	:= Load('_grRenderBuffer@4');
  grResetTriStats	:= Load('_grResetTriStats@0');
  grSplash	:= Load('_grSplash@20');
  grSstControl	:= Load('_grSstControl@4');
  grSstIdle	:= Load('_grSstIdle@0');
  grSstIsBusy	:= Load('_grSstIsBusy@0');
  grSstOrigin	:= Load('_grSstOrigin@4');
  grSstPerfStats	:= Load('_grSstPerfStats@4');
  grSstQueryBoards	:= Load('_grSstQueryBoards@4');
  grSstQueryHardware	:= Load('_grSstQueryHardware@4');
  grSstResetPerfStats	:= Load('_grSstResetPerfStats@0');
  grSstScreenHeight	:= Load('_grSstScreenHeight@0');
  grSstScreenWidth	:= Load('_grSstScreenWidth@0');
  grSstSelect	:= Load('_grSstSelect@4');
  grSstStatus	:= Load('_grSstStatus@0');
  grSstVRetraceOn	:= Load('_grSstVRetraceOn@0');
  grSstVideoLine	:= Load('_grSstVideoLine@0');
  grSstWinClose	:= Load('_grSstWinClose@0');
  grSstWinOpen	:= Load('_grSstWinOpen@28');
  grTexCalcMemRequired	:= Load('_grTexCalcMemRequired@16');
  grTexClampMode	:= Load('_grTexClampMode@12');
  grTexCombine	:= Load('_grTexCombine@28');
  grTexCombineFunction	:= Load('_grTexCombineFunction@8');
  grTexDetailControl	:= Load('_grTexDetailControl@16');
  grTexDownloadMipMap	:= Load('_grTexDownloadMipMap@16');
  grTexDownloadMipMapLevel	:= Load('_grTexDownloadMipMapLevel@32');
  grTexDownloadMipMapLevelPartial	:= Load('_grTexDownloadMipMapLevelPartial@40');
  grTexDownloadTable	:= Load('_grTexDownloadTable@12');
  grTexDownloadTablePartial	:= Load('_grTexDownloadTablePartial@20');
  grTexFilterMode	:= Load('_grTexFilterMode@12');
  grTexLodBiasValue	:= Load('_grTexLodBiasValue@8');
  grTexMaxAddress	:= Load('_grTexMaxAddress@4');
  grTexMinAddress	:= Load('_grTexMinAddress@4');
  grTexMipMapMode	:= Load('_grTexMipMapMode@12');
  grTexMultibase	:= Load('_grTexMultibase@8');
  grTexMultibaseAddress	:= Load('_grTexMultibaseAddress@20');
  grTexNCCTable	:= Load('_grTexNCCTable@8');
  grTexSource	:= Load('_grTexSource@16');
  grTexTextureMemRequired	:= Load('_grTexTextureMemRequired@8');
  grTriStats	:= Load('_grTriStats@8');

  gu3dfGetInfo := Load('_gu3dfGetInfo@8');
  gu3dfLoad	:= Load('_gu3dfLoad@8');
  guAADrawTriangleWithClip := Load('_guAADrawTriangleWithClip@12');
  guAlphaSource := Load('_guAlphaSource@4');
  guColorCombineFunction := Load('_guColorCombineFunction@4');
  guDrawTriangleWithClip	:= Load('_guDrawTriangleWithClip@12');
  guFogGenerateExp := Load('_guFogGenerateExp@8');
  guFogGenerateExp2 := Load('_guFogGenerateExp2@8');
  guFogGenerateLinear := Load('_guFogGenerateLinear@12');
  guFogTableIndexToW := Load('_guFogTableIndexToW@4');
  guTexAllocateMemory	:= Load('_guTexAllocateMemory@60');
  guTexChangeAttributes	:= Load('_guTexChangeAttributes@48');
  guTexCombineFunction	:= Load('_guTexCombineFunction@8');
  guTexDownloadMipMap	:= Load('_guTexDownloadMipMap@12');
  guTexDownloadMipMapLevel	:= Load('_guTexDownloadMipMapLevel@12');
  guTexGetCurrentMipMap	:= Load('_guTexGetCurrentMipMap@4');
  guTexGetMipMapInfo	:= Load('_guTexGetMipMapInfo@4');
  guTexMemQueryAvail	:= Load('_guTexMemQueryAvail@4');
  guTexMemReset	:= Load('_guTexMemReset@0');
  guTexSource	:= Load('_guTexSource@4');

  //load these?
  guDrawPolygonVertexListWithClip := Load('_guDrawPolygonVertexListWithClip@8');
  guEncodeRLE16	:= Load('_guEncodeRLE16@16');
  guEndianSwapBytes	:= Load('_guEndianSwapBytes@4');
  guEndianSwapWords := Load('_guEndianSwapWords@4');
  guTexCreateColorMipMap := Load('_guTexCreateColorMipMap@0');
  ConvertAndDownloadRle := Load('_ConvertAndDownloadRle@64');
end;

 
function InitGlideFromLibrary(PathDLL: string): Boolean;
begin
  Result := False;
  if PathDLL = '' then PathDLL := GlideLibName;
  if PathDLL[Length(PathDLL)-1] = '\' then PathDLL := PathDLL + GlideLibName;
  if GlideHandle <> 0 then
      CloseGlide;
  GlideHandle := LoadLibrary(PChar(PathDLL));
  if (GlideHandle = 0) then
      exit;
  LoadProcAddresses;
  Result := true;
end;

function InitGlide: Boolean;
begin
  Result := InitGlideFromLibrary('');
end;

procedure CloseGlide;
begin
  ClearProcAddresses;
  if GlideHandle <> 0 then
  begin
    FreeLibrary(GlideHandle);
    GlideHandle := 0;
  end;
end;


initialization
begin
  ClearProcAddresses;
end

finalization
begin
  CloseGlide;
end

end.
