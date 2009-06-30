/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2007 Andrey Korotaev <unC0Rr@gmail.com>
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
 */

#include "SDLs.h"

#include "SDL.h"
#include "hwconsts.h"

SDLInteraction::SDLInteraction()
{
	music = -1;

	SDL_Init(SDL_INIT_VIDEO);
	openal_init(5);

}

SDLInteraction::~SDLInteraction()
{
	SDL_Quit();
	openal_close();
}

QStringList SDLInteraction::getResolutions() const
{
	QStringList result;

	SDL_Rect **modes;

	modes = SDL_ListModes(NULL, SDL_FULLSCREEN);

	if((modes == (SDL_Rect **)0) || (modes == (SDL_Rect **)-1))
	{
		result << "640x480";
	} else
	{
		for(int i = 0; modes[i]; ++i)
			if ((modes[i]->w >= 640) && (modes[i]->h >= 480))
				result << QString("%1x%2").arg(modes[i]->w).arg(modes[i]->h);
	}

	return result;
}

void SDLInteraction::StartMusic()
{
	if (music < 0) {
		music = openal_loadfile(QString(datadir->absolutePath() + "/Music/main theme.ogg").toLocal8Bit().constData());
		openal_toggleloop(music);
	}
	openal_setvolume(music, 60);
	openal_fadein(music, 25);
}

void SDLInteraction::StopMusic()
{
	if (music >= 0) openal_fadeout(music, 40);
}
