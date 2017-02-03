(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *)

{$INCLUDE "options.inc"}

unit SDLh;
interface

{$IFDEF LINUX}
    {$DEFINE UNIX}
{$ENDIF}
{$IFDEF FREEBSD}
    {$DEFINE UNIX}
{$ENDIF}
{$IFDEF OPENBSD}
    {$DEFINE UNIX}
{$ENDIF}
{$IFDEF DARWIN}
    {$DEFINE UNIX}
{$ENDIF}
{$IFDEF HAIKU}
    {$DEFINE UNIX}
{$ENDIF}

{$IFDEF UNIX}
    {$IFDEF HAIKU}
        {$linklib root}
    {$ELSE}
        {$IFNDEF ANDROID}
            {$linklib pthread}
        {$ENDIF}
    {$ENDIF}
{$ENDIF}

{$IFDEF FPC}
    {$PACKRECORDS C}
{$ELSE}
    {$DEFINE cdecl attribute(cdecl)}
    type PByte = ^Byte;
    type PInteger = ^Integer;
    type PLongInt = ^LongInt;
{$ENDIF}


(*  SDL  *)
const
{$IFDEF WIN32}
    SDLLibName = 'SDL2.dll';
    SDL_TTFLibName = 'SDL2_ttf.dll';
    SDL_MixerLibName = 'SDL2_mixer.dll';
    SDL_ImageLibName = 'SDL2_image.dll';
    SDL_NetLibName = 'SDL2_net.dll';
{$ELSE}
    SDLLibName = 'libSDL2';
    SDL_TTFLibName = 'libSDL2_ttf';
    SDL_MixerLibName = 'libSDL2_mixer';
    SDL_ImageLibName = 'libSDL2_image';
    SDL_NetLibName = 'libSDL2_net';
{$ENDIF}

/////////////////////////////////////////////////////////////////
/////////////////////  CONSTANT DEFINITIONS /////////////////////
/////////////////////////////////////////////////////////////////

    // SDL_Init() flags
    SDL_INIT_TIMER          = $00000001;
    SDL_INIT_AUDIO          = $00000010;
    SDL_INIT_VIDEO          = $00000020; // implies SDL_INIT_EVENTS (sdl2)
    SDL_INIT_JOYSTICK       = $00000200; // implies SDL_INIT_EVENTS (sdl2)
    SDL_INIT_HAPTIC         = $00001000;
    SDL_INIT_GAMECONTROLLER = $00002000; // implies SDL_INIT_JOYSTICK
    SDL_INIT_EVENTS         = $00004000;
    SDL_INIT_NOPARACHUTE    = $00100000;
    //SDL_INIT_EVERYTHING                // unsafe, init subsystems one at a time

    SDL_ALLEVENTS        = $FFFFFFFF;    // dummy event type to prevent stack corruption
    SDL_APPINPUTFOCUS    = $02;

    // (some) audio formats from SDL_audio.h
    AUDIO_S16LSB         = $8010; // Signed 16-bit samples, in little-endian byte order
    AUDIO_S16MSB         = $9010; // Signed 16-bit samples, in big-endian byte order
    AUDIO_S16SYS         = {$IFDEF ENDIAN_LITTLE}AUDIO_S16LSB{$ELSE}AUDIO_S16MSB{$ENDIF};

    // default audio format from SDL_mixer.h
    MIX_DEFAULT_FORMAT   = AUDIO_S16SYS;

    SDL_BUTTON_LEFT      = 1;
    SDL_BUTTON_MIDDLE    = 2;
    SDL_BUTTON_RIGHT     = 3;
    SDL_BUTTON_X1        = 4;
    SDL_BUTTON_X2        = 5;


    SDL_TEXTEDITINGEVENT_TEXT_SIZE = 32;
    SDL_TEXTINPUTEVENT_TEXT_SIZE   = 32;

    // SDL_Event types
    // pascal does not support unions as is, so we list here every possible event
    // and later associate a struct type each
    SDL_FIRSTEVENT        = 0;              // type
    SDL_COMMONDEVENT      = 1;              // type and timestamp
    SDL_QUITEV            = $100;
    SDL_APP_TERMINATING   = $101;
    SDL_APP_LOWMEMORY     = $102;
    SDL_APP_WILLENTERBACKGROUND = $103;
    SDL_APP_DIDENTERBACKGROUND = $104;
    SDL_APP_WILLENTERFOREGROUND = $105;
    SDL_APP_DIDENTERFOREGROUND = $106;
    SDL_WINDOWEVENT       = $200;
    SDL_SYSWMEVENT        = $201;
    SDL_KEYDOWN           = $300;
    SDL_KEYUP             = $301;
    SDL_TEXTEDITING       = $302;
    SDL_TEXTINPUT         = $303;
    SDL_MOUSEMOTION       = $400;
    SDL_MOUSEBUTTONDOWN   = $401;
    SDL_MOUSEBUTTONUP     = $402;
    SDL_MOUSEWHEEL        = $403;
    SDL_JOYAXISMOTION     = $600;
    SDL_JOYBALLMOTION     = $601;
    SDL_JOYHATMOTION      = $602;
    SDL_JOYBUTTONDOWN     = $603;
    SDL_JOYBUTTONUP       = $604;
    SDL_JOYDEVICEADDED    = $605;
    SDL_JOYDEVICEREMOVED  = $606;
    SDL_CONTROLLERAXISMOTION = $650;
    SDL_CONTROLLERBUTTONDOWN = $651;
    SDL_CONTROLLERBUTTONUP = $652;
    SDL_CONTROLLERDEVICEADDED = $653;
    SDL_CONTROLLERDEVICEREMOVED = $654;
    SDL_CONTROLLERDEVICEREMAPPED = $655;
    SDL_FINGERDOWN        = $700;
    SDL_FINGERUP          = $701;
    SDL_FINGERMOTION      = $702;
    SDL_DOLLARGESTURE     = $800;
    SDL_DOLLARRECORD      = $801;
    SDL_MULTIGESTURE      = $802;
    SDL_CLIPBOARDUPDATE   = $900;
    SDL_DROPFILE          = $1000;
    SDL_USEREVENT         = $8000;
    SDL_LASTEVENT         = $FFFF;

    // SDL_Surface flags
    SDL_SWSURFACE   = $00000000;  //*< Not used */
    SDL_PREALLOC    = $00000001;  //*< Surface uses preallocated memory */
    SDL_RLEACCEL    = $00000002;  //*< Surface is RLE encoded */
    SDL_DONTFREE    = $00000004;  //*< Surface is referenced internally */
    SDL_SRCCOLORKEY = $00020000;  // compatibility only

    // SDL_RendererFlags
    SDL_RENDERER_SOFTWARE     = $00000001;     //*< The renderer is a software fallback */
    SDL_RENDERER_ACCELERATED  = $00000002;     //*< The renderer uses hardware acceleration */
    SDL_RENDERER_PRESENTVSYNC = $00000004;     //*< Present is synchronized with the refresh rate */
    SDL_RENDERER_TARGETTEXTURE = $00000008;    //*< The renderer supports rendering to texture */

    // SDL_WindowFlags
    SDL_WINDOW_FULLSCREEN    = $00000001;      //*< fullscreen window, implies borderless */
    SDL_WINDOW_OPENGL        = $00000002;      //*< window usable with OpenGL context */
    SDL_WINDOW_SHOWN         = $00000004;      //*< window is visible */
    SDL_WINDOW_HIDDEN        = $00000008;      //*< window is not visible */
    SDL_WINDOW_BORDERLESS    = $00000010;      //*< no window decoration */
    SDL_WINDOW_RESIZABLE     = $00000020;      //*< window can be resized */
    SDL_WINDOW_MINIMIZED     = $00000040;      //*< window is minimized */
    SDL_WINDOW_MAXIMIZED     = $00000080;      //*< window is maximized */
    SDL_WINDOW_INPUT_GRABBED = $00000100;      //*< window has grabbed input focus */
    SDL_WINDOW_INPUT_FOCUS   = $00000200;      //*< window has input focus */
    SDL_WINDOW_MOUSE_FOCUS   = $00000400;      //*< window has mouse focus */
    SDL_WINDOW_FULLSCREEN_DESKTOP = $00001001; //*< fullscreen as maximed window */
    SDL_WINDOW_FOREIGN       = $00000800;      //*< window not created by SDL */

    SDL_WINDOWPOS_CENTERED_MASK = $2FFF0000;

    // SDL_WindowEventID
    SDL_WINDOWEVENT_NONE         = 0;    //*< Never used
    SDL_WINDOWEVENT_SHOWN        = 1;    //*< Window has been shown
    SDL_WINDOWEVENT_HIDDEN       = 2;    //*< Window has been hidden
    SDL_WINDOWEVENT_EXPOSED      = 3;    //*< Window has been exposed and should be redrawn
    SDL_WINDOWEVENT_MOVED        = 4;    //*< Window has been moved to data1, data2
    SDL_WINDOWEVENT_RESIZED      = 5;    //*< Window size changed to data1xdata2
    SDL_WINDOWEVENT_SIZE_CHANGED = 6;    //*< The window size has changed, [...] */
    SDL_WINDOWEVENT_MINIMIZED    = 7;    //*< Window has been minimized
    SDL_WINDOWEVENT_MAXIMIZED    = 8;    //*< Window has been maximized
    SDL_WINDOWEVENT_RESTORED     = 9;    //*< Window has been restored to normal size and position
    SDL_WINDOWEVENT_ENTER        = 10;   //*< Window has gained mouse focus
    SDL_WINDOWEVENT_LEAVE        = 11;   //*< Window has lost mouse focus
    SDL_WINDOWEVENT_FOCUS_GAINED = 12;   //*< Window has gained keyboard focus
    SDL_WINDOWEVENT_FOCUS_LOST   = 13;   //*< Window has lost keyboard focus
    SDL_WINDOWEVENT_CLOSE        = 14;   //*< The window manager requests that the window be closed */

{$IFDEF ENDIAN_LITTLE}
    RMask = $000000FF;
    GMask = $0000FF00;
    BMask = $00FF0000;
    AMask = $FF000000;
    RShift = 0;
    GShift = 8;
    BShift = 16;
    AShift = 24;
{$ELSE}
    RMask = $FF000000;
    GMask = $00FF0000;
    BMask = $0000FF00;
    AMask = $000000FF;
    RShift = 24;
    GShift = 16;
    BShift = 8;
    AShift = 0;
{$ENDIF}

    KMOD_NONE   = $0000;
    KMOD_LSHIFT = $0001;
    KMOD_RSHIFT = $0002;
    KMOD_LCTRL  = $0040;
    KMOD_RCTRL  = $0080;
    KMOD_LALT   = $0400;
    KMOD_RALT   = $0800;
    KMOD_LMETA  = $0400;
    KMOD_RMETA  = $0800;
    KMOD_NUM    = $1000;
    KMOD_CAPS   = $2000;
    KMOD_MODE   = $4000;

    {* SDL_mixer *}
    MIX_MAX_VOLUME      = 128;
    MIX_INIT_FLAC       = $00000001;
    MIX_INIT_MOD        = $00000002;
    MIX_INIT_MODPLUG    = $00000004;
    MIX_INIT_MP3        = $00000008;
    MIX_INIT_OGG        = $00000010;
    MIX_INIT_FLUIDSYNTH = $00000020;

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
    SDL_HAT_LEFTUP    = SDL_HAT_LEFT  or SDL_HAT_UP;
    SDL_HAT_LEFTDOWN  = SDL_HAT_LEFT  or SDL_HAT_DOWN;

    {* SDL_image *}
    IMG_INIT_JPG = $00000001;
    IMG_INIT_PNG = $00000002;
    IMG_INIT_TIF = $00000004;

    {* SDL_keycode *}
    SDLK_UNKNOWN = 0;
    SDLK_BACKSPACE = 8;
    SDLK_RETURN    = 13;
    SDLK_ESCAPE    = 27;
    SDLK_a         = 97;
    SDLK_c         = 99;
    SDLK_q         = 113;
    SDLK_v         = 118;
    SDLK_w         = 119;
    SDLK_x         = 120;
    SDLK_DELETE    = 127;
    SDLK_KP_ENTER  = 271;
    SDLK_UP        = 273;
    SDLK_DOWN      = 274;
    SDLK_RIGHT     = 275;
    SDLK_LEFT      = 276;
    SDLK_HOME      = 278;
    SDLK_END       = 279;
    SDLK_PAGEUP    = 280;
    SDLK_PAGEDOWN  = 281;

    // special keycodes (for modifier keys etc. will have this bit set)
    SDLK_SCANCODE_MASK = (1 shl 30);

    SDL_SCANCODE_UNKNOWN = 0;
    SDL_SCANCODE_A = 4;
    SDL_SCANCODE_B = 5;
    SDL_SCANCODE_C = 6;
    SDL_SCANCODE_D = 7;
    SDL_SCANCODE_E = 8;
    SDL_SCANCODE_F = 9;
    SDL_SCANCODE_G = 10;
    SDL_SCANCODE_H = 11;
    SDL_SCANCODE_I = 12;
    SDL_SCANCODE_J = 13;
    SDL_SCANCODE_K = 14;
    SDL_SCANCODE_L = 15;
    SDL_SCANCODE_M = 16;
    SDL_SCANCODE_N = 17;
    SDL_SCANCODE_O = 18;
    SDL_SCANCODE_P = 19;
    SDL_SCANCODE_Q = 20;
    SDL_SCANCODE_R = 21;
    SDL_SCANCODE_S = 22;
    SDL_SCANCODE_T = 23;
    SDL_SCANCODE_U = 24;
    SDL_SCANCODE_V = 25;
    SDL_SCANCODE_W = 26;
    SDL_SCANCODE_X = 27;
    SDL_SCANCODE_Y = 28;
    SDL_SCANCODE_Z = 29;
    SDL_SCANCODE_1 = 30;
    SDL_SCANCODE_2 = 31;
    SDL_SCANCODE_3 = 32;
    SDL_SCANCODE_4 = 33;
    SDL_SCANCODE_5 = 34;
    SDL_SCANCODE_6 = 35;
    SDL_SCANCODE_7 = 36;
    SDL_SCANCODE_8 = 37;
    SDL_SCANCODE_9 = 38;
    SDL_SCANCODE_0 = 39;
    SDL_SCANCODE_RETURN = 40;
    SDL_SCANCODE_ESCAPE = 41;
    SDL_SCANCODE_BACKSPACE = 42;
    SDL_SCANCODE_TAB = 43;
    SDL_SCANCODE_SPACE = 44;
    SDL_SCANCODE_MINUS = 45;
    SDL_SCANCODE_EQUALS = 46;
    SDL_SCANCODE_LEFTBRACKET = 47;
    SDL_SCANCODE_RIGHTBRACKET = 48;
    SDL_SCANCODE_BACKSLASH = 49;
    SDL_SCANCODE_NONUSHASH = 50;
    SDL_SCANCODE_SEMICOLON = 51;
    SDL_SCANCODE_APOSTROPHE = 52;
    SDL_SCANCODE_GRAVE = 53;
    SDL_SCANCODE_COMMA = 54;
    SDL_SCANCODE_PERIOD = 55;
    SDL_SCANCODE_SLASH = 56;
    SDL_SCANCODE_CAPSLOCK = 57;
    SDL_SCANCODE_F1 = 58;
    SDL_SCANCODE_F2 = 59;
    SDL_SCANCODE_F3 = 60;
    SDL_SCANCODE_F4 = 61;
    SDL_SCANCODE_F5 = 62;
    SDL_SCANCODE_F6 = 63;
    SDL_SCANCODE_F7 = 64;
    SDL_SCANCODE_F8 = 65;
    SDL_SCANCODE_F9 = 66;
    SDL_SCANCODE_F10 = 67;
    SDL_SCANCODE_F11 = 68;
    SDL_SCANCODE_F12 = 69;
    SDL_SCANCODE_PRINTSCREEN = 70;
    SDL_SCANCODE_SCROLLLOCK = 71;
    SDL_SCANCODE_PAUSE = 72;
    SDL_SCANCODE_INSERT = 73;
    SDL_SCANCODE_HOME = 74;
    SDL_SCANCODE_PAGEUP = 75;
    SDL_SCANCODE_DELETE = 76;
    SDL_SCANCODE_END = 77;
    SDL_SCANCODE_PAGEDOWN = 78;
    SDL_SCANCODE_RIGHT = 79;
    SDL_SCANCODE_LEFT = 80;
    SDL_SCANCODE_DOWN = 81;
    SDL_SCANCODE_UP = 82;
    SDL_SCANCODE_NUMLOCKCLEAR = 83;
    SDL_SCANCODE_KP_DIVIDE = 84;
    SDL_SCANCODE_KP_MULTIPLY = 85;
    SDL_SCANCODE_KP_MINUS = 86;
    SDL_SCANCODE_KP_PLUS = 87;
    SDL_SCANCODE_KP_ENTER = 88;
    SDL_SCANCODE_KP_1 = 89;
    SDL_SCANCODE_KP_2 = 90;
    SDL_SCANCODE_KP_3 = 91;
    SDL_SCANCODE_KP_4 = 92;
    SDL_SCANCODE_KP_5 = 93;
    SDL_SCANCODE_KP_6 = 94;
    SDL_SCANCODE_KP_7 = 95;
    SDL_SCANCODE_KP_8 = 96;
    SDL_SCANCODE_KP_9 = 97;
    SDL_SCANCODE_KP_0 = 98;
    SDL_SCANCODE_KP_PERIOD = 99;
    SDL_SCANCODE_NONUSBACKSLASH = 100;
    SDL_SCANCODE_APPLICATION = 101;
    SDL_SCANCODE_POWER = 102;
    SDL_SCANCODE_KP_EQUALS = 103;
    SDL_SCANCODE_F13 = 104;
    SDL_SCANCODE_F14 = 105;
    SDL_SCANCODE_F15 = 106;
    SDL_SCANCODE_F16 = 107;
    SDL_SCANCODE_F17 = 108;
    SDL_SCANCODE_F18 = 109;
    SDL_SCANCODE_F19 = 110;
    SDL_SCANCODE_F20 = 111;
    SDL_SCANCODE_F21 = 112;
    SDL_SCANCODE_F22 = 113;
    SDL_SCANCODE_F23 = 114;
    SDL_SCANCODE_F24 = 115;
    SDL_SCANCODE_EXECUTE = 116;
    SDL_SCANCODE_HELP = 117;
    SDL_SCANCODE_MENU = 118;
    SDL_SCANCODE_SELECT = 119;
    SDL_SCANCODE_STOP = 120;
    SDL_SCANCODE_AGAIN = 121;
    SDL_SCANCODE_UNDO = 122;
    SDL_SCANCODE_CUT = 123;
    SDL_SCANCODE_COPY = 124;
    SDL_SCANCODE_PASTE = 125;
    SDL_SCANCODE_FIND = 126;
    SDL_SCANCODE_MUTE = 127;
    SDL_SCANCODE_VOLUMEUP = 128;
    SDL_SCANCODE_VOLUMEDOWN = 129;
    SDL_SCANCODE_KP_COMMA = 133;
    SDL_SCANCODE_KP_EQUALSAS400 = 134;
    SDL_SCANCODE_INTERNATIONAL1 = 135;
    SDL_SCANCODE_INTERNATIONAL2 = 136;
    SDL_SCANCODE_INTERNATIONAL3 = 137;
    SDL_SCANCODE_INTERNATIONAL4 = 138;
    SDL_SCANCODE_INTERNATIONAL5 = 139;
    SDL_SCANCODE_INTERNATIONAL6 = 140;
    SDL_SCANCODE_INTERNATIONAL7 = 141;
    SDL_SCANCODE_INTERNATIONAL8 = 142;
    SDL_SCANCODE_INTERNATIONAL9 = 143;
    SDL_SCANCODE_LANG1 = 144; (*< Hangul/English toggle *)
    SDL_SCANCODE_LANG2 = 145; (*< Hanja conversion *)
    SDL_SCANCODE_LANG3 = 146; (*< Katakana *)
    SDL_SCANCODE_LANG4 = 147; (*< Hiragana *)
    SDL_SCANCODE_LANG5 = 148; (*< Zenkaku/Hankaku *)
    SDL_SCANCODE_LANG6 = 149; (*< reserved *)
    SDL_SCANCODE_LANG7 = 150; (*< reserved *)
    SDL_SCANCODE_LANG8 = 151; (*< reserved *)
    SDL_SCANCODE_LANG9 = 152; (*< reserved *)
    SDL_SCANCODE_ALTERASE = 153;
    SDL_SCANCODE_SYSREQ = 154;
    SDL_SCANCODE_CANCEL = 155;
    SDL_SCANCODE_CLEAR = 156;
    SDL_SCANCODE_PRIOR = 157;
    SDL_SCANCODE_RETURN2 = 158;
    SDL_SCANCODE_SEPARATOR = 159;
    SDL_SCANCODE_OUT = 160;
    SDL_SCANCODE_OPER = 161;
    SDL_SCANCODE_CLEARAGAIN = 162;
    SDL_SCANCODE_CRSEL = 163;
    SDL_SCANCODE_EXSEL = 164;
    SDL_SCANCODE_KP_00 = 176;
    SDL_SCANCODE_KP_000 = 177;
    SDL_SCANCODE_THOUSANDSSEPARATOR = 178;
    SDL_SCANCODE_DECIMALSEPARATOR = 179;
    SDL_SCANCODE_CURRENCYUNIT = 180;
    SDL_SCANCODE_CURRENCYSUBUNIT = 181;
    SDL_SCANCODE_KP_LEFTPAREN = 182;
    SDL_SCANCODE_KP_RIGHTPAREN = 183;
    SDL_SCANCODE_KP_LEFTBRACE = 184;
    SDL_SCANCODE_KP_RIGHTBRACE = 185;
    SDL_SCANCODE_KP_TAB = 186;
    SDL_SCANCODE_KP_BACKSPACE = 187;
    SDL_SCANCODE_KP_A = 188;
    SDL_SCANCODE_KP_B = 189;
    SDL_SCANCODE_KP_C = 190;
    SDL_SCANCODE_KP_D = 191;
    SDL_SCANCODE_KP_E = 192;
    SDL_SCANCODE_KP_F = 193;
    SDL_SCANCODE_KP_XOR = 194;
    SDL_SCANCODE_KP_POWER = 195;
    SDL_SCANCODE_KP_PERCENT = 196;
    SDL_SCANCODE_KP_LESS = 197;
    SDL_SCANCODE_KP_GREATER = 198;
    SDL_SCANCODE_KP_AMPERSAND = 199;
    SDL_SCANCODE_KP_DBLAMPERSAND = 200;
    SDL_SCANCODE_KP_VERTICALBAR = 201;
    SDL_SCANCODE_KP_DBLVERTICALBAR = 202;
    SDL_SCANCODE_KP_COLON = 203;
    SDL_SCANCODE_KP_HASH = 204;
    SDL_SCANCODE_KP_SPACE = 205;
    SDL_SCANCODE_KP_AT = 206;
    SDL_SCANCODE_KP_EXCLAM = 207;
    SDL_SCANCODE_KP_MEMSTORE = 208;
    SDL_SCANCODE_KP_MEMRECALL = 209;
    SDL_SCANCODE_KP_MEMCLEAR = 210;
    SDL_SCANCODE_KP_MEMADD = 211;
    SDL_SCANCODE_KP_MEMSUBTRACT = 212;
    SDL_SCANCODE_KP_MEMMULTIPLY = 213;
    SDL_SCANCODE_KP_MEMDIVIDE = 214;
    SDL_SCANCODE_KP_PLUSMINUS = 215;
    SDL_SCANCODE_KP_CLEAR = 216;
    SDL_SCANCODE_KP_CLEARENTRY = 217;
    SDL_SCANCODE_KP_BINARY = 218;
    SDL_SCANCODE_KP_OCTAL = 219;
    SDL_SCANCODE_KP_DECIMAL = 220;
    SDL_SCANCODE_KP_HEXADECIMAL = 221;
    SDL_SCANCODE_LCTRL = 224;
    SDL_SCANCODE_LSHIFT = 225;
    SDL_SCANCODE_LALT = 226;
    SDL_SCANCODE_LGUI = 227;
    SDL_SCANCODE_RCTRL = 228;
    SDL_SCANCODE_RSHIFT = 229;
    SDL_SCANCODE_RALT = 230;
    SDL_SCANCODE_RGUI = 231;
    SDL_SCANCODE_MODE = 257;
    SDL_SCANCODE_AUDIONEXT = 258;
    SDL_SCANCODE_AUDIOPREV = 259;
    SDL_SCANCODE_AUDIOSTOP = 260;
    SDL_SCANCODE_AUDIOPLAY = 261;
    SDL_SCANCODE_AUDIOMUTE = 262;
    SDL_SCANCODE_MEDIASELECT = 263;
    SDL_SCANCODE_WWW = 264;
    SDL_SCANCODE_MAIL = 265;
    SDL_SCANCODE_CALCULATOR = 266;
    SDL_SCANCODE_COMPUTER = 267;
    SDL_SCANCODE_AC_SEARCH = 268;
    SDL_SCANCODE_AC_HOME = 269;
    SDL_SCANCODE_AC_BACK = 270;
    SDL_SCANCODE_AC_FORWARD = 271;
    SDL_SCANCODE_AC_STOP = 272;
    SDL_SCANCODE_AC_REFRESH = 273;
    SDL_SCANCODE_AC_BOOKMARKS = 274;
    SDL_SCANCODE_BRIGHTNESSDOWN = 275;
    SDL_SCANCODE_BRIGHTNESSUP = 276;
    SDL_SCANCODE_DISPLAYSWITCH = 277;
    SDL_SCANCODE_KBDILLUMTOGGLE = 278;
    SDL_SCANCODE_KBDILLUMDOWN = 279;
    SDL_SCANCODE_KBDILLUMUP = 280;
    SDL_SCANCODE_EJECT = 281;
    SDL_SCANCODE_SLEEP = 282;
    SDL_SCANCODE_APP1 = 283;
    SDL_SCANCODE_APP2 = 284;

/////////////////////////////////////////////////////////////////
///////////////////////  TYPE DEFINITIONS ///////////////////////
/////////////////////////////////////////////////////////////////

// two important reference points for the wanderers of this area
// http://www.freepascal.org/docs-html/ref/refsu5.html
// http://www.freepascal.org/docs-html/prog/progsu144.html

type
    PSDL_Window   = Pointer;
    PSDL_Renderer = Pointer;
    PSDL_Texture  = Pointer;
    PSDL_GLContext= Pointer;
    TSDL_TouchId  = Int64;
    TSDL_FingerId = Int64;
    TSDL_Keycode = LongInt;
    TSDL_Scancode = LongInt;

    TSDL_eventaction = (SDL_ADDEVENT, SDL_PEEPEVENT, SDL_GETEVENT);

    PSDL_Rect = ^TSDL_Rect;
    TSDL_Rect = record
        x, y, w, h: LongInt;
        end;

    TPoint = record
        x, y: LongInt;
        end;

    PSDL_PixelFormat = ^TSDL_PixelFormat;
    TSDL_PixelFormat = record
        format: LongWord;
        palette: Pointer;
        BitsPerPixel : Byte;
        BytesPerPixel: Byte;
        padding: array[0..1] of Byte;
        RMask : LongWord;
        GMask : LongWord;
        BMask : LongWord;
        AMask : LongWord;
        Rloss : Byte;
        Gloss : Byte;
        Bloss : Byte;
        Aloss : Byte;
        Rshift: Byte;
        Gshift: Byte;
        Bshift: Byte;
        Ashift: Byte;
        refcount: LongInt;
        next: PSDL_PixelFormat;
        end;

    PSDL_Surface = ^TSDL_Surface;
    TSDL_Surface = record
        flags : LongWord;
        format: PSDL_PixelFormat;
        w, h  : LongInt;
        pitch : LongInt;
        pixels: Pointer;
{$IFDEF PAS2C}
        hwdata   : Pointer;
        clip_rect: TSDL_Rect;
        unsed1   : LongWord;
        locked   : LongWord;
        map      : Pointer;
        format_version: Longword;
        refcount : LongInt;
        offset   : LongInt;
{$ELSE}
        userdata  : Pointer;
        locked    : LongInt;
        lock_data : Pointer;
        clip_rect : TSDL_Rect;
        map       : Pointer;
        refcount  : LongInt;
{$ENDIF}
        end;


    PSDL_Color = ^TSDL_Color;
    TSDL_Color = record
            r: Byte;
            g: Byte;
            b: Byte;
            a: Byte; //sdl12 name is 'unused' but as long as size matches...
        end;


    (* SDL_RWops and friends *)
    PSDL_RWops = ^TSDL_RWops;
    TSize  = function( context: PSDL_RWops): Int64; cdecl;
    TSeek  = function( context: PSDL_RWops; offset: Int64; whence: LongInt ): Int64; cdecl;
    TRead  = function( context: PSDL_RWops; Ptr: Pointer; size: LongInt; maxnum : LongInt ): LongInt;  cdecl;
    TWrite = function( context: PSDL_RWops; Ptr: Pointer; size: LongInt; num: LongInt ): LongInt; cdecl;
    TClose = function( context: PSDL_RWops ): LongInt; cdecl;

    TStdio = record
        autoclose: Boolean;
        fp: Pointer;
        end;

    TMem = record
        base: PByte;
        here: PByte;
        stop: PByte;
        end;

    TUnknown = record
        data1: Pointer;
        data2: Pointer;
        end;

{$IFDEF ANDROID}
    TAndroidio = record
        fileName, inputStream, readableByteChannel: Pointer;
        readMethod, assetFileDescriptor: Pointer;
        position, size, offset: Int64;
        fd: LongInt;
        end;
{$ELSE}
{$IFDEF WIN32}
    TWinbuffer = record
        data: Pointer;
        size, left: LongInt;
        end;
    TWindowsio = record
        append : Boolean;
        h : Pointer;
        buffer : TWinbuffer;
        end;
{$ENDIF}
{$ENDIF}

    TSDL_RWops = record
        size: TSize;
        seek: TSeek;
        read: TRead;
        write: TWrite;
        close: TClose;
        type_: LongWord;
        case Byte of
{$IFDEF ANDROID}
            0: (androidio: TAndroidio);
{$ELSE}
{$IFDEF WIN32}
            0: (windowsio: TWindowsio);
{$ENDIF}
{$ENDIF}
            1: (stdio: TStdio);     // assumes HAVE_STDIO_H
            2: (mem: TMem);
            3: (unknown: TUnknown);
            end;


{* SDL_Event type definition *}

    TSDL_Keysym = record
        scancode: TSDL_Scancode;
        sym: TSDL_Keycode;
        modifier: Word;
        unused: LongWord;
        end;

    TSDL_WindowEvent = record
        type_: LongWord;
        timestamp: LongWord;
        windowID: LongWord;
        event: Byte;
        padding1, padding2, padding3: Byte;
        data1, data2: LongInt;
        end;

    TSDL_TextEditingEvent = record
        type_: Longword;
        timestamp: Longword;
        windowID: Longword;
        text: array [0..SDL_TEXTEDITINGEVENT_TEXT_SIZE - 1] of char;
        start: LongInt;
        length: LongInt;
        end;

    TSDL_TextInputEvent = record
        type_: Longword;
        timestamp: Longword;
        windowID: Longword;
        text: array [0..SDL_TEXTINPUTEVENT_TEXT_SIZE - 1] of char;
        end;

    TSDL_TouchFingerEvent = record
        type_: LongWord;
        timestamp: LongWord;
        touchId: TSDL_TouchId;
        fingerId: TSDL_FingerId;
        x, y, dx, dy: Single;
        pressure: Single;
        end;

    TSDL_MultiGestureEvent = record
        type_: LongWord;
        timestamp: LongWord;
        touchId: TSDL_TouchId;
        dTheta, dDist, x, y: Single;
        numFingers, padding: Word;
        end;

    TSDL_DollarGestureEvent = record
        type_: LongWord;
        timestamp: LongWord;
        touchId: Int64;
        gesturedId: Int64;
        numFingers: LongWord;
        error, x, y: Single;
        end;

    TSDL_DropEvent = record
        type_: LongWord;
        timestamp: LongWord;
        filename: PChar;
        end;

    TSDL_SysWMEvent = record
        type_: LongWord;
        timestamp: LongWord;
        msg: Pointer;
        end;

    TSDL_ControllerAxisEvent = record
        type_: LongWord;
        timestamp: LongWord;
        which: LongInt;
        axis, padding1, padding2, padding3: Byte;
        value: SmallInt;
        padding4: Word;
        end;

    TSDL_ControllerButtonEvent = record
        type_: LongWord;
        timestamp: LongWord;
        which: LongInt;
        button, states, padding1, padding2: Byte;
        end;

    TSDL_ControllerDeviceEvent = record
        type_: LongWord;
        timestamp: LongWord;
        which: SmallInt;
        end;

    TSDL_JoyDeviceEvent = TSDL_ControllerDeviceEvent;

    TSDL_CommonEvent = record
        type_: LongWord;
        timestamp: LongWord;
        end;

    TSDL_OSEvent = TSDL_CommonEvent;

    TSDL_KeyboardEvent = record
        type_: LongWord;
        timestamp: LongWord;
        windowID: LongWord;
        state, repeat_, padding2, padding3: Byte;
        keysym: TSDL_Keysym;
        end;

    TSDL_MouseMotionEvent = record
        type_: LongWord;
        timestamp: LongWord;
        windowID: LongWord;
        which, state: LongWord;
        x, y, xrel, yrel: LongInt;
        end;

    TSDL_MouseButtonEvent = record
        type_: LongWord;
        timestamp: LongWord;
        windowID: LongWord;
        which: LongWord;
        button, state, padding1, padding2: Byte;
        x, y: LongInt;
        end;

    TSDL_MouseWheelEvent = record
        type_: LongWord;
        timestamp: LongWord;
        windowID: LongWord;
        which: LongWord;
        x, y: LongInt;
        end;

    TSDL_JoyAxisEvent = record
        type_: LongWord;
        timestamp: LongWord;
        which: LongWord;
        axis: Byte;
        padding1, padding2, padding3: Byte;
        value: LongInt;
        padding4: Word;
        end;

    TSDL_JoyBallEvent = record
        type_: LongWord;
        timestamp: LongWord;
        which: LongWord;
        ball: Byte;
        padding1, padding2, padding3: Byte;
        xrel, yrel: SmallInt;
        end;

    TSDL_JoyHatEvent = record
        type_: LongWord;
        timestamp: LongWord;
        which: LongWord;
        hat: Byte;
        value: Byte;
        padding1, padding2: Byte;
        end;

    TSDL_JoyButtonEvent = record
        type_: LongWord;
        timestamp: LongWord;
        which: Byte;
        button: Byte;
        state: Byte;
        padding1: Byte;
        end;

    TSDL_QuitEvent = record
        type_: LongWord;
        timestamp: LongWord;
        end;

    TSDL_UserEvent = record
        type_: LongWord;
        timestamp: LongWord;
        windowID: LongWord;
        code: LongInt;
        data1, data2: Pointer;
        end;

    PSDL_Event = ^TSDL_Event;
    TSDL_Event = record
        case LongInt of
            SDL_FIRSTEVENT: (type_: LongWord);
            SDL_COMMONDEVENT: (common: TSDL_CommonEvent);
            SDL_WINDOWEVENT: (window: TSDL_WindowEvent);
            SDL_KEYDOWN,
            SDL_KEYUP: (key: TSDL_KeyboardEvent);
            SDL_TEXTEDITING: (edit: TSDL_TextEditingEvent);
            SDL_TEXTINPUT: (text: TSDL_TextInputEvent);
            SDL_MOUSEMOTION: (motion: TSDL_MouseMotionEvent);
            SDL_MOUSEBUTTONDOWN,
            SDL_MOUSEBUTTONUP: (button: TSDL_MouseButtonEvent);
            SDL_MOUSEWHEEL: (wheel: TSDL_MouseWheelEvent);
            SDL_JOYAXISMOTION: (jaxis: TSDL_JoyAxisEvent);
            SDL_JOYBALLMOTION: (jball: TSDL_JoyBallEvent);
            SDL_JOYHATMOTION: (jhat: TSDL_JoyHatEvent);
            SDL_JOYBUTTONDOWN,
            SDL_JOYBUTTONUP: (jbutton: TSDL_JoyButtonEvent);
            SDL_JOYDEVICEADDED,
            SDL_JOYDEVICEREMOVED: (jdevice: TSDL_JoyDeviceEvent);
            SDL_CONTROLLERAXISMOTION: (caxis: TSDL_ControllerAxisEvent);
            SDL_CONTROLLERBUTTONUP,
            SDL_CONTROLLERBUTTONDOWN: (cbutton: TSDL_ControllerButtonEvent);
            SDL_CONTROLLERDEVICEADDED,
            SDL_CONTROLLERDEVICEREMAPPED,
            SDL_CONTROLLERDEVICEREMOVED: (cdevice: TSDL_ControllerDeviceEvent);
            SDL_QUITEV: (quit: TSDL_QuitEvent);
            SDL_USEREVENT: (user: TSDL_UserEvent);
            SDL_SYSWMEVENT: (syswm: TSDL_SysWMEvent);
            SDL_FINGERDOWN,
            SDL_FINGERUP,
            SDL_FINGERMOTION: (tfinger: TSDL_TouchFingerEvent);
            SDL_MULTIGESTURE: (mgesture: TSDL_MultiGestureEvent);
            SDL_DOLLARGESTURE: (dgesture: TSDL_DollarGestureEvent);
            SDL_DROPFILE: (drop: TSDL_DropEvent);
            SDL_ALLEVENTS: (foo: shortstring);
        end;

    TSDL_EventFilter = function( event : PSDL_Event ): Integer; cdecl;

    TByteArray = array[0..65535] of Byte;
    PByteArray = ^TByteArray;

    TLongWordArray = array[0..16383] of LongWord;
    PLongWordArray = ^TLongWordArray;

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
        SDL_GL_RETAINED_BACKING,
        SDL_GL_CONTEXT_MAJOR_VERSION,
        SDL_GL_CONTEXT_MINOR_VERSION,
        SDL_GL_CONTEXT_EGL,
        SDL_GL_CONTEXT_FLAGS,
        SDL_GL_CONTEXT_PROFILE_MASK,
        SDL_GL_SHARE_WITH_CURRENT_CONTEXT
        );

    TSDL_ArrayByteOrder = (  // array component order, low Byte -> high Byte
        SDL_ARRAYORDER_NONE,
        SDL_ARRAYORDER_RGB,
        SDL_ARRAYORDER_RGBA,
        SDL_ARRAYORDER_ARGB,
        SDL_ARRAYORDER_BGR,
        SDL_ARRAYORDER_BGRA,
        SDL_ARRAYORDER_ABGR
        );

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
        allocated: LongWord;
        abuf     : PByte;
        alen     : LongWord;
        volume   : PByte;
        end;
    TMusic = (MUS_CMD, MUS_WAV, MUS_MOD, MUS_MID, MUS_OGG, MUS_MP3);
    TMix_Fading = (MIX_NO_FADING, MIX_FADING_OUT, MIX_FADING_IN);

    TMidiSong = record
                samples : LongInt;
                events  : Pointer;
                end;

    TMusicUnion = record
        case Byte of
            0: ( midi : TMidiSong );
            1: ( ogg  : Pointer);
            end;

    PMixMusic = ^TMixMusic;
    TMixMusic = record
                end;

    TPostMix = procedure(udata: Pointer; stream: PByte; len: LongInt); cdecl;

    {* SDL_net *}
    TIPAddress = record
                host: LongWord;
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

{$IFDEF WIN32}
     TThreadFunction = function (p: pointer): Longword; stdcall;
     pfnSDL_CurrentBeginThread = function (
        _Security: pointer; 
        _StackSize: LongWord;
        _StartAddress: TThreadFunction;
        _ArgList: pointer;
        _InitFlag: Longword;
        _ThrdAddr: PLongword): PtrUInt; cdecl;
    pfnSDL_CurrentEndThread = procedure (_Retval: LongInt); cdecl;
{$ENDIF} 

/////////////////////////////////////////////////////////////////
/////////////////////  FUNCTION DEFINITIONS /////////////////////
/////////////////////////////////////////////////////////////////


{* SDL *}
function  SDL_Init(flags: LongWord): LongInt; cdecl; external SDLLibName;
function  SDL_InitSubSystem(flags: LongWord): LongInt; cdecl; external SDLLibName;
procedure SDL_Quit; cdecl; external SDLLibName;

procedure SDL_free(mem: Pointer); cdecl; external SDLLibName;

procedure SDL_Delay(msec: LongWord); cdecl; external SDLLibName;
function  SDL_GetTicks: LongWord; cdecl; external SDLLibName;

function  SDL_MustLock(Surface: PSDL_Surface): Boolean;
function  SDL_LockSurface(Surface: PSDL_Surface): LongInt; cdecl; external SDLLibName;
procedure SDL_UnlockSurface(Surface: PSDL_Surface); cdecl; external SDLLibName;

function  SDL_GetError: PChar; cdecl; external SDLLibName;

function  SDL_CreateRGBSurface(flags: LongWord; Width, Height, Depth: LongInt; RMask, GMask, BMask, AMask: LongWord): PSDL_Surface; cdecl; external SDLLibName;
function  SDL_CreateRGBSurfaceFrom(pixels: Pointer; width, height, depth, pitch: LongInt; RMask, GMask, BMask, AMask: LongWord): PSDL_Surface; cdecl; external SDLLibName;
procedure SDL_FreeSurface(Surface: PSDL_Surface); cdecl; external SDLLibName;
function  SDL_SetColorKey(surface: PSDL_Surface; flag, key: LongWord): LongInt; cdecl; external SDLLibName;
function  SDL_SetAlpha(surface: PSDL_Surface; flag, key: LongWord): LongInt; cdecl; external SDLLibName;
function  SDL_ConvertSurface(src: PSDL_Surface; fmt: PSDL_PixelFormat; flags: LongWord): PSDL_Surface; cdecl; external SDLLibName;

function  SDL_UpperBlit(src: PSDL_Surface; srcrect: PSDL_Rect; dst: PSDL_Surface; dstrect: PSDL_Rect): LongInt; cdecl; external SDLLibName;
function  SDL_FillRect(dst: PSDL_Surface; dstrect: PSDL_Rect; color: LongWord): LongInt; cdecl; external SDLLibName;
procedure SDL_UpdateRect(Screen: PSDL_Surface; x, y: LongInt; w, h: LongWord); cdecl; external SDLLibName;
function  SDL_Flip(Screen: PSDL_Surface): LongInt; cdecl; external SDLLibName;

procedure SDL_GetRGB(pixel: LongWord; fmt: PSDL_PixelFormat; r, g, b: PByte); cdecl; external SDLLibName;
procedure SDL_GetRGBA(pixel: LongWord; fmt: PSDL_PixelFormat; r, g, b, a: PByte); cdecl; external SDLLibName;
function  SDL_MapRGB(format: PSDL_PixelFormat; r, g, b: Byte): LongWord; cdecl; external SDLLibName;
function  SDL_MapRGBA(format: PSDL_PixelFormat; r, g, b, a: Byte): LongWord; cdecl; external SDLLibName;

function  SDL_DisplayFormat(Surface: PSDL_Surface): PSDL_Surface; cdecl; external SDLLibName;
function  SDL_DisplayFormatAlpha(Surface: PSDL_Surface): PSDL_Surface; cdecl; external SDLLibName;

function  SDL_RWFromFile(filename, mode: PChar): PSDL_RWops; cdecl; external SDLLibName;
function  SDL_SaveBMP_RW(surface: PSDL_Surface; dst: PSDL_RWops; freedst: LongInt): LongInt; cdecl; external SDLLibName;

function  SDL_CreateWindow(title: PChar; x,y,w,h: LongInt; flags: LongWord): PSDL_Window; cdecl; external SDLLibName;
procedure SDL_SetWindowIcon(window: PSDL_Window; icon: PSDL_Surface); cdecl; external SDLLibName;

function  SDL_CreateRenderer(window: PSDL_Window; index: LongInt; flags: LongWord): PSDL_Renderer; cdecl; external SDLLibName;
function  SDL_DestroyWindow(window: PSDL_Window): LongInt; cdecl; external SDLLibName;
function  SDL_DestroyRenderer(renderer: PSDL_Renderer): LongInt; cdecl; external SDLLibName;
procedure SDL_SetWindowPosition(window: PSDL_Window; w, h: LongInt); cdecl; external SDLLibName;
procedure SDL_SetWindowSize(window: PSDL_Window; w, h: LongInt); cdecl; external SDLLibName;
procedure SDL_SetWindowFullscreen(window: PSDL_Window; flags: LongWord); cdecl; external SDLLibName;
function  SDL_GetCurrentVideoDriver:Pchar; cdecl; external SDLLibName;

function  SDL_GL_CreateContext(window: PSDL_Window): PSDL_GLContext; cdecl; external SDLLibName;
procedure SDL_GL_DeleteContext(context: PSDL_GLContext); cdecl; external SDLLibName;
procedure SDL_GL_SwapWindow(window: PSDL_Window); cdecl; external SDLLibName;
function  SDL_GL_SetSwapInterval(interval: LongInt): LongInt; cdecl; external SDLLibName;

procedure SDL_VideoQuit; cdecl; external SDLLibName;
function  SDL_GetNumVideoDisplays: LongInt; cdecl; external SDLLibName;
procedure SDL_ShowWindow(window: PSDL_Window); cdecl; external SDLLibName;

function  SDL_SetRenderDrawColor(renderer: PSDL_Renderer; r,g,b,a: Byte): LongInt; cdecl; external SDLLibName;
function  SDL_GetRenderer(window: PSDL_Window): PSDL_Renderer; cdecl; external SDLLibName;
function  SDL_RenderFillRect(renderer: PSDL_Renderer; rect: PSDL_Rect): LongInt; cdecl; external SDLLibName;
function  SDL_RenderClear(renderer: PSDL_Renderer): LongInt; cdecl; external SDLLibName;
procedure SDL_RenderPresent(renderer: PSDL_Renderer); cdecl; external SDLLibName;
function  SDL_RenderReadPixels(renderer: PSDL_Renderer; rect: PSDL_Rect; format: LongInt; pixels: Pointer; pitch: LongInt): LongInt; cdecl; external SDLLibName;
function  SDL_RenderSetViewport(window: PSDL_Window; rect: PSDL_Rect): LongInt; cdecl; external SDLLibName;

function  SDL_GetRelativeMouseState(x, y: PLongInt): Byte; cdecl; external SDLLibName;
function  SDL_PixelFormatEnumToMasks(format: TSDL_ArrayByteOrder; bpp: PLongInt; Rmask, Gmask, Bmask, Amask: PLongInt): Boolean; cdecl; external SDLLibName;

procedure SDL_WarpMouseInWindow(window: PSDL_Window; x, y: LongInt); cdecl; external SDLLibName;
function  SDL_SetHint(name, value: PChar): Boolean; cdecl; external SDLLibName;
procedure SDL_StartTextInput; cdecl; external SDLLibName;
procedure SDL_StopTextInput; cdecl; external SDLLibName;

function  SDL_PeepEvents(event: PSDL_Event; numevents: LongInt; action: TSDL_eventaction; minType, maxType: LongWord): LongInt; cdecl; external SDLLibName;

function  SDL_AllocFormat(format: LongWord): PSDL_PixelFormat; cdecl; external SDLLibName;
procedure SDL_FreeFormat(pixelformat: PSDL_PixelFormat); cdecl; external SDLLibName;


function  SDL_GetMouseState(x, y: PLongInt): Byte; cdecl; external SDLLibName;
function  SDL_GetKeyName(key: TSDL_Keycode): PChar; cdecl; external SDLLibName;
function  SDL_GetScancodeName(key: TSDL_Scancode): PChar; cdecl; external SDLLibName;
function  SDL_GetKeyFromScancode(key: TSDL_Scancode): TSDL_Keycode; cdecl; external SDLLibName;
// SDL2 functions has some additional functions (not listed here) for keycode/scancode translation

procedure SDL_PumpEvents; cdecl; external SDLLibName;
function  SDL_PollEvent(event: PSDL_Event): LongInt; cdecl; external SDLLibName;
function  SDL_WaitEvent(event: PSDL_Event): LongInt; cdecl; external SDLLibName;
procedure SDL_SetEventFilter(filter: TSDL_EventFilter); cdecl; external SDLLibName;

function  SDL_ShowCursor(toggle: LongInt): LongInt; cdecl; external SDLLibName;
procedure SDL_WarpMouse(x, y: Word); inline;

function  SDL_GetKeyboardState(numkeys: PLongInt): PByteArray; cdecl; external SDLLibName;

procedure SDL_WM_SetIcon(icon: PSDL_Surface; mask : Byte); cdecl; external SDLLibName;
procedure SDL_WM_SetCaption(title: PChar; icon: PChar); cdecl; external SDLLibName;
function  SDL_WM_ToggleFullScreen(surface: PSDL_Surface): LongInt; cdecl; external SDLLibName;


(* remember to mark the threaded functions as 'cdecl; export;'
   (or have fun debugging nil arguments) *)
{$IFDEF WIN32}
// SDL uses wrapper in windows
function  SDL_CreateThread(fn: Pointer; name: PChar; data: Pointer; bt: pfnSDL_CurrentBeginThread; et: pfnSDL_CurrentEndThread): PSDL_Thread; cdecl; external SDLLibName;
function  SDL_CreateThread(fn: Pointer; name: PChar; data: Pointer): PSDL_Thread; cdecl; overload;
{$ELSE}
function  SDL_CreateThread(fn: Pointer; name: PChar; data: Pointer): PSDL_Thread; cdecl; external SDLLibName;
{$ENDIF}
procedure SDL_WaitThread(thread: PSDL_Thread; status: PLongInt); cdecl; external SDLLibName;
procedure SDL_KillThread(thread: PSDL_Thread); cdecl; external SDLLibName;

function  SDL_CreateMutex: PSDL_mutex; cdecl; external SDLLibName;
procedure SDL_DestroyMutex(mutex: PSDL_mutex); cdecl; external SDLLibName;
function  SDL_LockMutex(mutex: PSDL_mutex): LongInt; cdecl; external SDLLibName;
function  SDL_UnlockMutex(mutex: PSDL_mutex): LongInt; cdecl; external SDLLibName;

function  SDL_GL_SetAttribute(attr: TSDL_GLattr; value: LongInt): LongInt; cdecl; external SDLLibName;
procedure SDL_GL_SwapBuffers; cdecl; external SDLLibName;

procedure SDL_LockAudio; cdecl; external SDLLibName;
procedure SDL_UnlockAudio; cdecl; external SDLLibName;

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

{$IFDEF WIN32}
function SDL_putenv(const text: PChar): LongInt; cdecl; external SDLLibName;
function SDL_getenv(const text: PChar): PChar; cdecl; external SDLLibName;
{$ENDIF}


(*  SDL_ttf  *)
function  TTF_Init: LongInt; cdecl; external SDL_TTFLibName;
procedure TTF_Quit; cdecl; external SDL_TTFLibName;

function  TTF_SizeUTF8(font: PTTF_Font; const text: PChar; w, h: PLongInt): LongInt; cdecl; external SDL_TTFLibName;

function  TTF_RenderUTF8_Solid(font: PTTF_Font; const text: PChar; fg: TSDL_Color): PSDL_Surface; cdecl; external SDL_TTFLibName;
function  TTF_RenderUTF8_Blended(font: PTTF_Font; const text: PChar; fg: TSDL_Color): PSDL_Surface; cdecl; external SDL_TTFLibName;
function  TTF_RenderUTF8_Shaded(font: PTTF_Font; const text: PChar; fg, bg: TSDL_Color): PSDL_Surface; cdecl; external SDL_TTFLibName;

function  TTF_OpenFontRW(src: PSDL_RWops; freesrc: LongBool; size: LongInt): PTTF_Font; cdecl; external SDL_TTFLibName;
procedure TTF_SetFontStyle(font: PTTF_Font; style: LongInt); cdecl; external SDL_TTFLibName;
procedure TTF_CloseFont(font: PTTF_Font); cdecl; external SDL_TTFLibName;

(*  SDL_mixer  *)
function  Mix_Init(flags: LongInt): LongInt; cdecl; external SDL_MixerLibName;
procedure Mix_Quit; cdecl; external SDL_MixerLibName;

function  Mix_OpenAudio(frequency: LongInt; format: Word; channels: LongInt; chunksize: LongInt): LongInt; cdecl; external SDL_MixerLibName;
procedure Mix_CloseAudio; cdecl; external SDL_MixerLibName;
function  Mix_QuerySpec(frequency: PLongInt; format: PWord; channels: PLongInt): LongInt; cdecl; external SDL_MixerLibName;

function  Mix_Volume(channel: LongInt; volume: LongInt): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_SetDistance(channel: LongInt; distance: Byte): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_VolumeMusic(volume: LongInt): LongInt; cdecl; external SDL_MixerLibName;

function  Mix_AllocateChannels(numchans: LongInt): LongInt; cdecl; external SDL_MixerLibName;
procedure Mix_FreeChunk(chunk: PMixChunk); cdecl; external SDL_MixerLibName;
procedure Mix_FreeMusic(music: PMixMusic); cdecl; external SDL_MixerLibName;

function  Mix_LoadWAV_RW(src: PSDL_RWops; freesrc: LongInt): PMixChunk; cdecl; external SDL_MixerLibName;
function  Mix_LoadMUS_RW(src: PSDL_RWops): PMixMusic; cdecl; external SDL_MixerLibName;

function  Mix_Playing(channel: LongInt): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_PlayingMusic: LongInt; cdecl; external SDL_MixerLibName;
function  Mix_FadeInMusic(music: PMixMusic; loops: LongInt; ms: LongInt): LongInt; cdecl; external SDL_MixerLibName;

function  Mix_PlayChannelTimed(channel: LongInt; chunk: PMixChunk; loops: LongInt; ticks: LongInt): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_PlayMusic(music: PMixMusic; loops: LongInt): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_PausedMusic(music: PMixMusic): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_PauseMusic(music: PMixMusic): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_ResumeMusic(music: PMixMusic): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_HaltChannel(channel: LongInt): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_HaltMusic: LongInt; cdecl; external SDL_MixerLibName;

function  Mix_FadeInChannelTimed(channel: LongInt; chunk: PMixChunk; loops: LongInt; fadems: LongInt; ticks: LongInt): LongInt; cdecl; external SDL_MixerLibName;
function  Mix_FadeOutChannel(channel: LongInt; fadems: LongInt): LongInt; cdecl; external SDL_MixerLibName;

procedure Mix_SetPostMix( mix_func: TPostMix; arg: Pointer); cdecl; external SDL_MixerLibName;

(*  SDL_image  *)
function  IMG_Init(flags: LongInt): LongInt; cdecl; external SDL_ImageLibName;
procedure IMG_Quit; cdecl; external SDL_ImageLibName;

function  IMG_Load(const _file: PChar): PSDL_Surface; cdecl; external SDL_ImageLibName;
function  IMG_Load_RW(rwop: PSDL_RWops; freesrc: LongBool): PSDL_Surface; cdecl; external SDL_ImageLibName;
function  IMG_LoadPNG_RW(rwop: PSDL_RWops): PSDL_Surface; cdecl; external SDL_ImageLibName;
function  IMG_LoadTyped_RW(rwop: PSDL_RWops; freesrc: LongBool; type_: PChar): PSDL_Surface; cdecl; external SDL_ImageLibName;

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

// SDL 2 clipboard functions
function SDL_HasClipboardText(): Boolean; cdecl; external SDLLibName;
// returns nil if memory for clipboard contents copy couldn't be allocated
function SDL_GetClipboardText(): PChar; cdecl; external SDLLibName;
// returns 0 on success or negative error number on failure
function SDL_SetClipboardText(const text: PChar): LongInt; cdecl; external SDLLibName;

procedure SDLNet_Write16(value: Word; buf: Pointer);
procedure SDLNet_Write32(value: LongWord; buf: Pointer);
function  SDLNet_Read16(buf: Pointer): Word;
function  SDLNet_Read32(buf: Pointer): LongWord;

implementation
uses uStore;

// for sdl1.2 we directly call SDL_WarpMouse()
// for sdl2 we provide a SDL_WarpMouse() which calls the right SDL_WarpMouseInWindow() function
// this has the advantage of reducing 'uses' and 'ifdef' statements
// (SDLwindow is a private member of uStore module)
procedure SDL_WarpMouse(x, y: Word); inline;
begin
    WarpMouse(x, y);
end;

function SDL_MustLock(Surface: PSDL_Surface): Boolean;
begin
    SDL_MustLock:=
        ((surface^.flags and SDL_RLEACCEL) <> 0)
end;

procedure SDLNet_Write16(value: Word; buf: Pointer);
begin
    PByteArray(buf)^[1]:= value;
    PByteArray(buf)^[0]:= value shr 8
end;

procedure SDLNet_Write32(value: LongWord; buf: Pointer);
begin
    PByteArray(buf)^[3]:= value;
    PByteArray(buf)^[2]:= value shr  8;
    PByteArray(buf)^[1]:= value shr 16;
    PByteArray(buf)^[0]:= value shr 24
end;

function SDLNet_Read16(buf: Pointer): Word;
begin
    SDLNet_Read16:= PByteArray(buf)^[1] or
                 (PByteArray(buf)^[0] shl 8)
end;

function SDLNet_Read32(buf: Pointer): LongWord;
begin
    SDLNet_Read32:=  PByteArray(buf)^[3] or
                  (PByteArray(buf)^[2] shl  8) or
                  (PByteArray(buf)^[1] shl 16) or
                  (PByteArray(buf)^[0] shl 24)
end;

{$IFDEF WIN32}
function  SDL_CreateThread(fn: Pointer; name: PChar; data: Pointer): PSDL_Thread; cdecl;
begin
    SDL_CreateThread:= SDL_CreateThread(fn, name, data, nil, nil)
end;  
{$ENDIF}

end.

