/*
 * Hedgewars Xfire integration
 * Copyright (c) 2010 Mario Liebisch <mario.liebisch AT googlemail.com>
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

#ifndef XFIRE_H
#define XFIRE_H

#ifdef _WIN32
// TODO: Move to CMAKE
#define USE_XFIRE
#endif

#ifdef USE_XFIRE
enum XFIRE_KEYS
{
    XFIRE_STATUS = 0,
    XFIRE_NICKNAME,
    XFIRE_SERVER,
    XFIRE_ROOM,
    XFIRE_KEY_COUNT,
};

void xfire_init(void);
void xfire_free(void);
void xfire_setvalue(const XFIRE_KEYS status, const char *value);
void xfire_update(void);
#endif

#endif // XFIRE_H
