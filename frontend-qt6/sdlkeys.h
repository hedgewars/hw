/*
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
 */

#ifndef SDLKEYS_H
#define SDLKEYS_H

extern char sdlkeys[1024][2][128];
extern bool sdlkeys_iskeyboard[1024];
extern char xb360buttons[10][128];
extern char xbox360axes[10][128];
extern char xb360dpad[128];
extern char controlleraxis[128];
extern char controllerbutton[128];
extern char controllerhat[128];
extern char controllerup[128];
extern char controllerdown[128];
extern char controllerleft[128];
extern char controllerright[128];
extern char unboundcontrol[128];

#endif
