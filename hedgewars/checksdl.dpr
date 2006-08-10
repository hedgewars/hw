program checksdl;
{$APPTYPE CONSOLE}
uses
  SDLh;

procedure fail;
begin
writeln('fail');
halt
end;

var SDLPrimSurface: PSDL_Surface;
    Color: Longword;
begin
Write('Init SDL... ');
if SDL_Init(SDL_INIT_VIDEO) < 0 then fail;
WriteLn('ok');

Write('Create primsurface... ');
SDLPrimSurface:= SDL_SetVideoMode(640, 480, 16, 0);
if (SDLPrimSurface = nil) then fail;
WriteLn('ok');

Write('Try map color... ');
Color:= $FFFFFF;
Color:= SDL_MapRGB(SDLPrimSurface^.format, (Color shr 16) and $FF, (Color shr 8) and $FF, Color and $FF);
Writeln('ok');
Writeln('Result = ', Color);

SDL_Quit()
end.