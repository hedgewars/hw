/*
 SDL - Simple DirectMedia Layer
 Copyright (C) 1997-2009 Sam Lantinga
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 
 Sam Lantinga, mods for Hedgewars by Vittorio Giovara
 slouken@libsdl.org, vittorio.giovara@gmail.com
 */

#import "SDL_config.h"
#import "SDL_uikitopenglview.h"
//#import "../SDL_sysvideo.h"

typedef struct SDL_WindowData SDL_WindowData;

extern int UIKit_CreateWindow(_THIS, SDL_Window * window);
extern void UIKit_DestroyWindow(_THIS, SDL_Window * window);

@class UIWindow;

struct SDL_WindowData
{
    SDL_Window *window;
    UIWindow *uiwindow;
    SDL_uikitopenglview *view;
};

/* vi: set ts=4 sw=4 expandtab: */
