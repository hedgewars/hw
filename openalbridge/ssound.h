/*
 * OpenAL Bridge - a simple portable library for OpenAL interface
 * Copyright (c) 2009 Vittorio Giovara <vittorio.giovara@gmail.com>,
 *                    Mario Liebisch <mario.liebisch+hw@googlemail.com>
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

#ifndef _SSOUND_H
#define _SSOUND_H

#include "common.h"

char SSound_load        (SSound_t* pSound, const char* cFilename);
void SSound_close       (SSound_t* pSound);
void SSound_play        (SSound_t* pSound, const char bLoop);
void SSound_pause       (const SSound_t* pSound);
void SSound_continue    (const SSound_t* pSound);
void SSound_stop        (SSound_t* pSound);
void SSound_volume      (const SSound_t* pSound, const float fPercentage);

#endif /*_SSOUND_H*/
