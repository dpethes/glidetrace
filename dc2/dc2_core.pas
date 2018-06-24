unit dc2_core;
{$mode objfpc}
{$define bs_inline}

interface

uses
  sysutils, math;
  
const
  MAX_BLOCK_SIZE = 32 * 1024;

type
  TBlockTypeEnum = (BTRaw := 0, BTFixed, BTDynamic, BTError);

  //encoding statistics
  TStats = record
      elements_encoded: int64;
      blocks: array[TBlockTypeEnum] of longword;
  end;
  
type

TBitstreamBufferState = record
    current_bits: longword;
    mask: longword;
end;

{ TBitstreamWriter }

TBitstreamWriter = class
  private
    buffer: plongword;
    cur: plongword;
    mask: longword;
    closed: boolean;

  public
    constructor Create(const memory_buffer: pbyte);
    destructor Destroy; override;

    procedure Close;
    function IsByteAligned: boolean;
    procedure ByteAlign;
    function GetBitSize: longword;
    function GetByteSize: longword;
    function GetUnbufferedByteSize: longword;
    function GetDataStart: pbyte;

    procedure Write(const bit: integer);
    procedure Write(const bits, length: longword);  //write multiple bits, lsb first

    function GetState: TBitstreamBufferState;
    procedure SetState(const state: TBitstreamBufferState);

    procedure ResetBufferPosition;
end;


{ TBitstreamReader }

TBitstreamReader = class
  private
    bits: uint32;
    used: longword;
    cur: pbyte;
    buffer: pbyte;

  public
    constructor Create(const memory_buffer: pbyte);
    function  GetPosition(): longword;
    function  GetBitCount(): longword;
    function  GetUncachedPosition(): longword;
    function  IsByteAligned(): boolean;
    procedure Start();
    function  Read(): longword;
    function  Read(count: longword): longword;

    //U functions need explicit Refill calls
    procedure Refill;
    function  ReadU: longword;                   {$ifdef bs_inline}inline;{$endif}
    function  ReadU(count: longword): longword;  {$ifdef bs_inline}inline;{$endif}
    function  ShowU(const count: longword): longword; {$ifdef bs_inline}inline;{$endif}
    function  Show9U: longword;                  {$ifdef bs_inline}inline;{$endif}
    procedure SkipU(const count: longword);      {$ifdef bs_inline}inline;{$endif}

    function  ReadInverse(bit_count: longword): longword;

    function  GetState: TBitstreamBufferState;
    procedure SetState(const state: TBitstreamBufferState);
    procedure ResetBufferPosition;

    function GetInternalState: TBitstreamBufferState;
    procedure SetInternalState(const state: TBitstreamBufferState);
end;

function SwapBits (const bits, bit_count: longword): longword;

const
  END_OF_STREAM = 285;
  TOP_NODE      = END_OF_STREAM * 2 + 1;

type
  //huff tree definitions
  TTreeNode = record
      child_0: word;
      child_1: word;
  end;
  PTreeNode = ^TTreeNode;

  TVlcCode = record
      bits: word;
      code_len: byte;
  end;
  PVlcCode = ^TVlcCode;

  THuffTree = record
      counts: plongword;
      nodes:  PTreeNode;
      codes:  PVlcCode;
      root_node: longword;
  end;

  //fixed huffcodes are actually constructed using codes <0..287>, but last 2 are never used
  TDecodeTable = record
      codes_of_legth: array[0..15] of word;     //number of codes for given length
      code_value: array[0..END_OF_STREAM + 2] of word; //map code to literal/length value
  end;
  PDecodeTable = ^TDecodeTable;

procedure huff_FillCanonDecodingTable(var tab: TDecodeTable; const code_lengths: pbyte; const count: integer);

procedure huff_init(out h: THuffTree; const tree_memory: pointer);
function huff_alloc: pointer;
procedure huff_free(tree_memory: pointer);

const
  END_OF_BLOCK = 1000;  //must not collide with any valid Deflate values
  END_OF_BLOCK_CODE = 256;
  MAX_VLC_LENGTH = 6;  //maximum code+length vlc in bytes: 15+5 bits match with 15+13 bits offset

type

  { TVlcWriter }
  TVlcWriter = object
  private
    bs: TBitstreamWriter;
    len_tree, dist_tree: PVlcCode;
  public
    procedure SetTrees(const bitstream: TBitstreamWriter; const length_tree, distance_tree: PVlcCode);
    procedure WriteMatch (const len, dist: longword);
    procedure WriteLiteral (const c: byte);
    procedure WriteBlockEnd ();
  end;

  TSymbolBits = record
      symbol: word;
      nbits: byte;
  end;

const
  TAB0_BITS = 9;  //LUT bits, must be less or equal to maximum bit length of huff codes allowed by Deflate

type
  TDecodeLookupTables = record
      codes_t0: array[0..511] of TSymbolBits;  //9 bits = 512 values
      canon_table: TDecodeTable;
  end;

  { TVlcReader }

  TVlcReader = class
  private
    bs: TBitstreamReader;
    literal_dectable, distance_dectable: TDecodeLookupTables;
  public
    procedure SetTables(const bitreader: TBitstreamReader; const literal_table, distance_table: TDecodeLookupTables);
    function ReadCode: integer; inline;
    procedure ReadDist(code: integer; out length, distance: word);
  end;


function Length2code (const len:  longword): longword;
function Distance2code(const dist: longword): longword;

function vlc_ReadCode(const bs: TBitstreamReader; const dectable: TDecodeLookupTables): integer;
function InitDecodeLut(const code_lengths: pbyte; const count: integer): TDecodeLookupTables;


const
  MIN_MATCH_LENGTH = 3;

type
  TLiteralMatch = record
      match_length: word; //match length
      offset: word;       //match offset
      literal: byte;      //byte from input stream
  end;
  PLiteralMatch = ^TLiteralMatch;

  { TBlockWriter }
  TBlockWriter = class
  private
    bitWriter: TBitstreamWriter;      //bitstream writer
    literal_match_stats: pinteger;
    distance_stats: pinteger;
    literal_codes: PVlcCode;
    distance_codes: PVlcCode;
    huff_memory: pointer;

    _block_type: TBlockTypeEnum;
    _last: boolean;                   //last block in stream
    bs_cache: TBitstreamBufferState;  //state of the buffer at beginning of the block

    procedure BeginBlock;
    procedure BuildFixedHuffCodes;
    procedure WriteBlockEncoded(const search_results: PLiteralMatch; const size: integer);
    procedure WriteBlockRaw(const rawdata: pbyte; const rawsize: integer);

  public
    constructor Create(const output_buffer: pbyte);
    destructor Destroy; override;

    procedure InitNewBlock(const block_type: TBlockTypeEnum);
    procedure SetLast;
    procedure UpdateStatsMatch(const len, dist: longword);
    procedure UpdateStatsLiteral(const literal: byte);

    procedure WriteBlock(const rawdata: pbyte; const rawsize: integer;
      const search_results: PLiteralMatch; const size: integer; const keep_buffer: boolean = false);
    procedure Done;

    function GetStreamSize: integer;
  end;


  TBlockContext = record
      btype: TBlockTypeEnum;
      size:  integer;
      in_progress: boolean;
      is_last:  boolean;
  end;

  { TBlockReader }
  TBlockReader = class
  private
    _block_type: TBlockTypeEnum;
    _vlc: TVlcReader;
    procedure ReadHeaderCodes(const bs: TBitstreamReader);
    procedure InitFixedCodes(const bs: TBitstreamReader);
  public
    constructor Create;
    destructor Destroy; override;
    function ReadBlockHeader(const bs: TBitstreamReader): TBlockContext;
    function GetVlcReader: TVlcReader; inline;
  end;


const
  MAX_COMPRESSION_LEVEL = 1;
  DICT_SIZE = MAX_BLOCK_SIZE;
  MAX_DEFLATE_MATCH_LENGTH = 258;

type
  TSearchResult = record
    distance,
    length: word;
  end;

  { TSlidingBuffer }
  TSlidingBuffer = object
  private
      _buffer: pbyte;
      _previous_bytes_count: integer;
  public
      constructor Init();
      destructor Done;
      function GetWindow: pbyte; inline;
      procedure InsertData(const data: pbyte; const size: integer);
  end;

  { TMatchSearcher }
  TMatchSearcher = class
  private
      _max_search_depth: integer;  //limit how many positions we want to check
      _max_search_match_length: integer;  //limit how long match needs to be to satisfy search conditions
      _links: pinteger;                   //linked list of hash occurences
      _last_seen_idx: pinteger;           //last known position of a hash in the stream
      _bytes_processed: integer;
      _current_chunk_size: integer;
      _sbuffer: TSlidingBuffer;    //sliding buffer for search window data

      function Search(const window_end_ptr, str: pbyte; const current_idx, max_match_length: integer
        ): TSearchResult;

  public
      constructor Create;
      destructor Destroy; override;
      procedure SetCompressionLevel(const level: integer);

      { New chunk of data that to be processed. }
      procedure NewData (const data: pbyte; const size: integer);

      {
        Find previous occurence of bytes in str.
          str         - searched data pointer
          data_index  - searched data index relative to current chunk
      }
      function FindMatch(const str: pbyte; const data_index: integer): TSearchResult;
  end;


(*******************************************************************************
*******************************************************************************)
implementation

{ SwapBits
  Swap bit ordering in source pattern. Swaps up to 16 bits.
}
function SwapBits (const bits, bit_count: longword): longword;
var
  x: longword;
begin
  x := bits;
  x := ((x and $aaaa) >> 1) or ((x and $5555) << 1);
  x := ((x and $cccc) >> 2) or ((x and $3333) << 2);
  x := ((x and $f0f0) >> 4) or ((x and $0f0f) << 4);
  x := ((x and $ff00) >> 8) or ((x and $00ff) << 8);
  result := x >> (16 - bit_count);
end;

{ TBitstreamWriter }

constructor TBitstreamWriter.Create(const memory_buffer: pbyte);
begin
  buffer := plongword (memory_buffer);
  cur  := buffer;
  cur^ := 0;
  mask := 0;
end;

destructor TBitstreamWriter.Destroy;
begin
  if not closed then
      Close;

  inherited Destroy;
end;

function TBitstreamWriter.GetBitSize: longword;
begin
  result := 32 * (cur - buffer) + mask;
end;

function TBitstreamWriter.GetByteSize: longword;
begin
  result := (cur - buffer) * 4;
  result += (mask + 7) div 8;  //+ buffer
end;

function TBitstreamWriter.GetUnbufferedByteSize: longword;
begin
  result := (cur - buffer) * 4;
end;

function TBitstreamWriter.GetDataStart: pbyte;
begin
  result := pbyte(buffer);
end;

procedure TBitstreamWriter.Close;
begin
end;

function TBitstreamWriter.IsByteAligned: boolean;
begin
  result := mask mod 8 = 0;
end;

procedure TBitstreamWriter.ByteAlign;
begin
  while not IsByteAligned do
      Write(0);
end;

procedure TBitstreamWriter.Write(const bit: integer);
begin
  cur^ := cur^ or longword((bit and 1) shl mask);
  mask += 1;

  if mask = 32 then begin
      cur += 1;
      cur^ := 0;
      mask := 0;
  end;
end;

procedure TBitstreamWriter.Write(const bits, length: longword);
var
  bits_: longword;
begin
  Assert(length <= 32, 'bit_count over 32');

  //clear unused bits
  bits_ := bits and ($ffffffff shr (32 - length));

  cur^ := cur^ or (bits_ shl mask);
  mask += length;
  if mask >= 32 then begin
      mask -= 32;  //number of bits that didn't fit into buffer
      cur += 1;
      cur^ := 0;

      if mask > 0 then
          cur^ := bits_ shr (length - mask);
  end;
end;

function TBitstreamWriter.GetState: TBitstreamBufferState;
begin
  Result.mask := mask;
  Result.current_bits := cur^;
end;

procedure TBitstreamWriter.SetState(const state: TBitstreamBufferState);
begin
  mask := state.mask;
  cur^ := state.current_bits;
end;

procedure TBitstreamWriter.ResetBufferPosition;
var
  cache: TBitstreamBufferState;
begin
  cache := GetState;
  cur := buffer;
  SetState(cache);
end;


{ TBitstreamReader }

constructor TBitstreamReader.Create(const memory_buffer: pbyte);
begin
  buffer := memory_buffer;
  cur  := buffer;
  used := 0;
  bits := plongword(cur)^;
end;

function TBitstreamReader.GetPosition: longword;
begin
  result := cur - buffer;  //used bytes
  result += (used + 7) shr 3;  //+ buffer
end;

function TBitstreamReader.GetBitCount: longword;
begin
  result := 8 * (cur - buffer) + used;
end;

function TBitstreamReader.GetUncachedPosition: longword;
begin
  result := cur - buffer;
end;

function TBitstreamReader.IsByteAligned: boolean;
begin
  result := true;
  if used mod 8 > 0 then result := false;
end;

procedure TBitstreamReader.Start;
begin
  bits := plongword(cur)^;
end;

function TBitstreamReader.Read: longword;
begin
  result := (bits shr used) and 1;
  used += 1;
  if used = 32 then begin
      cur += 4;
      bits := plongword(cur)^;
      used := 0;
  end;
end;

function TBitstreamReader.Read(count: longword): longword;
var
  bits_left: integer;
begin
  result := bits shr used;
  if count < (32 - used) then begin
      result := result and ($ffffffff shr (32 - count));
      used += count;
  end else begin
      bits_left := count - (32 - used);
      cur += 4;
      bits := plongword(cur)^;
      if bits_left > 0 then
          result := result or (bits and ($ffffffff shr (32 - bits_left))) shl (32 - used);
      used := bits_left;
  end;
end;

procedure TBitstreamReader.Refill;
var
  fill_bits: integer;
begin
  if used < 8 then
      exit;
  fill_bits := used and (not %111);
  used -= fill_bits;
  bits := (bits >> fill_bits) or (plongword(cur + 4)^ << (32 - fill_bits));
  cur += fill_bits >> 3;
end;

function TBitstreamReader.ReadU: longword;
begin
  result := (bits shr used) and 1;
  used += 1;
end;

function TBitstreamReader.ReadU(count: longword): longword;
begin
  result := bits shr used;
  result := result and ($ffffffff shr (32 - count));
  used += count;
end;

function TBitstreamReader.ShowU(const count: longword): longword;
begin
  result := bits shr used;
  result := result and ($ffffffff shr (32 - count));
end;

function TBitstreamReader.Show9U: longword;
begin
  result := bits shr used;
  result := result and ($ffffffff shr 23)
end;

procedure TBitstreamReader.SkipU(const count: longword);
begin
  used += count;
end;

function TBitstreamReader.ReadInverse(bit_count: longword): longword;
var
  i: integer;
begin
  result := 0;
  for i := bit_count - 1 downto 0 do
      result := result or Read() shl i;
end;

function TBitstreamReader.GetState: TBitstreamBufferState;
begin
  result.current_bits := bits;
end;

procedure TBitstreamReader.SetState(const state: TBitstreamBufferState);
begin
  bits := state.current_bits;
end;

procedure TBitstreamReader.ResetBufferPosition;
begin
  cur := buffer;
end;

function TBitstreamReader.GetInternalState: TBitstreamBufferState;
begin
  result.current_bits := cur - buffer;
  result.mask := used;
end;

procedure TBitstreamReader.SetInternalState(const state: TBitstreamBufferState);
begin
  cur := buffer + state.current_bits;
  used := state.mask;
end;


{ huff_FillCanonDecodingTable

  code_lengths - array of lengths, indexed by code
  count - number of codes to fill
}
procedure huff_FillCanonDecodingTable(var tab: TDecodeTable; const code_lengths: pbyte; const count: integer);
var
  len: integer; //current length; all deflate code lengths are between 1 and 15
  same_length_count: integer;
  i, j: integer;
begin
  j := 0;
  tab.codes_of_legth[0] := 0;
  for len := 1 to 15 do begin
      same_length_count := 0;

      for i := 0 to count - 1 do begin
          if code_lengths[i] = len then begin
              tab.code_value[j] := i;
              j += 1;
              same_length_count += 1;
              if j = count then
                  break;
          end;
      end;

      tab.codes_of_legth[len] := same_length_count;
  end;
end;


{
  memory allocation
  As there's only one hufftree used at time, we can get away with reallocating the trees onto the
  same buffer
}
const
  TH_counts = sizeof(longword ) * (END_OF_STREAM + 1);
  TH_nodes  = sizeof(TTreeNode) * (END_OF_STREAM + 1) * 2;
  TH_codes  = sizeof(TVlcCode ) * (END_OF_STREAM + 1);
  TH_size = TH_counts + TH_nodes + TH_codes;

procedure huff_init(out h: THuffTree; const tree_memory: pointer);
var
  p: PByte;
begin
  p := tree_memory;
  Assert(p <> nil);
  FillByte(p^, TH_size, 0);
  h.counts := PLongWord( p );
  h.nodes  := PTreeNode( p + TH_counts );
  h.codes  := PVlcCode ( p + TH_counts + TH_nodes );
  h.root_node := 0;
end;

function huff_alloc: pointer;
begin
  result := GetMem(TH_size);
end;

procedure huff_free(tree_memory: pointer);
begin
  Freemem(tree_memory);
end;


{ Length2code
  Map match length value to length code for huff encoding.
}
function Length2code (const len: longword): longword; inline;
const
  table: array[byte] of byte = (
  1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 13, 13, 14, 14,
  14, 14, 15, 15, 15, 15, 16, 16, 16, 16, 17, 17, 17, 17, 17, 17, 17, 17, 18, 18,
  18, 18, 18, 18, 18, 18, 19, 19, 19, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20, 20,
  20, 20, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 22, 22,
  22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 23, 23, 23, 23, 23, 23,
  23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
  24, 24, 24, 24, 24, 24, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
  25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 26, 26,
  26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
  26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
  27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
  27, 27, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
  28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 29
  );
begin
  Assert(len >= 3);
  result := 256 + table[len-3];  //0..255 = literals, 256 = block end
end;


{ Code2length
  Map decoded length code to length value.
}
function Code2length(const code: longword): longword; inline;
const
  table: array[257..285] of byte = (  //final value minus 3
  0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40, 48, 56, 64,
  80, 96, 112, 128, 160, 192, 224, 255
  );
begin
  result := table[code] + 3;
end;


{ Distance2code
  Map distance value to distance code for huff encoding.
}
function Distance2code(const dist: longword): longword; inline;
const
  table_512: array [0..511] of byte = (
  0, 1, 2, 3, 4, 4, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9,
  9, 9, 9, 9, 9, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
  11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 12, 12, 12, 12,
  12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
  12, 12, 12, 12, 12, 12, 12, 12, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
  13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
  14, 14, 14, 14, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
  15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
  15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
  15, 15, 15, 15, 15, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
  16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
  16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
  16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
  16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
  16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
  16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 17, 17, 17,
  17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
  17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
  17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
  17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
  17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
  17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
  17, 17, 17, 17
  );
  table_128: array[2..127] of byte = (
  18, 19, 20, 20, 21, 21, 22, 22, 22, 22, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24,
  24, 24, 25, 25, 25, 25, 25, 25, 25, 25, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
  26, 26, 26, 26, 26, 26, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
  27, 27, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
  28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 29, 29, 29, 29, 29, 29,
  29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29,
  29, 29, 29, 29, 29, 29
  );
begin
  if dist <= 512 then
      result := table_512[dist - 1]
  else begin
      result := table_128[(dist - 1) shr 8];
  end;
end;


{ Code2distance
  Map decoded distance code to distance value.
}
function Code2distance(const code: longword): longword; inline;
const
  table: array[0..29] of word = (
  1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769,
  1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577
  );
begin
  result := table[ code ];
end;

{ TVlcWriter }

procedure TVlcWriter.SetTrees(const bitstream: TBitstreamWriter;
  const length_tree, distance_tree: PVlcCode);
begin
  bs := bitstream;
  len_tree := length_tree;
  dist_tree := distance_tree;
end;

procedure TVlcWriter.WriteMatch(const len, dist: longword);
var
  code, bits: longword;
begin
  //length
  code := Length2code(len);
  bs.Write(len_tree[code].bits, len_tree[code].code_len);
  if (code >= 265) and (code < 285) then begin  //extra bits
      bits := 5 - (284 - code) div 4;
      bs.Write(len - 3, bits);
  end;

  //offset / distance
  code := Distance2code(dist);
  bs.Write(dist_tree[code].bits, dist_tree[code].code_len);
  if code >= 4 then begin
      bits := code div 2 - 1;
      bs.Write(dist - 1, bits);
  end;
end;

procedure TVlcWriter.WriteLiteral(const c: byte);
begin
  bs.Write(len_tree[c].bits, len_tree[c].code_len);
end;

procedure TVlcWriter.WriteBlockEnd;
begin
  bs.Write(len_tree[END_OF_BLOCK_CODE].bits, len_tree[END_OF_BLOCK_CODE].code_len);
end;

{ vlc_ReadCode
  Read one canonical huffman code using the given decoding table. Maximum symbol length cannot
  exceed 15 bits (maximum allowed by Deflate), otherwise reading fails and bad things happen.
}
function vlc_ReadCodeSlow(const bs: TBitstreamReader; const table: TDecodeTable): integer;
var
  i, codes,
  diff, value: longword;
  value_low: longword;      //lowest value for code of given length
  codes_skipped: longword;  //how many codes we already skipped
  number_of_codes: pword;   //# codes of given length
begin
  i := 0;
  value := 0;
  codes_skipped := 0;
  value_low := 0;
  codes := 0;
  number_of_codes := @table.codes_of_legth[0];
  repeat
      codes_skipped += codes;
      value_low += codes;
      value_low := value_low shl 1;

      i += 1;
      Assert(i < 16, 'could not read vlc code');  //checking costs ~2%
      codes := number_of_codes[i];

      value := (value shl 1) or bs.readu();
      diff := value - value_low;
  until codes > diff;

  result := table.code_value[ codes_skipped + diff ];
end;


{ vlc_ReadCode
  Read one variable-length code using the given lookup table. If the code couldn't be read, try
  to read with the canon huff decoding table.
}
function vlc_ReadCode(const bs: TBitstreamReader; const dectable: TDecodeLookupTables): integer;
var
  bits: PtrInt;
begin
  bits := bs.Show9u();  //same as bs.Show(TAB0_BITS) but inlined and slightly faster
  result := dectable.codes_t0[bits].symbol;
  bits := dectable.codes_t0[bits].nbits;
  bs.Skipu(bits);
  if (bits = 0) then begin
      result := vlc_ReadCodeSlow(bs, dectable.canon_table);
      bs.Refill;
  end;
end;


{ InitDecodeLut
  Assign canonical huff code bits to each code by its length and build a look-up table for fast
  decoding. Uses separate code bits runs for each code length. Makes 2 passes over input data,
  one pass could be removed if code length stats were provided beforehand, but it doesn't gain much.
}
function InitDecodeLut(const code_lengths: pbyte; const count: integer): TDecodeLookupTables;
var
  i, len, code_bits: integer;
  value, k, b: integer;
  sb: TSymbolBits;
  num_lengths: array[0..15] of integer;  //# of codes of given length
  length_bits: array[0..15] of integer;  //canonical bits for codes of given length
begin
  FillByte(num_lengths, sizeof(num_lengths), 0);
  FillByte(length_bits, sizeof(length_bits), 0);
  for i := 0 to count - 1 do begin
      num_lengths[code_lengths[i]] += 1;
  end;
  b := 0;
  for i := 1 to 15 do begin
      length_bits[i] := b;
      b += num_lengths[i];
      b := b << 1;
  end;

  FillByte(result.codes_t0, sizeof(result.codes_t0), 0);
  for i := 0 to count - 1 do begin
      len := code_lengths[i];
      if not (len in [1..TAB0_BITS]) then
          continue;

      code_bits := length_bits[len];
      length_bits[len] += 1;
      sb.symbol := i;
      sb.nbits := len;

      //insert each code length + junk code_bits combination
      code_bits := SwapBits(code_bits, len);
      for k := 0 to 1 << (TAB0_BITS - len) - 1 do begin
          value := (k << len) or code_bits;
          result.codes_t0[value] := sb;
      end;
  end;
end;

{ TVlcReader }

procedure TVlcReader.SetTables(const bitreader: TBitstreamReader;
  const literal_table, distance_table: TDecodeLookupTables);
begin
  bs := bitreader;
  literal_dectable := literal_table;
  distance_dectable := distance_table;
end;

{ ReadCode + ReadDist
  There are at most 7 bits in buffer after refill, which gives 32-7=25 bits for unchecked reads.
  Here we do 9 bits lookup + 5 bits extra + 9 bits lookup = 23 bits at most;
  codes that cannot be decoded from lookup table cause buffer refills in vlc_ReadCode.
}
function TVlcReader.ReadCode: integer;
begin
  bs.Refill;
  result := vlc_ReadCode(bs, literal_dectable);
end;

{ ReadDist
  Code must be a valid length code read by ReadCode
}
procedure TVlcReader.ReadDist(code: integer; out length, distance: word);
const
  LENGTH_EXTRA_BITS: array[257..285] of byte = (
  0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0
  );
var
  extra_bits: longword;
begin
  length := Code2length(code);
  extra_bits := LENGTH_EXTRA_BITS[code];
  if extra_bits > 0 then begin
      length += bs.Readu(extra_bits);
  end;

  code := vlc_ReadCode(bs, distance_dectable);
  distance := Code2distance(code);
  if code >= 4 then begin
      distance += bs.Read(code >> 1 - 1);  //bitstream refill check needed, can read up to 13 bits
  end;
end;


const
  //code ordering for header code length alphabet
  //see RFC1951 section 3.2.7. Compression with dynamic Huffman codes (BTYPE=10)
  HeaderCodeLengthOrder: array[0..18] of byte = (
      16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15
  );

  LITERAL_MATCH_ELEMENTS = END_OF_STREAM + 1;
  DISTANCE_ELEMENTS = 30;
  MAX_CODE_LENGTHS = 286 + 32; //# of Literal/Length codes + # of Distance codes


{ TBlockWriter }

{
  BeginBlock

  Write block header.
  header bytes:
    BFINAL - 1 bit
    BTYPE  - 2 bits
}
procedure TBlockWriter.BeginBlock;
begin
  bitWriter.Write(longword( _last ) and 1);
  bitWriter.Write(longword( _block_type ), 2);
end;

{ BuildFixedHuffCodes
  Create vlc trees for blocks compressed using fixed Huffman codes
}
procedure TBlockWriter.BuildFixedHuffCodes;
var
  i, bits: integer;

  function vlc(const b, len: integer): TVlcCode;
  begin
    result.bits := SwapBits(b, len);
    result.code_len := len;
    bits += 1;
  end;

begin
  bits := 0;
  for i := 256 to 279 do literal_codes[i] := vlc(bits, 7);
  bits := bits << 1;
  for i :=   0 to 143 do literal_codes[i] := vlc(bits, 8);
  for i := 280 to 287 do literal_codes[i] := vlc(bits, 8);
  bits := bits << 1;
  for i := 144 to 255 do literal_codes[i] := vlc(bits, 9);
  for i := 0 to 29 do distance_codes[i] := vlc(i, 5);
end;



{ WriteBlockEncoded
  Write a complete block into bitstream: literals and match length / distance pairs, END_OF_BLOCK symbol.
  Handles distinction between blocks compressed using fixed or dynamic huff codes
}
procedure TBlockWriter.WriteBlockEncoded(const search_results: PLiteralMatch; const size: integer);
var
  i: integer;
  lm: TLiteralMatch;
  vlc: TVlcWriter;
begin
  BuildFixedHuffCodes();  //todo once?
  vlc.SetTrees(bitWriter, literal_codes, distance_codes);

  for i := 0 to size - 1 do begin
      lm := search_results[i];
      if lm.match_length > 0 then
          vlc.WriteMatch(lm.match_length, lm.offset)
      else
          vlc.WriteLiteral(lm.literal);
  end;

  vlc.WriteBlockEnd();
end;

{
  WriteBlockRaw

  Write a raw block into bitstream: copy input values.
  Raw block header:
    n bits  - byte alignment
    16 bits - data length
    16 bits - inverted data length
}
procedure TBlockWriter.WriteBlockRaw(const rawdata: pbyte; const rawsize: integer);
var
  i: integer;
begin
  bitWriter.ByteAlign;
  bitWriter.Write(rawsize, 16);
  bitWriter.Write(rawsize xor $ffff, 16);

  for i := 0 to rawsize - 1 do
      bitWriter.Write(rawdata[i], 8);  //todo: memcpy
end;

constructor TBlockWriter.Create(const output_buffer: pbyte);
begin
  bitWriter := TBitstreamWriter.Create(output_buffer);
  bs_cache := bitWriter.GetState;

  literal_match_stats := GetMem(LITERAL_MATCH_ELEMENTS * sizeof(integer));
  distance_stats := Getmem(DISTANCE_ELEMENTS * sizeof(integer));

  literal_codes := GetMem(LITERAL_MATCH_ELEMENTS * sizeof(TVlcCode));
  distance_codes := GetMem(DISTANCE_ELEMENTS * sizeof(TVlcCode));

  huff_memory := huff_alloc();
end;

destructor TBlockWriter.Destroy;
begin
  inherited Destroy;
  bitWriter.Free;
  Freemem(literal_match_stats);
  Freemem(distance_stats);
  Freemem(literal_codes);
  Freemem(distance_codes);
  huff_free(huff_memory);
end;

procedure TBlockWriter.InitNewBlock(const block_type: TBlockTypeEnum);
begin
  FillDWord(literal_match_stats^, LITERAL_MATCH_ELEMENTS, 0);
  FillDWord(distance_stats^, DISTANCE_ELEMENTS, 0);

  bitWriter.SetState(bs_cache);
  _block_type := block_type;
  _last := false;
end;

procedure TBlockWriter.SetLast;
begin
  _last := true;
end;

procedure TBlockWriter.UpdateStatsMatch(const len, dist: longword);
begin
  literal_match_stats[ Length2code(len) ] += 1;
  distance_stats[ Distance2code(dist) ] += 1;
end;

procedure TBlockWriter.UpdateStatsLiteral(const literal: byte);
begin
  literal_match_stats[ literal ] += 1;
end;

procedure TBlockWriter.WriteBlock(const rawdata: pbyte; const rawsize: integer;
  const search_results: PLiteralMatch; const size: integer; const keep_buffer: boolean);
begin
  if not keep_buffer then
      bitWriter.ResetBufferPosition;
  BeginBlock();
  if _block_type <> BTRaw then
      WriteBlockEncoded(search_results, size)
  else
      WriteBlockRaw(rawdata, rawsize);
end;

procedure TBlockWriter.Done;
begin
  //throw away bs cache
  bs_cache := bitWriter.GetState;
end;

{
  GetStreamSize

  Returns number of whole bytes that were written into bitstream for current block.
  The last written bit doesn't have to be at a byte aligned position,
  so we need to cache the write buffer and mask to put the bits in the next processed block.
  If the current block is the last one processed, the outstanding bits must be counted into the stream size
  (they would be lost otherwise).
}
function TBlockWriter.GetStreamSize: integer;
begin
  if not _last then begin
      result := bitWriter.GetUnbufferedByteSize;
  end else begin
      bitWriter.Close;
      result := bitWriter.GetByteSize;
  end;
end;


{ TBlockReader }

{ ReadHeaderCodes
  Read code lengths and generate tables for dynamic block decoding
}
procedure TBlockReader.ReadHeaderCodes(const bs: TBitstreamReader);
var
  literal_dectable,                       //literal/length decoding table
  distance_dectable: TDecodeLookupTables; //distance decoding table
  hlit, hdist, hclen: word;
  len, last_len: integer;  //code length, previous code length
  i, k, extra_bits: longword;
  code_lengths: array[0..MAX_CODE_LENGTHS-1] of byte;
  dt: TDecodeLookupTables;
begin
  hlit  := bs.Read(5) + 257;
  hdist := bs.Read(5) + 1;
  hclen := bs.Read(4) + 4;

  //get code_len codes
  FillByte(code_lengths, 19, 0);
  for i := 0 to hclen - 1 do begin
      k := HeaderCodeLengthOrder[i];
      code_lengths[k] := bs.Read(3);
  end;
  dt := InitDecodeLut(code_lengths, 19);

  //decode symbols
  //refill could be called less often, but this is not perf critical
  FillByte(code_lengths, MAX_CODE_LENGTHS, 0);
  i := 0;
  last_len := 16;
  while i < hlit + hdist do begin
      bs.Refill;
      len := vlc_ReadCode(bs, dt);

      if len < 16 then begin
           code_lengths[i] := len;
           i += 1;
           last_len := len;
      end
      else
          case len of
              16: begin  //rep previous length
                  Assert(last_len <> 16, 'dynamic block header error');
                  extra_bits := bs.Read(2);
                  k := i;
                  i += extra_bits + 3;
                  for k := k to i - 1 do
                      code_lengths[k] := last_len;
                  end;
              17: begin  //rep zero length
                  extra_bits := bs.Read(3);
                  i += extra_bits + 3;
                  end;
              18: begin  //rep zero length
                  extra_bits := bs.Read(7);
                  i += extra_bits + 11;
                  end
          end;
  end;

  literal_dectable  := InitDecodeLut(pbyte(@code_lengths), hlit);
  huff_FillCanonDecodingTable(literal_dectable.canon_table, pbyte(@code_lengths), hlit);

  distance_dectable := InitDecodeLut(pbyte(@code_lengths) + hlit, hdist);
  huff_FillCanonDecodingTable(distance_dectable.canon_table, pbyte(@code_lengths) + hlit, hdist);

  _vlc.SetTables(bs, literal_dectable, distance_dectable);
end;

procedure TBlockReader.InitFixedCodes(const bs: TBitstreamReader);
var
  literal_dectable,                       //literal/length decoding table
  distance_dectable: TDecodeLookupTables; //distance decoding table
  code_lengths: array[0..287] of byte;
  i: integer;
begin
  for i := 256 to 279 do code_lengths[i] := 7;
  for i :=   0 to 143 do code_lengths[i] := 8;
  for i := 280 to 287 do code_lengths[i] := 8;
  for i := 144 to 255 do code_lengths[i] := 9;
  literal_dectable := InitDecodeLut(pbyte(@code_lengths), 288);
  huff_FillCanonDecodingTable(literal_dectable.canon_table, pbyte(@code_lengths), 288);

  for i := 0 to 31 do code_lengths[i] := 5;
  distance_dectable := InitDecodeLut(pbyte(@code_lengths), 32);
  huff_FillCanonDecodingTable(distance_dectable.canon_table, pbyte(@code_lengths), 32);

  _vlc.SetTables(bs, literal_dectable, distance_dectable);
end;

constructor TBlockReader.Create;
begin
  _vlc := TVlcReader.Create;
end;

destructor TBlockReader.Destroy;
begin
  _vlc.Free;
  inherited;
end;

{ ReadBlockHeader
  Reads block header including length trees for codes
}
function TBlockReader.ReadBlockHeader(const bs: TBitstreamReader): TBlockContext;
var
  block: TBlockContext;
  t: integer;
begin
  block.is_last  := bs.Read() = 1;
  block.btype := TBlockTypeEnum( bs.Read(2) );
  _block_type := block.btype;

  case block.btype of
      BTRaw: begin
          while not bs.IsByteAligned() do
              bs.Read();
          block.size := bs.Read(16);
          t := bs.Read(16) xor $ffff;
          Assert(block.size = t, 'blk size mismatch');
      end;
      BTDynamic: begin
          ReadHeaderCodes(bs);
      end;
      BTFixed: begin
          InitFixedCodes(bs);
      end;
  end;

  Result := block;
end;


function TBlockReader.GetVlcReader(): TVlcReader;
begin
  result := _vlc;
end;



const
  SEARCH_DEPTH: array[0..MAX_COMPRESSION_LEVEL] of Integer =
    (0, 4);
  SEARCH_MATCH_DIVIDER: array[0..1] of Integer =
    (1, 8); //no divider for higher levels
  HASH_BITS = 12;

{
  make HASH_BITS bits long hash of first 4 bytes
}
function hash4(const x: pbyte): integer; inline;
var
  v: uint32;
begin
  v := puint32(x)^;
  result := uint32(v * 2654435771) >> 20;
end;


{ TSlidingBuffer }

constructor TSlidingBuffer.Init();
begin
  //we need some padding for match searching at the end of input data
  _buffer := getmem(2 * MAX_BLOCK_SIZE + MAX_DEFLATE_MATCH_LENGTH);
  _buffer += MAX_BLOCK_SIZE;
  FillByte((_buffer + MAX_BLOCK_SIZE)^, MAX_DEFLATE_MATCH_LENGTH, 0);
  _previous_bytes_count := 0;
end;

destructor TSlidingBuffer.Done;
begin
  freemem(_buffer - MAX_BLOCK_SIZE);
end;

function TSlidingBuffer.GetWindow: pbyte;
begin
  result := _buffer;
end;

procedure TSlidingBuffer.InsertData(const data: pbyte; const size: integer);
begin
  Assert(size <= MAX_BLOCK_SIZE, 'cannot insert more data than allocated range');

  if _previous_bytes_count > 0 then
      move((_buffer + _previous_bytes_count - MAX_BLOCK_SIZE)^,
           (_buffer - MAX_BLOCK_SIZE)^,
           MAX_BLOCK_SIZE);

  move(data^, _buffer^, size);
  _previous_bytes_count := size;
end;


{ TMatchSearcher }

constructor TMatchSearcher.Create;
begin
  _sbuffer.Init();
  _max_search_depth := SEARCH_DEPTH[0];
  _max_search_match_length := MAX_DEFLATE_MATCH_LENGTH;

  _links := getmem(2 * DICT_SIZE * sizeof(integer));
  _last_seen_idx := getmem(1 shl HASH_BITS * sizeof(integer));  //must be equal to hash bits
  Filldword(_last_seen_idx^, 1 shl HASH_BITS, $ffffffff );  //negative indices don't get searched, so use -1
  _current_chunk_size := 0;
  _bytes_processed := 0;
end;

destructor TMatchSearcher.Destroy;
begin
  freemem(_links);
  freemem(_last_seen_idx);
  _sbuffer.Done;
  inherited;
end;

procedure TMatchSearcher.SetCompressionLevel(const level: integer);
begin
  Assert(level <= MAX_COMPRESSION_LEVEL, 'invalid compression level');
  _max_search_depth := SEARCH_DEPTH[level];
  if level < High(SEARCH_MATCH_DIVIDER) then
      _max_search_match_length := MAX_DEFLATE_MATCH_LENGTH div SEARCH_MATCH_DIVIDER[level]
end;

{
  Take next data chunk and create links between the occurences of the same hash
}
procedure TMatchSearcher.NewData(const data: pbyte; const size: integer);
var
  i, key, last_seen: integer;
  p: PByte;
begin
  _sbuffer.InsertData(data, size);
  p := _sbuffer.GetWindow;
  _bytes_processed += _current_chunk_size;
  _current_chunk_size := size;

  move((_links + DICT_SIZE)^, _links^, DICT_SIZE * sizeof(integer));
  for i := -2 to size - 3 do begin
      key := hash4(p + i);
      last_seen := _last_seen_idx[key];
      _last_seen_idx[key] := i + _bytes_processed;
      _links[DICT_SIZE + i] := last_seen;
  end;
end;

{ compare_strings
  Compare 4 bytes at time between window and string data, after first mismatch compare single byte
  at time. There must be at least MAX_DEFLATE_MATCH_LENGTH valid bytes in window, so it needs some
  extra padding. Comparing 8 bytes is slower; non-inlined version is about 5% slower.
}
function compare_strings(window, string_data: pbyte): integer; inline;
var
  i: PtrInt;
begin
  result := 0;
  while PUInt32(window)^ = PUInt32(string_data)^ do begin
      window += 4;
      string_data += 4;
      result += 4;
      if result + 4 > MAX_DEFLATE_MATCH_LENGTH then break;
  end;
  for i := result to MAX_DEFLATE_MATCH_LENGTH - 1 do
      if window^ = string_data^ then begin
          window += 1;
          string_data += 1;
          result += 1;
      end
      else
          exit;
end;

{
  Compare last byte of the window against current string.
}
function compare_strings_rle(const string_data: pbyte; const byte_value, max_match_length: integer): integer;
var
  i: integer;
begin
  result := 0;
  for i := 0 to max_match_length - 1 do
      if byte_value = string_data[i] then
          result += 1
      else
          exit;
end;


function InitSearchResult(const distance, best_match: longword): TSearchResult; inline;
begin
  longword(result) := longword( best_match << 16 or distance );
end;

function TMatchSearcher.Search(const window_end_ptr, str: pbyte;
  const current_idx, max_match_length: integer): TSearchResult;
var
  i: integer;
  links: pinteger;
  best_match_distance: integer;
  best_match_length: integer;
  last_seen_idx: IntPtr;
  min_allowed_idx: integer;
  previous_idx: integer;
  length: integer;
  distance: integer;
  max_length: integer;
begin
  Assert(max_match_length >= 3);
  max_length := max_match_length;
  if _max_search_match_length < max_length then max_length := _max_search_match_length;

  //test if searched string is a repetition of the last byte before full search
  best_match_length := compare_strings_rle(str, window_end_ptr[-1], max_match_length);
  result := InitSearchResult(1, best_match_length);
  if best_match_length >= max_length then
      exit;

  last_seen_idx := current_idx - _bytes_processed;
  links := _links + DICT_SIZE;
  best_match_distance := 1;
  min_allowed_idx := max(0, current_idx - DICT_SIZE);

  //early termination if links of the next searched position are much closer than current ones
  if links[last_seen_idx] < links[last_seen_idx + 1] - (DICT_SIZE shr 1) then
      exit;
    //does this help much? probably disable if lazymatching

  for i := _max_search_depth - 1 downto 0 do begin
      //if the position falls out of the sliding window_end_ptr range, it's too old and cannot be searched
      previous_idx := links[last_seen_idx];
      if previous_idx < min_allowed_idx then begin
          break;
      end;
      last_seen_idx := previous_idx - _bytes_processed;

      //compare data at given positions
      distance := current_idx - previous_idx;
      length := compare_strings(window_end_ptr - distance, str);

      if length > best_match_length then begin
          best_match_length := length;
          best_match_distance := distance;
          if length >= max_length then
              break;
      end;
  end;

  if best_match_length > max_match_length then
      best_match_length := max_match_length;

  Assert(best_match_distance >= 0);
  result := InitSearchResult(best_match_distance, best_match_length);
end;

{
  Find best match between current bytes and bytes already seen.
  If distance = 0 & length = 0 - no occurences were found
}
function TMatchSearcher.FindMatch(const str: pbyte; const data_index: integer): TSearchResult;
var
  max_match_length: integer;
  current_idx: integer;
  window_end_ptr: pbyte;
begin
  result := InitSearchResult(0, 0);

  //reduce maximum possible match length at the end of the stream
  //we need at least 3 bytes to be able to run search (hash function takes 3 bytes as input)
  max_match_length := min(MAX_DEFLATE_MATCH_LENGTH, _current_chunk_size - data_index);
  if max_match_length <= 2 then
      exit;

  //beginning of a stream, nothing to search
  if _bytes_processed + data_index = 0 then
      exit;

  //get proper search window and currently searched string's file index
  window_end_ptr := _sbuffer.GetWindow + data_index;
  current_idx := _bytes_processed + data_index;

  result := Search(window_end_ptr, str, current_idx, max_match_length);
end;



end.

(*******************************************************************************
Copyright (c) 2007-2018 David Pethes

This file is part of Dc2.

Dc2 is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Dc2 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Dc2.  If not, see <http://www.gnu.org/licenses/>.

*******************************************************************************)
