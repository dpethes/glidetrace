{
Glide2x + SDL1.2 binding

You can copy and use unmodified imgui_impl_* files in your project.
If you use this binding you'll need to call 4 functions: ImGui_ImplXXXX_Init(), ImGui_ImplXXXX_NewFrame(), Imgui_ImplXXXX_RenderDrawLists() and ImGui_ImplXXXX_Shutdown().
If you are new to ImGui, see examples/README.txt and documentation at the top of imgui.cpp.
https://github.com/ocornut/imgui
}

unit fpimgui_impl_glide2x;
{$mode objfpc}{$H+}

interface

uses
  SDL, Glide2x, fpimgui, math;

procedure ImGui_ImplSdlGlide2x_Init();
procedure ImGui_ImplSdlGlide2x_Shutdown();
procedure ImGui_ImplSdlGlide2x_NewFrame();
procedure Imgui_ImplSdlGlide2x_RenderDrawLists(draw_data: PImDrawData); cdecl;
function  ImGui_ImplSdlGlide2x_ProcessEvent(event: PSDL_Event): boolean;

implementation

// Data
var
  g_Time: double = 0.0;
  g_MousePressed: array[0..2] of bool = ( false, false, false );
  g_MouseWheel: single = 0.0;
  g_FontTexture: record
      adress : TFxU32;
      info: TGrTexInfo;
  end;


function ImGui_ImplSdlGlide2x_ProcessEvent(event: PSDL_Event): boolean;
var
  io: PImGuiIO;
  button: UInt8;
  key: TSDLKey;
  textbuf: array[0..1] of UInt16;
begin
  result := false;
  io := igGetIO();
  case event^.type_ of
  SDL_MOUSEBUTTONDOWN: begin
      button := event^.button.button;
      if button = SDL_BUTTON_LEFT   then g_MousePressed[0] := true;
      if button = SDL_BUTTON_RIGHT  then g_MousePressed[1] := true;
      if button = SDL_BUTTON_MIDDLE then g_MousePressed[2] := true;
      if button = SDL_BUTTON_WHEELUP   then g_MouseWheel := 1;
      if button = SDL_BUTTON_WHEELDOWN then g_MouseWheel := -1;
      result := true;
  end;
  SDL_KEYDOWN, SDL_KEYUP: begin
      key := event^.key.keysym.sym;
      io^.KeysDown[key] := event^.type_ = SDL_KEYDOWN;
      io^.KeyShift := (SDL_GetModState() and KMOD_SHIFT) <> 0;
      io^.KeyCtrl  := (SDL_GetModState() and KMOD_CTRL)  <> 0;
      io^.KeyAlt   := (SDL_GetModState() and KMOD_ALT)   <> 0;
      io^.KeySuper := (SDL_GetModState() and KMOD_META)  <> 0;

      if event^.type_ = SDL_KEYDOWN then begin
          textbuf[0] := event^.key.keysym.unicode;
          textbuf[1] := 0;
          ImGuiIO_AddInputCharactersUTF8(@textbuf);
      end;
      result := true;
  end;
  end;
end;


procedure ImGui_ImplSdlGlide2x_CreateDeviceObjects();
var
  io: PImGuiIO;
  pixels: pbyte;
  width, height: integer;
  font_atlas: PImFontAtlas;
begin
  // Build texture atlas
  io := igGetIO();
  font_atlas := io^.Fonts;
  //ImFontAtlas_AddFontDefault(font_atlas);
  font_atlas^.TexDesiredWidth := 256;
  ImFontAtlas_GetTexDataAsAlpha8(font_atlas, @pixels, @width, @height);
  Assert((width = 256) and (height = 128), 'unexpected texture size');

  // Upload texture to graphics system
  g_FontTexture.info.smallLod := GR_LOD_256;
  g_FontTexture.info.largeLod := GR_LOD_256;
  g_FontTexture.info.aspectRatio := GR_ASPECT_2x1;
  g_FontTexture.info.format := GR_TEXFMT_ALPHA_8;
  g_FontTexture.info.data := pixels;
  g_FontTexture.adress := grTexMaxAddress(GR_TMU0) - 256*128;
  grTexDownloadMipMap(GR_TMU0, g_FontTexture.adress, GR_MIPMAPLEVELMASK_BOTH, @g_FontTexture.info);

  // Store our identifier
  ImFontAtlas_SetTexID(font_atlas, ImTextureID(g_FontTexture.adress));

  SDL_EnableUNICODE(1);
end;

procedure ImGui_ImplSdlGlide2x_InvalidateDeviceObjects();
begin
  //nothing needed?
end;

function ImGui_MemAlloc(sz:size_t): pointer; cdecl;
begin
  result := Getmem(sz);
end;

procedure ImGui_MemFree(ptr:pointer); cdecl;
begin
  Freemem(ptr);
end;

procedure ImGui_ImplSdlGlide2x_Init;
var
  io: PImGuiIO;
begin
  io := igGetIO();

  // Keyboard mapping. ImGui will use those indices to peek into the io.KeyDown[] array.
  io^.KeyMap[ImGuiKey_Tab] := SDLK_TAB;
  io^.KeyMap[ImGuiKey_LeftArrow] := SDLK_LEFT;
  io^.KeyMap[ImGuiKey_RightArrow] := SDLK_RIGHT;
  io^.KeyMap[ImGuiKey_UpArrow] := SDLK_UP;
  io^.KeyMap[ImGuiKey_DownArrow] := SDLK_DOWN;
  io^.KeyMap[ImGuiKey_PageUp] := SDLK_PAGEUP;
  io^.KeyMap[ImGuiKey_PageDown] := SDLK_PAGEDOWN;
  io^.KeyMap[ImGuiKey_Home] := SDLK_HOME;
  io^.KeyMap[ImGuiKey_End] := SDLK_END;
  io^.KeyMap[ImGuiKey_Delete] := SDLK_DELETE;
  io^.KeyMap[ImGuiKey_Backspace] := SDLK_BACKSPACE;
  io^.KeyMap[ImGuiKey_Enter] := SDLK_RETURN;
  io^.KeyMap[ImGuiKey_Escape] := SDLK_ESCAPE;
  io^.KeyMap[ImGuiKey_A] := SDLK_a;
  io^.KeyMap[ImGuiKey_C] := SDLK_c;
  io^.KeyMap[ImGuiKey_V] := SDLK_v;
  io^.KeyMap[ImGuiKey_X] := SDLK_x;
  io^.KeyMap[ImGuiKey_Y] := SDLK_y;
  io^.KeyMap[ImGuiKey_Z] := SDLK_z;

  io^.RenderDrawListsFn := @Imgui_ImplSdlGlide2x_RenderDrawLists;
  io^.SetClipboardTextFn := nil;
  io^.GetClipboardTextFn := nil;
  io^.ClipboardUserData := nil;

  // Allocate memory through pascal's memory allocator.
  // This is optional, for example for seeing the number of memory allocations through HeapTrc
  io^.MemAllocFn := @ImGui_MemAlloc;
  io^.MemFreeFn :=  @ImGui_MemFree;
end;

procedure ImGui_ImplSdlGlide2x_Shutdown();
begin
  ImGui_ImplSdlGlide2x_InvalidateDeviceObjects();
  igShutdown();
end;

procedure ImGui_ImplSdlGlide2x_NewFrame();
var
  io: PImGuiIO;
  time, mouseMask: UInt32;
  current_time: double;
  mx, my: Integer;
begin
  if g_FontTexture.adress = 0 then
      ImGui_ImplSdlGlide2x_CreateDeviceObjects();

  io := igGetIO();

  // Setup display size (every frame to accommodate for window resizing)
  io^.DisplaySize := ImVec2Init(grSstScreenWidth(), grSstScreenHeight());
  io^.DisplayFramebufferScale := ImVec2Init(1, 1);

  // Setup time step
  time := SDL_GetTicks();
  current_time := time / 1000.0;
  if (g_Time > 0.0) then
      io^.DeltaTime := current_time - g_Time
  else
      io^.DeltaTime := 1.0/60.0;
  g_Time := current_time;

  // Setup inputs
  // (we already got mouse wheel, keyboard keys & characters from SDL_PollEvent())
  mouseMask := SDL_GetMouseState(mx, my);
  io^.MousePos := ImVec2Init(mx, my);

  // If a mouse press event came, always pass it as "mouse held this frame", so we don't miss click-release events that are shorter than 1 frame.
  io^.MouseDown[0] := g_MousePressed[0] or (mouseMask and SDL_BUTTON(SDL_BUTTON_LEFT) <> 0);
  io^.MouseDown[1] := g_MousePressed[1] or (mouseMask and SDL_BUTTON(SDL_BUTTON_RIGHT) <> 0);
  io^.MouseDown[2] := g_MousePressed[2] or (mouseMask and SDL_BUTTON(SDL_BUTTON_MIDDLE) <> 0);
  g_MousePressed[0] := false;
  g_MousePressed[1] := false;
  g_MousePressed[2] := false;

  io^.MouseWheel := g_MouseWheel;
  g_MouseWheel := 0.0;

  // Hide OS mouse cursor if ImGui is drawing it
  if io^.MouseDrawCursor then SDL_ShowCursor(SDL_DISABLE) else SDL_ShowCursor(SDL_ENABLE);

  // Start the frame
  igNewFrame();
end;

procedure ResetGlideState;
begin
  grTexMipMapMode(GR_TMU0, GR_MIPMAP_DISABLE, FXFALSE);
  grTexFilterMode(GR_TMU0, GR_TEXTUREFILTER_BILINEAR, GR_TEXTUREFILTER_BILINEAR);  //not strictly necessary
  grChromakeyMode(GR_CHROMAKEY_DISABLE);
  grFogMode(GR_FOG_DISABLE);
  grCullMode(GR_CULL_DISABLE);
  grRenderBuffer(GR_BUFFER_BACKBUFFER);
  grAlphaTestFunction(GR_CMP_ALWAYS);
  grAlphaControlsITRGBLighting(FXFALSE);
  grColorMask(FXTRUE, FXFALSE);
  grDepthMask(FXFALSE);
  grDepthBufferMode(GR_DEPTHBUFFER_DISABLE);
  grDepthBufferFunction(GR_CMP_LESS);

  grChromakeyValue(0);
  grAlphaTestReferenceValue(0);
  grDepthBiasLevel(0);
  grFogColorValue(0);
  grConstantColorValue(not TFxU32(0));
  grHints(GR_HINT_STWHINT, 0);
end;

procedure Imgui_ImplSdlGlide2x_RenderDrawLists(draw_data: PImDrawData); cdecl;
var
  n, cmd_i, i, k: integer;
  cmd_list: PImDrawList;
  vtx_buffer: PImDrawVert;
  idx_buffer: PImDrawIdx;
  pcmd: PImDrawCmd;
  n_triangles: integer;
  idx: integer;
  imvtx: ImDrawVert;
  triangle: array[0..2] of TGrVertex;
  t: PGrVertex;
  clip: ImVec4;
  clip_x, clip_y, clip_w, clip_h: integer;
  scr_width, scr_height: integer;
  state: TGrState;
begin
  grGlideGetState(@state);
  ResetGlideState();

  grSstOrigin(GR_ORIGIN_UPPER_LEFT);

  grColorCombine(GR_COMBINE_FUNCTION_SCALE_OTHER, GR_COMBINE_FACTOR_LOCAL,
                 GR_COMBINE_LOCAL_ITERATED, GR_COMBINE_OTHER_TEXTURE, FXFALSE);
  grTexCombine(GR_TMU0, GR_COMBINE_FUNCTION_LOCAL, GR_COMBINE_FACTOR_NONE,
               GR_COMBINE_FUNCTION_LOCAL, GR_COMBINE_FACTOR_NONE,
               FXFALSE, FXFALSE);
  guAlphaSource(GR_ALPHASOURCE_TEXTURE_ALPHA_TIMES_ITERATED_ALPHA);
  grAlphaBlendFunction(GR_BLEND_SRC_ALPHA, GR_BLEND_ONE_MINUS_SRC_ALPHA, GR_BLEND_ZERO, GR_BLEND_ZERO);

  grTexSource(GR_TMU0, g_FontTexture.adress, GR_MIPMAPLEVELMASK_BOTH, @g_FontTexture.info);

  scr_width := grSstScreenWidth();
  scr_height := grSstScreenHeight();

  // Render command lists
  Assert(SizeOf(ImDrawIdx) = 2);

  for n := 0 to draw_data^.CmdListsCount - 1 do begin
      cmd_list := draw_data^.CmdLists[n];
      vtx_buffer := cmd_list^.VtxBuffer.Data;
      idx_buffer := cmd_list^.IdxBuffer.Data;

      for cmd_i := 0 to cmd_list^.CmdBuffer.Size - 1 do begin
          pcmd := @(cmd_list^.CmdBuffer.Data[cmd_i]);
          if pcmd^.UserCallback <> nil then begin
              pcmd^.UserCallback(cmd_list, pcmd);
          end else begin
              clip := pcmd^.ClipRect;
              clip_x := trunc(max(0, clip.x));
              clip_y := trunc(max(0, clip.y));
              clip_w := trunc(max(0, min(clip.z, scr_width )));
              clip_h := trunc(max(0, min(clip.w, scr_height)));
              grClipWindow(clip_x, clip_y, clip_w, clip_h);

              //we use only one texture, so ignore texId for now
              //texId := pcmd^.TextureId;
              n_triangles := pcmd^.ElemCount div 3;
              for i := 0 to n_triangles - 1 do begin
                  for k := 0 to 2 do begin
                      idx := idx_buffer[i * 3 + k];
                      imvtx := vtx_buffer[idx];
                      t := @triangle[k];
                      t^.x := imvtx.pos.x;
                      t^.y := imvtx.pos.y;
                      t^.z := 0;
                      t^.r := (imvtx.col) and $ff;
                      t^.g := (imvtx.col >> 8) and $ff;
                      t^.b := (imvtx.col >> 16) and $ff;
                      t^.a := (imvtx.col >> 24) and $ff;
                      t^.ooz := 1;
                      t^.oow := 1;
                      t^.tmuvtx[0].sow := imvtx.uv.x * 256;  //our texture is 256*128
                      t^.tmuvtx[0].tow := imvtx.uv.y * 128;
                  end;
                  guDrawTriangleWithClip(@triangle[0], @triangle[1], @triangle[2]);
              end;

          end;
          idx_buffer += pcmd^.ElemCount
      end;
  end;

  grGlideSetState(@state);
end;

end.

