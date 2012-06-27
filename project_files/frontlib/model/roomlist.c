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

#include "roomlist.h"

#include "../util/util.h"
#include "../util/list.h"
#include "../util/logging.h"

#include <stdlib.h>
#include <string.h>

flib_roomlist *flib_roomlist_create() {
	return flib_calloc(1, sizeof(flib_roomlist));
}

static void flib_roomlist_room_destroy(flib_room *room) {
	if(room) {
		free(room->map);
		free(room->name);
		free(room->owner);
		free(room->scheme);
		free(room->weapons);
		free(room);
	}
}

void flib_roomlist_destroy(flib_roomlist *list) {
	if(list) {
		for(int i=0; i<list->roomCount; i++) {
			flib_roomlist_room_destroy(list->rooms[i]);
		}
		free(list->rooms);
		free(list);
	}
}

static flib_room *fillRoomFromParams(char **params) {
	flib_room *result = NULL;
	flib_room *tmpRoom = flib_calloc(1, sizeof(flib_room));
	if(tmpRoom) {
		tmpRoom->inProgress = !strcmp(params[0], "True");
		tmpRoom->name = flib_strdupnull(params[1]);
		tmpRoom->playerCount = atoi(params[2]);
		tmpRoom->teamCount = atoi(params[3]);
		tmpRoom->owner = flib_strdupnull(params[4]);
		tmpRoom->map = flib_strdupnull(params[5]);
		tmpRoom->scheme = flib_strdupnull(params[6]);
		tmpRoom->weapons = flib_strdupnull(params[7]);
		if(tmpRoom->name && tmpRoom->owner && tmpRoom->map && tmpRoom->scheme && tmpRoom->weapons) {
			result = tmpRoom;
			tmpRoom = NULL;
		}
	}
	flib_roomlist_room_destroy(tmpRoom);
	return result;
}

GENERATE_STATIC_LIST_INSERT(insertRoom, flib_room*)
GENERATE_STATIC_LIST_DELETE(deleteRoom, flib_room*)

static int findRoom(const flib_roomlist *list, const char *name) {
	for(int i=0; i<list->roomCount; i++) {
		if(!strcmp(name, list->rooms[i]->name)) {
			return i;
		}
	}
	return -1;
}

int flib_roomlist_add(flib_roomlist *list, char **params) {
	int result = -1;
	if(!list || !params) {
		flib_log_e("null parameter in flib_roomlist_add");
	} else {
		flib_room *tmpRoom = fillRoomFromParams(params);
		if(tmpRoom) {
			if(!insertRoom(&list->rooms, &list->roomCount, tmpRoom, 0)) {
				tmpRoom = NULL;
				result = 0;
			}
		}
		flib_roomlist_room_destroy(tmpRoom);
	}
	return result;
}

int flib_roomlist_delete(flib_roomlist *list, const char *name) {
	int result = -1;
	if(!list || !name) {
		flib_log_e("null parameter in flib_roomlist_delete");
	} else {
		int roomid = findRoom(list, name);
		if(roomid<0) {
			flib_log_w("Attempt to delete unknown room %s", name);
		} else {
			flib_room *room = list->rooms[roomid];
			if(!deleteRoom(&list->rooms, &list->roomCount, roomid)) {
				flib_roomlist_room_destroy(room);
				result = 0;
			}
		}
	}
	return result;
}

int flib_roomlist_update(flib_roomlist *list, const char *name, char **params) {
	int result = -1;
	if(!list || !name || !params) {
		flib_log_e("null parameter in flib_roomlist_update");
	} else {
		flib_room *tmpRoom = fillRoomFromParams(params);
		int roomid = findRoom(list, name);
		if(tmpRoom && roomid>=0) {
			flib_roomlist_room_destroy(list->rooms[roomid]);
			list->rooms[roomid] = tmpRoom;
			tmpRoom = NULL;
			result = 0;
		}
		flib_roomlist_room_destroy(tmpRoom);
	}
	return result;
}

flib_room *flib_roomlist_find(const flib_roomlist *list, const char *name) {
	flib_room *result = NULL;
	if(!list || !name) {
		flib_log_e("null parameter in flib_roomlist_find");
	} else {
		int roomid = findRoom(list, name);
		if(roomid>=0) {
			result = list->rooms[roomid];
		}
	}
	return result;
}

void flib_roomlist_clear(flib_roomlist *list) {
	if(!list) {
		flib_log_e("null parameter in flib_roomlist_clear");
	} else {
		for(int i=0; i<list->roomCount; i++) {
			flib_roomlist_room_destroy(list->rooms[i]);
		}
		free(list->rooms);
		list->rooms = NULL;
		list->roomCount = 0;
	}
}
