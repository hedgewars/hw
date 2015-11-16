#ifndef _FPCRTL_H_
#define _FPCRTL_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <math.h>

#include "SysUtils.h"
#include "system.h"
#include "misc.h"
#include "fileio.h"
#include "pmath.h"

#ifndef EMSCRIPTEN
#include "GL/glew.h"
#endif

#define fpcrtl_memcpy                       memcpy

#define luapas_lua_gettop                   lua_gettop
#define luapas_lua_close                    lua_close
#define luapas_lua_createtable              lua_createtable
#define luapas_lua_error                    lua_error
#define luapas_lua_gc                       lua_gc
#define luapas_lua_getfield                 lua_getfield
#define luapas_lua_objlen                   lua_objlen
#define luapas_lua_call                     lua_call
#define luapas_lua_pcall                    lua_pcall
#define luapas_lua_pushboolean              lua_pushboolean
#define luapas_lua_pushcclosure             lua_pushcclosure
#define luapas_lua_pushinteger              lua_pushinteger
#define luapas_lua_pushnil                  lua_pushnil
#define luapas_lua_pushnumber               lua_pushnumber
#define luapas_lua_pushlstring              lua_pushlstring
#define luapas_lua_pushstring               lua_pushstring
#define luapas_lua_pushvalue                lua_pushvalue
#define luapas_lua_rawgeti                  lua_rawgeti
#define luapas_lua_setfield                 lua_setfield
#define luapas_lua_settop                   lua_settop
#define luapas_lua_toboolean                lua_toboolean
#define luapas_lua_tointeger                lua_tointeger
#define luapas_lua_tolstring                lua_tolstring
#define luapas_lua_tonumber                 lua_tonumber
#define luapas_lua_type                     lua_type
#define luapas_lua_typename                 lua_typename
#define luapas_luaL_argerror                luaL_argerror
#define luapas_luaL_checkinteger            luaL_checkinteger
#define luapas_luaL_checklstring            luaL_checklstring
#define luapas_luaL_loadfile                luaL_loadfile
#define luapas_luaL_loadstring              luaL_loadstring
#define luapas_luaL_newstate                luaL_newstate
#define luapas_luaL_optinteger              luaL_optinteger
#define luapas_luaL_optlstring              luaL_optlstring
#define luapas_luaL_prepbuffer              luaL_prepbuffer
#define luapas_luaL_ref                     luaL_ref
#define luapas_luaL_unref                   luaL_unref
#define luapas_luaopen_base                 luaopen_base
#define luapas_luaopen_math                 luaopen_math
#define luapas_luaopen_string               luaopen_string
#define luapas_luaopen_table                luaopen_table
#define luapas_lua_load                     lua_load

#define sdlh_IMG_Load                       IMG_Load
#define sdlh_IMG_Load_RW                    IMG_Load_RW

#ifndef EMSCRIPTEN
#define sdlh_Mix_AllocateChannels           Mix_AllocateChannels
#define sdlh_Mix_CloseAudio                 Mix_CloseAudio
#define sdlh_Mix_FadeInChannelTimed         Mix_FadeInChannelTimed
#define sdlh_Mix_FadeInMusic                Mix_FadeInMusic
#define sdlh_Mix_FadeOutChannel             Mix_FadeOutChannel
#define sdlh_Mix_FreeChunk                  Mix_FreeChunk
#define sdlh_Mix_FreeMusic                  Mix_FreeMusic
#define sdlh_Mix_HaltChannel                Mix_HaltChannel
#define sdlh_Mix_HaltMusic                  Mix_HaltMusic
#define sdlh_Mix_LoadMUS                    Mix_LoadMUS
#define sdlh_Mix_LoadMUS_RW                 Mix_LoadMUS_RW
#define sdlh_Mix_LoadWAV_RW                 Mix_LoadWAV_RW
#define sdlh_Mix_OpenAudio                  Mix_OpenAudio
#define sdlh_Mix_PauseMusic                 Mix_PauseMusic
#define sdlh_Mix_PlayChannelTimed           Mix_PlayChannelTimed
#define sdlh_Mix_Playing                    Mix_Playing
#define sdlh_Mix_ResumeMusic                Mix_ResumeMusic
#define sdlh_Mix_Volume                     Mix_Volume
#define sdlh_Mix_VolumeMusic                Mix_VolumeMusic
#else
#define sdlh_Mix_AllocateChannels           stub_Mix_AllocateChannels
#define sdlh_Mix_CloseAudio                 stub_Mix_CloseAudio
#define sdlh_Mix_FadeInChannelTimed         stub_Mix_FadeInChannelTimed
#define sdlh_Mix_FadeInMusic                stub_Mix_FadeInMusic
#define sdlh_Mix_FadeOutChannel             stub_Mix_FadeOutChannel
#define sdlh_Mix_FreeChunk                  stub_Mix_FreeChunk
#define sdlh_Mix_FreeMusic                  stub_Mix_FreeMusic
#define sdlh_Mix_HaltChannel                stub_Mix_HaltChannel
#define sdlh_Mix_HaltMusic                  stub_Mix_HaltMusic
#define sdlh_Mix_LoadMUS                    stub_Mix_LoadMUS
#define sdlh_Mix_LoadMUS_RW                 stub_Mix_LoadMUS_RW
#define sdlh_Mix_LoadWAV_RW                 stub_Mix_LoadWAV_RW
#define sdlh_Mix_OpenAudio                  stub_Mix_OpenAudio
#define sdlh_Mix_PauseMusic                 stub_Mix_PauseMusic
#define sdlh_Mix_PlayChannelTimed           stub_Mix_PlayChannelTimed
#define sdlh_Mix_Playing                    stub_Mix_Playing
#define sdlh_Mix_ResumeMusic                stub_Mix_ResumeMusic
#define sdlh_Mix_Volume                     stub_Mix_Volume
#define sdlh_Mix_VolumeMusic                stub_Mix_VolumeMusic
#endif

#define sdlh_SDL_free                       SDL_free
#define sdlh_SDL_ConvertSurface             SDL_ConvertSurface
#define sdlh_SDL_CreateRGBSurface           SDL_CreateRGBSurface
#define sdlh_SDL_CreateThread               SDL_CreateThread
#define sdlh_SDL_Delay                      SDL_Delay
#define sdlh_SDL_EnableKeyRepeat            SDL_EnableKeyRepeat
#define sdlh_SDL_EnableUNICODE              SDL_EnableUNICODE
#define sdlh_SDL_FillRect                   SDL_FillRect
#define sdlh_SDL_FreeSurface                SDL_FreeSurface
#define sdlh_SDL_GetError                   SDL_GetError
#define sdlh_SDL_GetKeyName                 SDL_GetKeyName
#define sdlh_SDL_GetKeyboardState           SDL_GetKeyboardState
#define sdlh_SDL_GetMouseState              SDL_GetMouseState
#define sdlh_SDL_GetRGBA                    SDL_GetRGBA
#define sdlh_SDL_GetTicks                   SDL_GetTicks
#define sdlh_SDL_GL_SetAttribute            SDL_GL_SetAttribute
#define sdlh_SDL_GL_SwapBuffers             SDL_GL_SwapBuffers
#define sdlh_SDL_Init                       SDL_Init
#define sdlh_SDL_InitSubSystem              SDL_InitSubSystem
#define sdlh_SDL_JoystickClose              SDL_JoystickClose
#define sdlh_SDL_JoystickEventState         SDL_JoystickEventState
#define sdlh_SDL_JoystickName               SDL_JoystickName
#define sdlh_SDL_JoystickNumAxes            SDL_JoystickNumAxes
#define sdlh_SDL_JoystickNumButtons         SDL_JoystickNumButtons
#define sdlh_SDL_JoystickNumHats            SDL_JoystickNumHats
#define sdlh_SDL_JoystickOpen               SDL_JoystickOpen
#define sdlh_SDL_LockSurface                SDL_LockSurface
#define sdlh_SDL_MapRGB                     SDL_MapRGB
#define sdlh_SDL_MapRGBA                    SDL_MapRGBA
#define sdlh_SDL_NumJoysticks               SDL_NumJoysticks
#define sdlh_SDL_PeepEvents                 SDL_PeepEvents
#define sdlh_SDL_PumpEvents                 SDL_PumpEvents
#define sdlh_SDL_Quit                       SDL_Quit
#define sdlh_SDL_RWFromFile                 SDL_RWFromFile
#define sdlh_SDL_SetColorKey                SDL_SetColorKey
#define sdlh_SDL_SetVideoMode               SDL_SetVideoMode
#define sdlh_SDL_WaitThread                 SDL_WaitThread
#define sdlh_SDL_CreateMutex                SDL_CreateMutex
#define sdlh_SDL_DestroyMutex               SDL_DestroyMutex
#define sdlh_SDL_LockMutex                  SDL_LockMutex
#define sdlh_SDL_UnlockMutex                SDL_UnlockMutex
#ifndef EMSCRIPTEN
#define sdlh_SDL_ShowCursor                 SDL_ShowCursor
#else
#define sdlh_SDL_ShowCursor                 SDL_ShowCursor_patch
#endif
#define sdlh_SDL_UnlockSurface              SDL_UnlockSurface
#define sdlh_SDL_UpperBlit                  SDL_UpperBlit
#define sdlh_SDL_VideoDriverName            SDL_VideoDriverName
#define sdlh_SDL_WarpMouse                  SDL_WarpMouse
#define sdlh_SDL_WM_SetCaption              SDL_WM_SetCaption
#define sdlh_SDL_WM_SetIcon                 SDL_WM_SetIcon
#define sdlh_SDLNet_AddSocket               SDLNet_AddSocket
#define sdlh_SDLNet_AllocSocketSet          SDLNet_AllocSocketSet
#define sdlh_SDLNet_CheckSockets            SDLNet_CheckSockets
#define sdlh_SDLNet_FreeSocketSet           SDLNet_FreeSocketSet
#define sdlh_SDLNet_Init                    SDLNet_Init
#define sdlh_SDLNet_Quit                    SDLNet_Quit
#define sdlh_SDLNet_ResolveHost             SDLNet_ResolveHost
#define sdlh_SDLNet_TCP_Close               SDLNet_TCP_Close
#define sdlh_SDLNet_TCP_Open                SDLNet_TCP_Open
#define sdlh_SDLNet_TCP_Recv                SDLNet_TCP_Recv
#define sdlh_SDLNet_TCP_Send                SDLNet_TCP_Send
#define sdlh_TTF_Init                       TTF_Init
#define sdlh_TTF_OpenFont                   TTF_OpenFont
#define sdlh_TTF_OpenFontRW                 TTF_OpenFontRW
#define sdlh_TTF_Quit                       TTF_Quit
#define sdlh_TTF_RenderUTF8_Blended         TTF_RenderUTF8_Blended
#define sdlh_TTF_RenderUTF8_Solid           TTF_RenderUTF8_Solid
#define sdlh_TTF_SetFontStyle               TTF_SetFontStyle
#define sdlh_TTF_SizeUTF8                   TTF_SizeUTF8

#define uphysfslayer_physfsReaderSetBuffer  physfsReaderSetBuffer
#define uphysfslayer_physfsReader           physfsReader
#define uphysfslayer_hedgewarsMountPackage  hedgewarsMountPackage
#define uphysfslayer_hedgewarsMountPackages hedgewarsMountPackages

#define uphysfslayer_PHYSFSRWOPS_openRead   PHYSFSRWOPS_openRead
#define uphysfslayer_PHYSFSRWOPS_openWrite  PHYSFSRWOPS_openWrite

#define _strconcat                          fpcrtl_strconcat
#define _strappend                          fpcrtl_strappend
#define _strprepend                         fpcrtl_strprepend
#define _strcompare                         fpcrtl_strcompare
#define _strncompare                        fpcrtl_strncompare
#define _strcomparec                        fpcrtl_strcomparec
#define _chrconcat                          fpcrtl_chrconcat
#define _pchar                              fpcrtl_pchar
#define _strconcatA                         fpcrtl_strconcatA
#define _strncompareA                       fpcrtl_strncompareA
#define _strappendA                         fpcrtl_strappendA

// hooks are implemented in javascript
void start_hook(void);
void mainloop_hook(void);
void clear_filelist_hook(void);
void add_file_hook(const char* ptr);
void idb_loader_hook();
void showcursor_hook();
void hidecursor_hook();
void drawworld_init_hook();
#endif
