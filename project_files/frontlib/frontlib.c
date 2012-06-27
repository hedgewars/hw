/*
 * Hedgewars, a free turn based strategy game
 * Copyright (C) 2012 Simeon Maxein <smaxein@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include "frontlib.h"
#include "util/logging.h"
#include <SDL.h>
#include <SDL_net.h>

static int flib_initflags;

int flib_init(int flags) {
	flib_initflags = flags;

	flib_log_d("Initializing frontlib");
	if(!(flib_initflags | FRONTLIB_SDL_ALREADY_INITIALIZED)) {
		if(SDL_Init(0)==-1) {
		    flib_log_e("Error in SDL_Init: %s", SDL_GetError());
		    return -1;
		}
	}

	if(SDLNet_Init()==-1) {
		flib_log_e("Error in SDLNet_Init: %s", SDLNet_GetError());
		if(!(flib_initflags | FRONTLIB_SDL_ALREADY_INITIALIZED)) {
			SDL_Quit();
		}
		return -1;
	}

	return 0;
}

void flib_quit() {
	flib_log_d("Shutting down frontlib");
	SDLNet_Quit();
	if(!(flib_initflags | FRONTLIB_SDL_ALREADY_INITIALIZED)) {
		SDL_Quit();
	}
}
