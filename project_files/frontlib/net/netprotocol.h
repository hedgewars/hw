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

#ifndef NETPROTOCOL_H_
#define NETPROTOCOL_H_

#include "../model/team.h"
#include "../model/scheme.h"
#include "../model/map.h"
#include "../model/room.h"

#include <stddef.h>

/**
 * Create a new team from this 23-part net message
 */
flib_team *flib_team_from_netmsg(char **parts);

/**
 * Create a new scheme from this net message, which must have
 * meta->modCount+meta->settingCount+1 parts.
 */
flib_scheme *flib_scheme_from_netmsg(char **parts);

/**
 * Create a new map from this five-part netmsg
 */
flib_map *flib_map_from_netmsg(char **parts);

/**
 * Decode the drawn map data from this netmessage line.
 *
 * The data is first base64 decoded and then quncompress()ed.
 * The return value is a newly allocated byte buffer, the length
 * is written to the variable pointed to by outlen.
 * Returns NULL on error.
 */
int flib_drawnmapdata_from_netmsg(char *netmsg, uint8_t **outbuf, size_t *outlen);

/**
 * Create a new room from this 8-part net message
 */
flib_room *flib_room_from_netmsg(char **params);

/**
 * Create an array of count rooms from count*8 netmessage parts
 */
flib_room **flib_room_array_from_netmsg(char **params, int count);

#endif /* NETPROTOCOL_H_ */
