{ replay glide2x trace
}
program glide2x_retrace;

{$mode objfpc}{$H+}

uses
  classes, SysUtils, math, IniFiles,
  sdl, display, glide2x,
  fpimgui, fpimgui_impl_glide2x,
  gli_common, funcreplay, tracefile, wrapper_util;

var
  disp: TDisplay;
  glide_dll_path: string;

{ These glide initialization calls can be skipped if in trace, because they don't change the glide state.
}
procedure PrepareGlide;
var
  version: array[0..80] of char;
  hw_config: TGrHwConfiguration;
  board: string;
begin
  //must always match glide's GrVertex size
  Assert(sizeof(TGrVertex) = 60, 'TGrVertex size doesn''t match glide');

  if not glide2x.grSstQueryBoards(@hw_config) then
  begin
      writeln('no 3dfx board found!');
      exit;
  end;
  assert(hw_config.num_sst > 0);

  glide2x.grGlideInit;
  glide2x.grGlideGetVersion(@version);
  glide2x.grSstQueryHardware(@hw_config);
  board := 'unknown';
  case hw_config.SSTs[0].type_ of
      GR_SSTTYPE_VOODOO: board := 'Voodoo';
      GR_SSTTYPE_SST96: board := 'Rush';
      GR_SSTTYPE_AT3D: board := 'AT3D';
      GR_SSTTYPE_Voodoo2: board := 'Voodoo 2';
  end;
  writeln('library version: ' + version);
  writeln('boards found: ', hw_config.num_sst);
  writeln('board 0: ', board);

  glide2x.grSstSelect(0);
end;

{ Games (or their runtime) often mask more fpu exceptions than we do by default. If the game actually
  causes fpu exceptions, this manifests as a crash in grDraw* calls (unreal tournament, tomb raider).
  So mask all exceptions.
}
procedure MaskFPUExceptions;
var
  FPUException: TFPUException;
  FPUExceptionMask: TFPUExceptionMask;
begin
  FPUExceptionMask := GetExceptionMask;
  for FPUException := Low(TFPUException) to High(TFPUException) do begin
      FPUExceptionMask += [FPUException];
  end;
  SetExceptionMask(FPUExceptionMask);
end;

{ Handle glide calls. Functions that just get some value from glide and don't change its state
  are skipped. Functions with parameters and/or additional logic are handled in their
  corresponding *_do() functions
}
procedure InterpretFunc(glFunc: TraceFunc);
begin
  //writeln('func: ', TraceFuncNames[glFunc]);
  case glFunc of
      { System
      }
      grGlideInit:     writeln('call: grGlideInit');     //skip, already initialized
      grGlideShutdown: writeln('call: grGlideShutdown'); //skip, we do that ourselves
      grGlideGetVersion: ;  //skip
      //todo these two should be paired: get should store state until set is called; unless pairing is broken
      grGlideGetState: ;
      //grGlideSetState: grGlideSetState_do();

      grSstSelect: ;        //already selected 0 on init. Don't assume multiple adapters will be used
      grSstOrigin:          grSstOrigin_do();
      grSstIdle:            glide2x.grSstIdle();  //forces openglide to flush buffers, otherwise could be skipped on wrappers
      grSstControl: ;       //skip completely? also known as grSstControlMode
      grSstIsBusy,
      grSstQueryBoards,
      grSstQueryHardware,
      grSstScreenHeight,
      grSstScreenWidth,
      grSstStatus,
      grSstVideoLine,
      grSstVRetraceOn: ;    //skip

      grErrorSetCallback: ; //wrappers most likely never return anything; might be useful on real HW though

      { Windows
        If trace changes resolution and SDL window stays the same, dgVoodoo and nGlide can
        resize the window; openglide can't
        Probably recreate the window if single window isn't forced
      }
      grSstWinOpen: begin
          grSstWinOpen_do(disp);
          ImGui_ImplSdlGlide2x_NewFrame();
          Imgui.GetIO()^.MouseDrawCursor := true;  //useful in fullscreen mode
      end;
      grSstWinClose: begin
          grSstWinClose_do(disp);
      end;

      { Buffers
      }
      grBufferClear:          grBufferClear_do();
      grBufferSwap: ;         //buffer swaps are handled in the interpreter loop
      grRenderBuffer:         grRenderBuffer_do();
      grBufferNumPending: ;   //skip

      { LFB
        - writes go through a pointer, so exact modifications aren't traceable through API
        - reads can be skipped
      }
      grLfbLock: ; //glide2x.grLfbLock;
      grLfbUnlock: ; //glide2x.grLfbUnlock;
      grLfbReadRegion: ;  //skip
      grLfbWriteRegion: ; //do write region

      { Drawing
      }
      grAADrawPoint:          grAADrawPoint_do();
      grAADrawLine:           grAADrawLine_do();
      grAADrawTriangle:       grAADrawTriangle_do();
      grDrawPoint:            grDrawPoint_do();
      grDrawLine:             grDrawLine_do();
      grDrawTriangle:         grDrawTriangle_do();
      guDrawTriangleWithClip: guDrawTriangleWithClip_do();
      //one batch, two batch
      grDrawPlanarPolygon:             grDrawPlanarPolygon_do();
      grDrawPlanarPolygonVertexList:   grDrawPlanarPolygonVertexList_do();
      grDrawPolygon:                   grDrawPolygon_do();
      grDrawPolygonVertexList:         grDrawPolygonVertexList_do();

      { Textures
      }
      grTexClampMode:         grTexClampMode_do;
      grTexCombine:           grTexCombine_do;
      guTexCombineFunction,
      grTexCombineFunction:   guTexCombineFunction_do;  //they're the same
      grTexDownloadMipMap:             grTexDownloadMipMap_do;
      grTexDownloadMipMapLevel:        grTexDownloadMipMapLevel_do;
      grTexDownloadMipMapLevelPartial: grTexDownloadMipMapLevelPartial_do;
      grTexDownloadTable:              grTexDownloadTable_do;
      grTexDownloadTablePartial:       grTexDownloadTablePartial_do;
      grTexFilterMode:        grTexFilterMode_do;
      grTexLodBiasValue:      grTexLodBiasValue_do;
      grTexMipMapMode:        grTexMipMapMode_do;
      grTexSource:            grTexSource_do;
      grTexTextureMemRequired,
      grTexCalcMemRequired,
      grTexMaxAddress,
      grTexMinAddress: ;      //skip

      //alloc TGrMipMapId -s and compare them to stored id-s. if they'll differ from run to run, we need remapping
      guTexAllocateMemory:    guTexAllocateMemory_do;
      guTexChangeAttributes:  guTexChangeAttributes_do;
      guTexDownloadMipMap:    guTexDownloadMipMap_do;
      guTexMemReset:          guTexMemReset_do;
      guTexSource:            guTexSource_do;
      guTexGetCurrentMipMap,
      guTexGetMipMapInfo,
      guTexMemQueryAvail: ;   //skip

      { configuration and special effect maintenance functions
      }
      grChromakeyMode:        grChromakeyMode_do();
      grChromakeyValue:       grChromakeyValue_do();
      grClipWindow:           grClipWindow_do();

      grAlphaBlendFunction:   grAlphaBlendFunction_do();
      grAlphaCombine:         grAlphaCombine_do();
      grAlphaTestFunction:    grAlphaTestFunction_do();
      grAlphaTestReferenceValue: grAlphaTestReferenceValue_do();

      grColorCombine:         grColorCombine_do();
      grColorMask:            grColorMask_do();
      grConstantColorValue:   grConstantColorValue_do();
      grCullMode:             grCullMode_do();
      grDepthBiasLevel:       grDepthBiasLevel_do();
      grDepthBufferFunction:  grDepthBufferFunction_do();
      grDepthBufferMode:      grDepthBufferMode_do();
      grDepthMask:            grDepthMask_do();
      grDisableAllEffects:    glide2x.grDisableAllEffects();
      grDitherMode:           grDitherMode_do();

      grFogColorValue:        grFogColorValue_do();
      grFogMode:              grFogMode_do();
      grFogTable:             grFogTable_do();

      grGammaCorrectionValue: grGammaCorrectionValue_do();
      grHints:                grHints_do();
      grSplash: ;             //skip
      grGlideShamelessPlug: ; //skip

      { utility functions
      }
      guAlphaSource:          guAlphaSource_do();
      guColorCombineFunction: guColorCombineFunction_do();
      gu3dfGetInfo,
      gu3dfLoad,
      guFogGenerateExp,
      guFogGenerateExp2,
      guFogGenerateLinear,
      guFogTableIndexToW: ;   //skip

      { perf info, only works on real HW }
      grSstPerfStats, grSstResetPerfStats, grTriStats, grResetTriStats: ;  //skip

      { todo - easy to add, but they are missing test cases
      grAADrawPolygon
      grAADrawPolygonVertexList
      guAADrawTriangleWithClip

      grAlphaControlsITRGBLighting
      grConstantColorValue4

      grLfbConstantAlpha
      grLfbConstantDepth

      grTexDetailControl
      grTexMultibase
      grTexMultibaseAddress
      grTexNCCTable
      guTexDownloadMipMapLevel
      }

      { obsolete / missing documentation / unimplemented in wrappers
      grLfbWriteColorFormat
      grLfbWriteColorSwizzle
      grCheckForRoom
      guDrawPolygonVertexListWithClip
      guEncodeRLE16
      guEndianSwapBytes
      guEndianSwapWords
      guTexCreateColorMipMap
      ConvertAndDownloadRle
      }
      else
      begin
          writeln('cannot interpret command: ', TraceFuncNames[glFunc]);
      end;
  end;
end;

{ Be careful to not load the tracing glide2x
  With dgVoodoo, you have to use the debug version, as the normal version crashes with debugger attached.
}
procedure LoadConfig;
var
  cfg: TIniFile;
begin
  cfg := TIniFile.Create('glide2x_retrace.ini', false);
  glide_dll_path := cfg.ReadString('config', 'Wrapper', '..\glide2x.dll');
  g_rep.force_single_window := cfg.ReadBool('config', 'ForceSingleWindow', false);
  g_rep.disable_gamma       := cfg.ReadBool('config', 'DisableGamma', false);
  g_rep.disable_tex         := cfg.ReadBool('config', 'DisableTextures', false);
  g_rep.wireframe           := cfg.ReadBool('config', 'EnableWireframe', false);
  g_rep.force_tmu0 := false;
  cfg.Free;
  //glide_dll_path := '..\glide2x.psvoodoo.dll';
  //glide_dll_path := '..\gld.dll';
  //glide_dll_path := '..\glide2x.dg.dll';
  //g_rep.force_single_window := true;  //block multiple calls to grSstWinOpen, as it can be annoying at times
  //g_rep.disable_gamma := true;  //disable grGammaCorrectionValue
  //g_rep.disable_tex := true;    //disable texture alloc/download/source/combine
  //g_rep.wireframe := true;      //replace triangle calls with lines
end;

const
  TRACE_FILE_NAME = 'trace.bin';

var
  ev: TSDL_Event;
  key: TSDLKey;
  glFunc, i: TraceFunc;
  frames: integer;

  done: boolean = false;
  load_next_frame: boolean;
  ui: record
      sleep_ms: integer;
      play: boolean;
      buffer_clears_on_swap: boolean;
      frame_analysis: boolean;
      step_forward,
      step_backward: boolean;
  end;
  draw_call: record
    count,
    max,
    start, limit: integer;
  end;
  glFuncCallStats: array[TraceFunc] of integer;

begin
  if not FileExists(TRACE_FILE_NAME) then begin
      writeln('could not find input trace!');
      halt;
  end;
  if not OpenTraceFileRead(TRACE_FILE_NAME) then begin
      writeln('invalid trace!');
      halt;
  end;
  LoadConfig;

  //init wrapper
  InitGlideFromLibrary(glide_dll_path);
  PrepareGlide;

  //reserve "plenty" of space - should be enough for one glide call param list
  g_rep.scratchpad := getmem(16 * (1 shl 20));
  g_rep.mmid_translation_table := getmem(MMID_TRANSLATION_TABLE_SIZE);
  g_rep.active_tmus[GR_TMU0] := false;
  g_rep.active_tmus[GR_TMU1] := false;
  g_rep.active_tmus[GR_TMU2] := false;
  g_rep.frame_draw_call_skip := false;

  //open SDL window
  disp := TDisplay.Create;
  ImGui_ImplSdlGlide2x_Init();
  ImGui.StyleColorsDark(ImGui.GetStyle());
  ImGui.GetStyle()^.WindowRounding := 0;
  ImGui.GetStyle()^.Colors[ImGuiCol_WindowBg] := ImVec4Init(0.05, 0.05, 0.05, 0.4);

  //see no evil
  MaskFPUExceptions;

  //init UI state
  done := false;
  frames := 0;
  for i := Low(TraceFunc) to High(TraceFunc) do
      glFuncCallStats[i] := 0;
  with draw_call do begin
      count := 0;
      max   := 0;
      start := 0;
      limit := 0;
  end;
  with ui do begin
      play := true;
      sleep_ms := 16;
      buffer_clears_on_swap := false;
      frame_analysis := false;
  end;

  while not done do begin
      glFunc := LoadFunc;
      InterpretFunc(glFunc);

      if glFunc in DrawCalls then
          draw_call.count += 1;

      g_rep.frame_draw_call_skip := draw_call.start > draw_call.count;
      if not ((glFunc in DrawCalls) and g_rep.frame_draw_call_skip) then
         glFuncCallStats[glFunc] += 1;

      //if the playback is stopped, we have to issue bufferswap ourselves
      //if not ui.play and (draw_call.count >= draw_call.limit) then
      //    glFunc := grBufferSwap;

      //some games can call shutdown and then init glide again, so stop only if there's no more data
      if glFunc = grGlideShutdown then
          done := not HaveMore;

      //run event handling and UI drawing
      if glFunc = grBufferSwap then
      begin
          //write(frames, #13);
          Imgui.Text('frame: %d (draws:%d)',[frames, draw_call.count]);
          ImGui.Text('data size: %d / %d', [g_tr.frame_size_bytes, g_tr.frame_compressed_size_bytes]);
          ImGui.Checkbox('play', @ui.play);
          if not ui.play then begin
              ImGui.SameLine();
              ImGui.Checkbox('analyze', @ui.frame_analysis);
              draw_call.limit := draw_call.count;
              if not ui.frame_analysis then begin  //todo why this breaks if analysis?
                  ImGui.SameLine();
                  ui.step_backward := ImGui.Button('<-');
                  ImGui.SameLine();
                  ui.step_forward := ImGui.Button('->');
              end;
          end;
          ImGui.Checkbox('wireframe', @g_rep.wireframe);
          ImGui.SameLine();
          ImGui.Checkbox('clear on swap', @ui.buffer_clears_on_swap);
          ImGui.SameLine();
          if ImGui.Button('re-upload gui texture') then
              ImGui_ImplSdlGlide2x_ReuploadFontTexture;
          ImGui.SliderInt('sleep', @ui.sleep_ms, 0, 100);
          for i := Low(TraceFunc) to High(TraceFunc) do begin
              if glFuncCallStats[i] > 0 then begin
                  Imgui.Text(TraceFuncNames[i] + ': %d', [glFuncCallStats[i]]);
                  glFuncCallStats[i] := 0;
              end;
          end;
          if not ui.play then begin
              ImGui.Begin_('calls');
              ImGui.PushItemWidth(-35);

              //todo limit max. num of calls for each frame individually
              ImGui.SliderInt('skip', @draw_call.start, 0, draw_call.max);
              ImGui.SliderInt('stop', @draw_call.limit, 0, draw_call.max);
              ImGui.PopItemWidth;

              ImGui.Text('TMU0/1/2 active: %s/%s/%s', [
                         BoolToStr(g_rep.active_tmus[GR_TMU0], true),
                         BoolToStr(g_rep.active_tmus[GR_TMU1], true),
                         BoolToStr(g_rep.active_tmus[GR_TMU2], true)]);
              ImGui.End_;
          end;
          Imgui.Render();

          glide2x.grBufferSwap(1);

          //unreal tournament doesn't clear the buffers - wireframe mode looks weird
          if ui.buffer_clears_on_swap then
              glide2x.grBufferClear(0,0,0);
          Sleep(ui.sleep_ms);

          //screenshots
          //g_ctx.buffer_swaps += 1;
          //SaveFrontBuffer();

          if SDL_PollEvent(@ev) <> 0 then begin
              case ev.type_ of
                  SDL_QUITEV:
                      done := True;
                  SDL_KEYDOWN:
                  begin
                      key := ev.key.keysym.sym;
                      case key of
                          SDLK_ESCAPE, SDLK_q: done := True;
                          SDLK_w: g_rep.wireframe := not g_rep.wireframe;
                          SDLk_p, SDLK_SPACE: ui.play := not ui.play;
                          SDLK_RIGHT: ui.step_forward := true;
                          SDLK_LEFT: ui.step_backward := true;
                      end;
                  end;
              end;
              ImGui_ImplSdlGlide2x_ProcessEvent(@ev);
          end;

          if not done then begin
              load_next_frame := false;
              if ui.play then begin
                  load_next_frame := true;
              end else begin
                  if ui.step_backward then begin
                      LoadPrevFrame;
                      frames -= 1;
                  end
                  else if ui.step_forward then begin
                      load_next_frame := true;
                  end
                  else
                      RewindFrame;
              end;
              if load_next_frame then begin
                  done := not HaveMore;
                  if not done then begin
                      LoadNewFrame;
                      frames += 1;
                  end;
              end;
          end;

          if draw_call.max < draw_call.count then
              draw_call.max := draw_call.count;
          draw_call.count := 0;

          ImGui_ImplSdlGlide2x_NewFrame();
      end;
  end;
  ImGui_ImplSdlGlide2x_Shutdown();
  CloseTraceFileRead;

  //close glide
  Sleep(250);
  if g_rep.force_single_window then begin
      glide2x.grSstWinClose();
      disp.FreeDisplay;
  end;
  disp.Free;
  glide2x.grGlideShutdown;

  freemem(g_rep.mmid_translation_table);
  freemem(g_rep.scratchpad);
end.
