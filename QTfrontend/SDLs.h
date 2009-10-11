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

#ifndef SDLS_H
#define SDLS_H

#include <QStringList>

extern "C" bool openal_init		(char *programname, bool usehardware, unsigned int memorysize);
extern "C" bool openal_close		(void);
extern "C" bool openal_ready		(void);
extern "C" int  openal_loadfile		(const char *filename);
extern "C" bool openal_toggleloop	(unsigned int index);
extern "C" bool openal_setvolume	(unsigned int index, unsigned char percentage);
extern "C" bool openal_setglobalvolume	(unsigned char percentage);
extern "C" bool openal_togglemute	(void);
extern "C" bool openal_fadeout		(unsigned int index, unsigned short int quantity);
extern "C" bool openal_fadein		(unsigned int index, unsigned short int quantity);
extern "C" bool openal_fade		(unsigned int index, unsigned short int quantity, bool direction);
extern "C" bool openal_playsound 	(unsigned int index);
extern "C" bool openal_stopsound	(unsigned int index);
extern "C" bool openal_pausesound	(unsigned int index);

class SDLInteraction : public QObject
{
	Q_OBJECT

private:
	int music;

public:
	SDLInteraction(bool);
	~SDLInteraction();
	QStringList getResolutions() const;
	void StartMusic();
	void StopMusic();
};

void OpenAL_Init();

#endif
