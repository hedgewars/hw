(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2008 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 *)

{$I "options.inc"}

unit SDLh;
interface

{$IFDEF LINUX}
  {$DEFINE UNIX}
{$ENDIF}
{$IFDEF FREEBSD}
  {$DEFINE UNIX}
{$ENDIF}

{$IFDEF UNIX}
  {$IFNDEF DARWIN}
    {$linklib c}
  {$ENDIF}
  {$linklib pthread}
{$ENDIF}

{$IFDEF FPC}
  {$PACKRECORDS C}
{$ELSE}
  {$DEFINE cdecl attribute(cdecl)}
{$ENDIF}

{$IFDEF DARWIN}
  {$PASCALMAINNAME SDL_main}
  {$IFNDEF IPHONEOS}
    {$linkframework Cocoa}
    {$linkframework SDL}
    {$linkframework SDL_net}
    {$linkframework SDL_image}
    {$linkframework SDL_ttf}
    {$linkframework SDL_mixer}
  {$ENDIF}
{$ENDIF}


(*  SDL  *)
const
{$IFDEF WIN32}
	SDLLibName = 'SDL.dll';
	SDL_TTFLibName = 'SDL_ttf.dll';
	SDL_MixerLibName = 'SDL_mixer.dll';
	SDL_ImageLibName = 'SDL_image.dll';
	SDL_NetLibName = 'SDL_net.dll';
{$ELSE}
  {$IFDEF DARWIN}
	SDLLibName = 'SDL';
	SDL_TTFLibName = 'SDL_ttf';
	SDL_MixerLibName = 'SDL_mixer';
	SDL_ImageLibName = 'SDL_image';
	SDL_NetLibName = 'SDL_net';
  {$ELSE}
	SDLLibName = 'libSDL.so';
	SDL_TTFLibName = 'libSDL_ttf.so';
	SDL_MixerLibName = 'libSDL_mixer.so';
	SDL_ImageLibName = 'libSDL_image.so';
	SDL_NetLibName = 'libSDL_net.so';
  {$ENDIF}
{$ENDIF}

/////////////////////////////////////////////////////////////////
/////////////////////  CONSTANT DEFINITIONS /////////////////////
/////////////////////////////////////////////////////////////////

	SDL_SWSURFACE     = $00000000;
	SDL_HWSURFACE     = $00000001;
	SDL_SRCALPHA      = $00010000;
	
	SDL_INIT_TIMER    = $00000001;
	SDL_INIT_AUDIO    = $00000010;
	SDL_INIT_VIDEO    = $00000020;
	SDL_INIT_JOYSTICK = $00000200;
{$IFDEF SDL13}
	SDL_INIT_HAPTIC   = $00001000;
{$ELSE}
	SDL_INIT_CDROM	  = $00000100;
{$ENDIF}
	SDL_INIT_NOPARACHUTE = $00100000;
	SDL_INIT_EVENTTHREAD = $01000000;
	SDL_INIT_EVERYTHING  = $0000FFFF;

	SDL_APPINPUTFOCUS    = 2;
	SDL_BUTTON_WHEELUP   = 4;
	SDL_BUTTON_WHEELDOWN = 5;
		
{*begin SDL_Event binding*}
	SDL_NOEVENT = 0;
	SDL_KEYDOWN = 2;
	SDL_KEYUP = 3;
{$IFDEF SDL13}
        SDL_WINDOWEVENT = 1;
        SDL_TEXTINPUT = 4;
        SDL_TEXTEDITING = 5;
	SDL_MOUSEMOTION  = 6;
        SDL_MOUSEBUTTONDOWN = 7;
	SDL_MOUSEBUTTONUP   = 8;
        SDL_MOUSEWHEEL = 9;
	SDL_JOYAXISMOTION = 10;
	SDL_JOYBALLMOTION = 11;
	SDL_JOYHATMOTION = 12;
	SDL_JOYBUTTONDOWN = 13;
	SDL_JOYBUTTONUP = 14;
	SDL_QUITEV = 15;
{$ELSE}
        SDL_ACTIVEEVENT = 1;
	SDL_MOUSEMOTION  = 4;
       	SDL_MOUSEBUTTONDOWN = 5;
	SDL_MOUSEBUTTONUP   = 6;
	SDL_JOYAXISMOTION = 7;
	SDL_JOYBALLMOTION = 8;
	SDL_JOYHATMOTION = 9;
	SDL_JOYBUTTONDOWN = 10;
	SDL_JOYBUTTONUP = 11;
	SDL_QUITEV = 12;
	SDL_VIDEORESIZE = 16; // TODO: outdated? no longer in SDL 1.3?
{$ENDIF}
{*end SDL_Event binding*}
		
{$IFDEF SDL13}
	SDL_ASYNCBLIT   = $08000000;
	SDL_ANYFORMAT   = $10000000;
	SDL_HWPALETTE   = $00200000;
	SDL_DOUBLEBUF   = $00400000;
	SDL_FULLSCREEN  = $00800000;
	SDL_HWACCEL     = $08000000;
	SDL_SRCCOLORKEY = $00020000;
	SDL_RLEACCEL    = $08000000;
	SDL_NOFRAME     = $02000000;
	SDL_OPENGL      = $04000000;
	SDL_RESIZABLE   = $01000000;
{$ELSE}
	SDL_ASYNCBLIT   = $00000004;
	SDL_ANYFORMAT   = $00100000;
	SDL_HWPALETTE   = $20000000;
	SDL_DOUBLEBUF   = $40000000;
	SDL_FULLSCREEN  = $80000000;
	SDL_HWACCEL     = $00000100;
	SDL_SRCCOLORKEY = $00001000;
	SDL_RLEACCEL    = $00004000;
	SDL_NOFRAME     = $00000020;
	SDL_OPENGL      = $00000002;
	SDL_RESIZABLE   = $00000010;
{$ENDIF}


{$IFDEF ENDIAN_LITTLE}
	RMask = $000000FF;
	GMask = $0000FF00;
	BMask = $00FF0000;
	AMask = $FF000000;
{$ELSE}
	RMask = $FF000000;
	GMask = $00FF0000;
	BMask = $0000FF00;
	AMask = $000000FF;
{$ENDIF}

	{* SDL_mixer *}
	MIX_MAX_VOLUME = 128;
	MIX_INIT_FLAC = $00000001;
	MIX_INIT_MOD  = $00000002;
	MIX_INIT_MP3  = $00000004;
	MIX_INIT_OGG  = $00000008;
	
	{* SDL_TTF *}
	TTF_STYLE_NORMAL = 0;
	TTF_STYLE_BOLD   = 1;
	TTF_STYLE_ITALIC = 2;

	{* SDL Joystick *}
	SDL_HAT_CENTERED  = $00;
	SDL_HAT_UP        = $01;
	SDL_HAT_RIGHT     = $02;
	SDL_HAT_DOWN      = $04;
	SDL_HAT_LEFT      = $08;
	SDL_HAT_RIGHTUP   = SDL_HAT_RIGHT or SDL_HAT_UP;
	SDL_HAT_RIGHTDOWN = SDL_HAT_RIGHT or SDL_HAT_DOWN;
	SDL_HAT_LEFTUP    = SDL_HAT_LEFT or SDL_HAT_UP;
	SDL_HAT_LEFTDOWN  = SDL_HAT_LEFT or SDL_HAT_DOWN;

	{* SDL_image *}
	IMG_INIT_JPG = $00000001;
	IMG_INIT_PNG = $00000002;
	IMG_INIT_TIF = $00000004;

/////////////////////////////////////////////////////////////////
///////////////////////  TYPE DEFINITIONS ///////////////////////
/////////////////////////////////////////////////////////////////

type 
	PSDL_Rect = ^TSDL_Rect;
	TSDL_Rect = record
{$IFDEF SDL13}
		x, y, w, h: LongInt;
{$ELSE}
		x, y: SmallInt;
		w, h: Word;
{$ENDIF}
		end;

	TPoint = record
		X: LongInt;
		Y: LongInt;
		end;

	PSDL_PixelFormat = ^TSDL_PixelFormat;
	TSDL_PixelFormat = record
		palette: Pointer;
		BitsPerPixel : Byte;
		BytesPerPixel: Byte;
		Rloss : Byte;
		Gloss : Byte;
		Bloss : Byte;
		Aloss : Byte;
		Rshift: Byte;
		Gshift: Byte;
		Bshift: Byte;
		Ashift: Byte;
		RMask : Longword;
		GMask : Longword;
		BMask : Longword;
		AMask : Longword;
		colorkey: Longword;
		alpha : Byte;
		end;


	PSDL_Surface = ^TSDL_Surface;
	TSDL_Surface = record
		flags : Longword;
		format: PSDL_PixelFormat;
		w, h  : LongInt;
		pitch : Word;
		pixels: Pointer;
		offset: LongInt;
		end;


	PSDL_Color = ^TSDL_Color;
	TSDL_Color = record
		case byte of
			0: (	r: Byte;
				g: Byte;
				b: Byte;
				unused: Byte;
			   );
			1: (	value: Longword);
		end;


	PSDL_RWops = ^TSDL_RWops;
	TSeek  = function( context: PSDL_RWops; offset: LongInt; whence: LongInt ): LongInt; cdecl;
	TRead  = function( context: PSDL_RWops; Ptr: Pointer; size: LongInt; maxnum : LongInt ): LongInt;  cdecl;
	TWrite = function( context: PSDL_RWops; Ptr: Pointer; size: LongInt; num: LongInt ): LongInt; cdecl;
	TClose = function( context: PSDL_RWops ): LongInt; cdecl;

	TStdio = record
		autoclose: LongInt;
		fp: pointer;
		end;

	TMem = record
		base: PByte;
		here: PByte;
		stop: PByte;
		end;

	TUnknown = record
		data1: Pointer;
		end;

	TSDL_RWops = record
		seek: TSeek;
		read: TRead;
		write: TWrite;
		close: TClose;
		type_: Longword;
		case Byte of
			0: (stdio: TStdio);
			1: (mem: TMem);
			2: (unknown: TUnknown);
			end;

	TSDL_KeySym = record
		scancode: Byte;
		sym: Longword;
		modifier: Longword;
		unicode: Word;
		end;


{* SDL_Event type definition *}

{$IFDEF SDL13}
	TSDL_WindowID = LongInt;

	TSDL_WindowEvent = record
		type_: byte;
		gain: byte;
		state: byte;
		windowID: TSDL_WindowID;
		data1, data2: LongInt;
		end;

// implement SDL_TextEditingEvent + SDL_TextInputEvent for sdl13
{$ELSE}
	TSDL_ActiveEvent = record
		type_: byte;
		gain: byte;
		state: byte;
		end;
{$ENDIF}

	TSDL_MouseMotionEvent = record
		type_: byte;
		which: byte;
		state: byte;
{$IFDEF SDL13}
		x, y, xrel, yrel : LongInt;
		pressure, pressure_max, pressure_min,
		rotation, tilt, cursor: LongInt; 
{$ELSE}
		x, y, xrel, yrel : word;
{$ENDIF}
		end;

	TSDL_KeyboardEvent = record
		type_: Byte;
{$IFDEF SDL13}
		windowID: TSDL_WindowID;
{$ENDIF}
		which: Byte;
		state: Byte;
		keysym: TSDL_KeySym;
		end;

	TSDL_MouseButtonEvent = record
		_type,
		which,
		button,
		state: byte;
{$IFDEF SDL13}
		x, y: LongInt;
{$ELSE}
		x, y: word;
{$ENDIF}
		end;

{$IFDEF SDL13}
	TSDL_MouseWheelEvent = record
		type_: Byte;
		windowID: TSDL_WindowID;
		which: Byte;
		x, y: LongInt;
		end;
{$ENDIF}

	TSDL_JoyAxisEvent = record
		type_: Byte;
		which: Byte;
		axis: Byte;
{$IFDEF SDL13}
		value: LongInt;
{$ELSE}
		value: word;
{$ENDIF}	
		end;
			
	TSDL_JoyBallEvent = record
		type_: Byte;
		which: Byte;
		ball: Byte;
{$IFDEF SDL13}
		xrel, yrel: LongInt;
{$ELSE}
		xrel, yrel: word;
{$ENDIF}
		end;

	TSDL_JoyHatEvent = record
		type_: Byte;
		which: Byte;
		hat: Byte;
		value: Byte;
		end;
	
	TSDL_JoyButtonEvent = record
		type_: Byte;
		which: Byte;
		button: Byte;
		state: Byte;
		end;

	TSDL_QuitEvent = record
                type_: Byte;
                end;

{$IFNDEF SDL13}
	TSDL_ResizeEvent = record
		type_: Byte;
		w, h: LongInt;
		end;
{$ENDIF}

	PSDL_Event = ^TSDL_Event;
	TSDL_Event = record
		case Byte of
			SDL_NOEVENT: (type_: byte);
{$IFDEF SDL13}
			SDL_WINDOWEVENT: (active: TSDL_WindowEvent);
			SDL_KEYDOWN,
			SDL_KEYUP: (key: TSDL_KeyboardEvent);
			SDL_TEXTEDITING,
			SDL_TEXTINPUT: (txtin: byte);
			SDL_MOUSEMOTION: (motion: TSDL_MouseMotionEvent);
			SDL_MOUSEBUTTONDOWN,
			SDL_MOUSEBUTTONUP: (button: TSDL_MouseButtonEvent);
			SDL_MOUSEWHEEL: (wheel: TSDL_MouseWheelEvent);
			SDL_JOYAXISMOTION: (jaxis: TSDL_JoyAxisEvent);
			SDL_JOYHATMOTION: (jhat: TSDL_JoyHatEvent);
			SDL_JOYBALLMOTION: (jball: TSDL_JoyBallEvent);
			SDL_JOYBUTTONDOWN,
			SDL_JOYBUTTONUP: (jbutton: TSDL_JoyButtonEvent);
			SDL_QUITEV: (quit: TSDL_QuitEvent);
{$ELSE}
			SDL_ACTIVEEVENT: (active: TSDL_ActiveEvent);
			SDL_KEYDOWN,
			SDL_KEYUP: (key: TSDL_KeyboardEvent);
			SDL_MOUSEMOTION: (motion: TSDL_MouseMotionEvent);
			SDL_MOUSEBUTTONDOWN,
			SDL_MOUSEBUTTONUP: (button: TSDL_MouseButtonEvent);
			SDL_JOYAXISMOTION: (jaxis: TSDL_JoyAxisEvent);
			SDL_JOYHATMOTION: (jhat: TSDL_JoyHatEvent);
			SDL_JOYBALLMOTION: (jball: TSDL_JoyBallEvent);
			SDL_JOYBUTTONDOWN,
			SDL_JOYBUTTONUP: (jbutton: TSDL_JoyButtonEvent);
			SDL_QUITEV: (quit: TSDL_QuitEvent);
			//SDL_SYSWMEVENT,SDL_EVENT_RESERVEDA,SDL_EVENT_RESERVEDB
			//SDL_VIDEORESIZE: (resize: TSDL_ResizeEvent);
{$ENDIF}
		end;

	PByteArray = ^TByteArray;
	TByteArray = array[0..65535] of Byte;
	PLongWordArray = ^TLongWordArray;
	TLongWordArray = array[0..16383] of LongWord;

	PSDL_Thread = Pointer;
	PSDL_mutex = Pointer;

	TSDL_GLattr = (
		SDL_GL_RED_SIZE,
		SDL_GL_GREEN_SIZE,
		SDL_GL_BLUE_SIZE,
		SDL_GL_ALPHA_SIZE,
		SDL_GL_BUFFER_SIZE,
		SDL_GL_DOUBLEBUFFER,
		SDL_GL_DEPTH_SIZE,
		SDL_GL_STENCIL_SIZE,
		SDL_GL_ACCUM_RED_SIZE,
		SDL_GL_ACCUM_GREEN_SIZE,
		SDL_GL_ACCUM_BLUE_SIZE,
		SDL_GL_ACCUM_ALPHA_SIZE,
		SDL_GL_STEREO,
		SDL_GL_MULTISAMPLEBUFFERS,
		SDL_GL_MULTISAMPLESAMPLES,
		SDL_GL_ACCELERATED_VISUAL,
{$IFDEF SDL13}
		SDL_GL_RETAINED_BACKING,
		SDL_GL_CONTEXT_MAJOR_VERSION,
		SDL_GL_CONTEXT_MINOR_VERSION
{$ELSE}
		SDL_GL_SWAP_CONTROL
{$ENDIF}
		);

{$IFDEF SDL13}
	TSDL_ArrayByteOrder = (  // array component order, low byte -> high byte 
		SDL_ARRAYORDER_NONE,
		SDL_ARRAYORDER_RGB,
		SDL_ARRAYORDER_RGBA,
		SDL_ARRAYORDER_ARGB,
		SDL_ARRAYORDER_BGR,
		SDL_ARRAYORDER_BGRA,
		SDL_ARRAYORDER_ABGR
		);
{$ENDIF}

// Joystick/Controller support
	PSDL_Joystick = ^TSDL_Joystick;
	TSDL_Joystick = record
			end;

	{* SDL_TTF *}
	PTTF_Font = ^TTTF_font;
	TTTF_Font = record
		    end;

	{* SDL_mixer *}
	PMixChunk = ^TMixChunk;
	TMixChunk = record
		allocated: Longword;
		abuf     : PByte;
		alen     : Longword;
		volume   : PByte;
		end;
	TMusic = (MUS_CMD, MUS_WAV, MUS_MOD, MUS_MID, MUS_OGG, MUS_MP3);
	TMix_Fading = (MIX_NO_FADING, MIX_FADING_OUT, MIX_FADING_IN);

	TMidiSong = record
               samples : LongInt;
               events  : pointer;
               end;

	TMusicUnion = record
		case Byte of
		     0: ( midi : TMidiSong );
		     1: ( ogg  : pointer);
		     end;

	PMixMusic = ^TMixMusic;
	TMixMusic = record
                 end;

	{* SDL_net *}
	TIPAddress = record
                  host: Longword;
                  port: Word;
                  end;

	PTCPSocket = ^TTCPSocket;
	TTCPSocket = record
                  ready: LongInt;
                  channel: LongInt;
                  remoteAddress: TIPaddress;
                  localAddress: TIPaddress;
                  sflag: LongInt;
                  end;
	PSDLNet_SocketSet = ^TSDLNet_SocketSet;
	TSDLNet_SocketSet = record
                         numsockets,
                         maxsockets: LongInt;
                         sockets: PTCPSocket;
                         end;


/////////////////////////////////////////////////////////////////
/////////////////////  FUNCTION DEFINITIONS /////////////////////
/////////////////////////////////////////////////////////////////


{* SDL *}
function  SDL_Init(flags: Longword): LongInt; cdecl; external SDLLibName;
function  SDL_InitSubSystem(flags: LongWord): LongInt; cdecl; external SDLLibName;
procedure SDL_Quit; cdecl; external SDLLibName;

function  SDL_VideoDriverName(var namebuf; maxlen: LongInt): PChar; cdecl; external SDLLibName;
procedure SDL_EnableUNICODE(enable: LongInt); cdecl; external SDLLibName;

procedure SDL_Delay(msec: Longword); cdecl; external SDLLibName;
function  SDL_GetTicks: Longword; cdecl; external SDLLibName;

function  SDL_MustLock(Surface: PSDL_Surface): Boolean;
function  SDL_LockSurface(Surface: PSDL_Surface): LongInt; cdecl; external SDLLibName;
procedure SDL_UnlockSurface(Surface: PSDL_Surface); cdecl; external SDLLibName;

function  SDL_GetError: PChar; cdecl; external SDLLibName;

function  SDL_SetVideoMode(width, height, bpp: LongInt; flags: Longword): PSDL_Surface; cdecl; external SDLLibName;
function  SDL_CreateRGBSurface(flags: Longword; Width, Height, Depth: LongInt; RMask, GMask, BMask, AMask: Longword): PSDL_Surface; cdecl; external SDLLibName;
function  SDL_CreateRGBSurfaceFrom(pixels: Pointer; width, height, depth, pitch: LongInt; RMask, GMask, BMask, AMask: Longword): PSDL_Surface; cdecl; external SDLLibName;
procedure SDL_FreeSurface(Surface: PSDL_Surface); cdecl; external SDLLibName;
function  SDL_SetColorKey(surface: PSDL_Surface; flag, key: Longword): LongInt; cdecl; external SDLLibName;
function  SDL_SetAlpha(surface: PSDL_Surface; flag, key: Longword): LongInt; cdecl; external SDLLibName;
function  SDL_ConvertSurface(src: PSDL_Surface; fmt: PSDL_PixelFormat; flags: LongInt): PSDL_Surface; cdecl; external SDLLibName;

function  SDL_UpperBlit(src: PSDL_Surface; srcrect: PSDL_Rect; dst: PSDL_Surface; dstrect: PSDL_Rect): LongInt; cdecl; external SDLLibName;
function  SDL_FillRect(dst: PSDL_Surface; dstrect: PSDL_Rect; color: Longword): LongInt; cdecl; external SDLLibName;
procedure SDL_UpdateRect(Screen: PSDL_Surface; x, y: LongInt; w, h: Longword); cdecl; external SDLLibName;
function  SDL_Flip(Screen: PSDL_Surface): LongInt; cdecl; external SDLLibName;

procedure SDL_GetRGB(pixel: Longword; fmt: PSDL_PixelFormat; r, g, b: PByte); cdecl; external SDLLibName;
function  SDL_MapRGB(format: PSDL_PixelFormat; r, g, b: Byte): Longword; cdecl; external SDLLibName;
function  SDL_MapRGBA(format: PSDL_PixelFormat; r, g, b, a: Byte): Longword; cdecl; external SDLLibName;

function  SDL_DisplayFormat(Surface: PSDL_Surface): PSDL_Surface; cdecl; external SDLLibName;
function  SDL_DisplayFormatAlpha(Surface: PSDL_Surface): PSDL_Surface; cdecl; external SDLLibName;

function  SDL_RWFromFile(filename, mode: PChar): PSDL_RWops; cdecl; external SDLLibName;
function  SDL_SaveBMP_RW(surface: PSDL_Surface; dst: PSDL_RWops; freedst: LongInt): LongInt; cdecl; external SDLLibName;

{$IFDEF SDL13}
function  SDL_GetKeyboardState(numkeys: PLongInt): PByteArray; cdecl; external SDLLibName;
function  SDL_SelectMouse(index: LongInt): LongInt; cdecl; external SDLLibName;
function  SDL_GetRelativeMouseState(index: LongInt; x, y: PLongInt): Byte; cdecl; external SDLLibName;
function  SDL_GetNumMice: LongInt; cdecl; external SDLLibName;
function  SDL_PixelFormatEnumToMasks(format: TSDL_ArrayByteOrder; bpp: PLongInt; Rmask, Gmask, Bmask, Amask: PLongInt): boolean; cdecl; external SDLLibName;
{$ELSE}
function  SDL_GetKeyState(numkeys: PLongInt): PByteArray; cdecl; external SDLLibName;
{$ENDIF}
function  SDL_GetMouseState(x, y: PLongInt): Byte; cdecl; external SDLLibName;
function  SDL_GetKeyName(key: Longword): PChar; cdecl; external SDLLibName;
procedure SDL_WarpMouse(x, y: Word); cdecl; external SDLLibName;

procedure SDL_PumpEvents; cdecl; external SDLLibName;
function  SDL_PollEvent(event: PSDL_Event): LongInt; cdecl; external SDLLibName;
function  SDL_WaitEvent(event: PSDL_Event): LongInt; cdecl; external SDLLibName;

function  SDL_ShowCursor(toggle: LongInt): LongInt; cdecl; external SDLLibName;

procedure SDL_WM_SetCaption(title: PChar; icon: PChar); cdecl; external SDLLibName;
function  SDL_WM_ToggleFullScreen(surface: PSDL_Surface): LongInt; cdecl; external SDLLibName;

function  SDL_CreateMutex: PSDL_mutex; cdecl; external SDLLibName;
procedure SDL_DestroyMutex(mutex: PSDL_mutex); cdecl; external SDLLibName;
function  SDL_LockMutex(mutex: PSDL_mutex): LongInt; cdecl; external SDLLibName name 'SDL_mutexP';
function  SDL_UnlockMutex(mutex: PSDL_mutex): LongInt; cdecl; external SDLLibName name 'SDL_mutexV';

function  SDL_GL_SetAttribute(attr: TSDL_GLattr; value: LongInt): LongInt; cdecl; external SDLLibName;
procedure SDL_GL_SwapBuffers(); cdecl; external SDLLibName;

{$IFDEF IPHONEOS}
function  SDL_iPhoneKeyboardShow(windowID: LongInt): LongInt; cdecl; external SDLLibName;
function  SDL_iPhoneKeyboardHide(windowID: LongInt): LongInt; cdecl; external SDLLibName;
function  SDL_iPhoneKeyboardIsShown(windowID: LongInt): boolean; cdecl; external SDLLibName;
function  SDL_iPhoneKeyboardToggle(windowID: LongInt): LongInt; cdecl; external SDLLibName;
{$ENDIF}

function  SDL_NumJoysticks: LongInt; cdecl; external SDLLibName;
function  SDL_JoystickName(idx: LongInt): PChar; cdecl; external SDLLibName;
function  SDL_JoystickOpen(idx: LongInt): PSDL_Joystick; cdecl; external SDLLibName;
function  SDL_JoystickOpened(idx: LongInt): LongInt; cdecl; external SDLLibName;
function  SDL_JoystickIndex(joy: PSDL_Joystick): LongInt; cdecl; external SDLLibName;
function  SDL_JoystickNumAxes(joy: PSDL_Joystick): LongInt; cdecl; external SDLLibName;
function  SDL_JoystickNumBalls(joy: PSDL_Joystick): LongInt; cdecl; external SDLLibName;
function  SDL_JoystickNumHats(joy: PSDL_Joystick): LongInt; cdecl; external SDLLibName;
function  SDL_JoystickNumButtons(joy: PSDL_Joystick): LongInt; cdecl; external SDLLibName;
procedure SDL_JoystickUpdate; cdecl; external SDLLibName;
function  SDL_JoystickEventState(state: LongInt): LongInt; cdecl; external SDLLibName;
function  SDL_JoystickGetAxis(joy: PSDL_Joystick; axis: LongInt): LongInt; cdecl; external SDLLibName;
function  SDL_JoystickGetBall(joy: PSDL_Joystick; ball: LongInt; dx: PInteger; dy: PInteger): Word; cdecl; external SDLLibName;
function  SDL_JoystickGetHat(joy: PSDL_Joystick; hat: LongInt): Byte; cdecl; external SDLLibName;
function  SDL_JoystickGetButton(joy: PSDL_Joystick; button: LongInt): Byte; cdecl; external SDLLibName;
procedure SDL_JoystickClose(joy: PSDL_Joystick); cdecl; external SDLLibName;

(*  SDL_TTF  *)
function  TTF_Init: LongInt; cdecl; external SDL_TTFLibName;
procedure TTF_Quit; cdecl; external SDL_TTFLibName;

function  TTF_SizeUTF8(font: PTTF_Font; const text: PChar; var w, h: LongInt): LongInt; cdecl; external SDL_TTFLibName;

function  TTF_RenderUTF8_Solid(font: PTTF_Font; const text: PChar; fg: TSDL_Color): PSDL_Surface; cdecl; external SDL_TTFLibName;
function  TTF_RenderUTF8_Blended(font: PTTF_Font; const text: PChar; fg: TSDL_Color): PSDL_Surface; cdecl; external SDL_TTFLibName;
function  TTF_RenderUTF8_Shaded(font: PTTF_Font; const text: PChar; fg, bg: TSDL_Color): PSDL_Surface; cdecl; external SDL_TTFLibName;

function  TTF_OpenFont(const filename: PChar; size: LongInt): PTTF_Font; cdecl; external SDL_TTFLibName;
procedure TTF_SetFontStyle(font: PTTF_Font; style: LongInt); cdecl; external SDL_TTFLibName;

(*  SDL_mixer  *)
function  Mix_Init(flags: LongInt): LongInt; cdecl; external SDL_MixerLibName;
procedure Mix_Quit; cdecl; external SDL_MixerLibName;

function  Mix_OpenAudio(frequency: LongInt; format: Word; channels: LongInt; chunksize: LongInt): LongInt; cdecl; external SDL_MixerLibName;
procedure Mix_CloseAudio; cdecl; external SDL_MixerLibName;

function  Mix_Volume(channel: LongInt; volume: LongInt): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_SetDistance(channel: LongInt; distance: Byte): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_VolumeMusic(volume: LongInt): LongInt; cdecl; external SDL_MixerLibName;

function  Mix_AllocateChannels(numchans: LongInt): LongInt; cdecl; external SDL_MixerLibName;
procedure Mix_FreeChunk(chunk: PMixChunk); cdecl; external SDL_MixerLibName;
procedure Mix_FreeMusic(music: PMixMusic); cdecl; external SDL_MixerLibName;

function  Mix_LoadWAV_RW(src: PSDL_RWops; freesrc: LongInt): PMixChunk; cdecl; external SDL_MixerLibName;
function  Mix_LoadMUS(const filename: PChar): PMixMusic; cdecl; external SDL_MixerLibName;

function  Mix_Playing(channel: LongInt): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_PlayingMusic: LongInt; cdecl; external SDL_MixerLibName;
function  Mix_FadeInMusic(music: PMixMusic; loops: LongInt; ms: LongInt): LongInt; cdecl; external SDL_MixerLibName;

function  Mix_PlayChannelTimed(channel: LongInt; chunk: PMixChunk; loops: LongInt; ticks: LongInt): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_PlayMusic(music: PMixMusic; loops: LongInt): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_PausedMusic(music: PMixMusic): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_PauseMusic(music: PMixMusic): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_ResumeMusic(music: PMixMusic): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_HaltChannel(channel: LongInt): LongInt; cdecl; external SDL_MixerLibName;

(*  SDL_image  *)
function  IMG_Init(flags: LongInt): LongInt; cdecl; external SDL_ImageLibName;
procedure IMG_Quit; cdecl; external SDL_ImageLibName;

function  IMG_Load(const _file: PChar): PSDL_Surface; cdecl; external SDL_ImageLibName;
function  IMG_LoadPNG_RW(rwop: PSDL_RWops): PSDL_Surface; cdecl; external SDL_ImageLibName;

(*  SDL_net  *)
function  SDLNet_Init: LongInt; cdecl; external SDL_NetLibName;
procedure SDLNet_Quit; cdecl; external SDL_NetLibName;

function  SDLNet_AllocSocketSet(maxsockets: LongInt): PSDLNet_SocketSet; cdecl; external SDL_NetLibName;
function  SDLNet_ResolveHost(var address: TIPaddress; host: PChar; port: Word): LongInt; cdecl; external SDL_NetLibName;
function  SDLNet_TCP_Accept(server: PTCPsocket): PTCPSocket; cdecl; external SDL_NetLibName;
function  SDLNet_TCP_Open(var ip: TIPaddress): PTCPSocket; cdecl; external SDL_NetLibName;
function  SDLNet_TCP_Send(sock: PTCPsocket; data: Pointer; len: LongInt): LongInt; cdecl; external SDL_NetLibName;
function  SDLNet_TCP_Recv(sock: PTCPsocket; data: Pointer; len: LongInt): LongInt; cdecl; external SDL_NetLibName;
procedure SDLNet_TCP_Close(sock: PTCPsocket); cdecl; external SDL_NetLibName;
procedure SDLNet_FreeSocketSet(_set: PSDLNet_SocketSet); cdecl; external SDL_NetLibName;
function  SDLNet_AddSocket(_set: PSDLNet_SocketSet; sock: PTCPSocket): LongInt; cdecl; external SDL_NetLibName;
function  SDLNet_CheckSockets(_set: PSDLNet_SocketSet; timeout: LongInt): LongInt; cdecl; external SDL_NetLibName;


procedure SDLNet_Write16(value: Word; buf: pointer);
procedure SDLNet_Write32(value: LongWord; buf: pointer);
function  SDLNet_Read16(buf: pointer): Word;
function  SDLNet_Read32(buf: pointer): LongWord;

{$IFDEF IPHONEOS}
function  get_documents_path: PChar; cdecl; external 'hwutils';
procedure IPH_showControls; cdecl; external name 'showControls';
{$ENDIF}

implementation

function SDL_MustLock(Surface: PSDL_Surface): Boolean;
begin
	SDL_MustLock:= ( surface^.offset <> 0 ) or (( surface^.flags and (SDL_HWSURFACE or SDL_ASYNCBLIT or SDL_RLEACCEL)) <> 0)
end;

procedure SDLNet_Write16(value: Word; buf: pointer);
begin
	PByteArray(buf)^[1]:= value;
	PByteArray(buf)^[0]:= value shr 8
end;

procedure SDLNet_Write32(value: LongWord; buf: pointer);
begin
	PByteArray(buf)^[3]:= value;
	PByteArray(buf)^[2]:= value shr  8;
	PByteArray(buf)^[1]:= value shr 16;
	PByteArray(buf)^[0]:= value shr 24
end;

function SDLNet_Read16(buf: pointer): Word;
begin
	SDLNet_Read16:= PByteArray(buf)^[1] or
                 (PByteArray(buf)^[0] shl 8)
end;

function SDLNet_Read32(buf: pointer): LongWord;
begin
	SDLNet_Read32:=  PByteArray(buf)^[3] or
                  (PByteArray(buf)^[2] shl  8) or
                  (PByteArray(buf)^[1] shl 16) or
                  (PByteArray(buf)^[0] shl 24)
end;

end.

