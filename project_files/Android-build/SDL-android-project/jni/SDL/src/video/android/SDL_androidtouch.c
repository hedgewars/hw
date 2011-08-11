/*
    SDL - Simple DirectMedia Layer
    Copyright (C) 1997-2011 Sam Lantinga

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

    Sam Lantinga
    slouken@libsdl.org
*/
#include "SDL_config.h"

#include <android/log.h>

#include "SDL_events.h"
#include "../../events/SDL_touch_c.h"

#include "SDL_androidtouch.h"


#define ACTION_DOWN 0
#define ACTION_UP 1
#define ACTION_MOVE 2
#define ACTION_CANCEL 3
#define ACTION_OUTSIDE 4
#define ACTION_POINTER_DOWN 5
#define ACTION_POINTER_UP 6


void Android_OnTouch(int action, int pointerId, float x, float y, float p)
{
    if (!Android_Window) {
        return;
    }

    //The first event will provide the x, y and pressure max values,
    if(!SDL_GetTouch(1)){
        SDL_Touch touch;
        touch.id = 1;
        touch.x_min = 0;
        touch.x_max = x;
        touch.native_xres = touch.x_max - touch.x_min;
        touch.y_min = 0;
        touch.y_max = y;
        touch.native_yres = touch.y_max - touch.y_min;
        touch.pressure_min = 0;
        touch.pressure_max = p;
        touch.native_pressureres = touch.pressure_max - touch.pressure_min;

        if(SDL_AddTouch(&touch, "") < 0) return;
    }


    switch(action){
        case ACTION_DOWN:
        case ACTION_POINTER_DOWN:
            SDL_SetTouchFocus(pointerId, Android_Window);
            SDL_SendFingerDown(1, pointerId, SDL_TRUE, x, y, p);
            break;
        case ACTION_CANCEL:
        case ACTION_POINTER_UP:
        case ACTION_UP:
            SDL_SendFingerDown(1, pointerId, SDL_FALSE, x, y, p);
            break;
        case ACTION_MOVE: 
            SDL_SendTouchMotion(1, pointerId, 0, x, y, p);
            break;
        case ACTION_OUTSIDE:
            break;
    }
}

/* vi: set ts=4 sw=4 expandtab: */
