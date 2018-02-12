unit display;

{$mode objfpc}{$H+}

interface

uses
  sdl;

type
  { TDisplay }
  TDisplay = class
  public
      procedure InitDisplay(const Width, Height: word);
      procedure FreeDisplay;
      procedure Update;
      procedure Clear;
  private
      scr: PSDL_Surface;
      fmt: PSDL_PixelFormat;
      w, h: word;
  end;

implementation

{ TDisplay }

procedure TDisplay.InitDisplay(const Width, Height: word);
var
  flags: UInt32;
begin
  if (SDL_WasInit(SDL_INIT_VIDEO) and SDL_INIT_VIDEO) = 0 then begin
      writeln('display: init SDL');
      SDL_InitSubSystem(SDL_INIT_VIDEO);
  end;

  w := Width;
  h := Height;
  flags := SDL_SWSURFACE;
  scr := SDL_SetVideoMode(w, h, 16, flags);
  fmt := scr^.format;

  SDL_WM_SetCaption(PChar('display'), nil);
end;


procedure TDisplay.FreeDisplay;
begin
  SDL_FreeSurface(scr);
  SDL_QuitSubSystem(SDL_INIT_VIDEO);
end;

procedure TDisplay.Update;
begin
  SDL_UpdateRect(scr, 0, 0, 0, 0);
end;

procedure TDisplay.Clear;
begin
  SDL_FillRect(scr, nil, 0);
end;


end.
