/*
 * OpenAL Bridge - a simple portable library for OpenAL interface
 * Copyright (c) 2009 Vittorio Giovara <vittorio.giovara@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

#include "globals.h"

#ifndef _OALB_LOADERS_H
#define _OALB_LOADERS_H

int load_wavpcm     (const char *filename, ALenum *format, char **data, ALsizei *bitsize, ALsizei *freq);
int load_oggvorbis  (const char *filename, ALenum *format, char **data, ALsizei *bitsize, ALsizei *freq);

#endif /*_OALB_LOADERS_H*/
