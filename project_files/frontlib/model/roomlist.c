#include "roomlist.h"

#include "../util/util.h"
#include "../util/list.h"
#include "../util/logging.h"

#include <stdlib.h>
#include <string.h>

flib_roomlist *flib_roomlist_create() {
	return flib_calloc(1, sizeof(flib_roomlist));
}

static void flib_roomlist_room_destroy(flib_roomlist_room *room) {
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
		free(list);
	}
}

static flib_roomlist_room *fillRoomFromParams(char **params) {
	flib_roomlist_room *result = NULL;
	flib_roomlist_room *tmpRoom = flib_calloc(1, sizeof(flib_roomlist_room));
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

int flib_roomlist_add(flib_roomlist *list, char **params) {
	int result = -1;
	if(!list || !params) {
		flib_log_e("null parameter in flib_roomlist_add");
	} else {
		flib_roomlist_room *tmpRoom = fillRoomFromParams(params);
		if(tmpRoom) {
			flib_roomlist_room **rooms = flib_list_insert(list->rooms, &list->roomCount, sizeof(*list->rooms), &tmpRoom, 0);
			if(rooms) {
				list->rooms = rooms;
				tmpRoom = NULL;
				result = 0;
			}
		}
		flib_roomlist_room_destroy(tmpRoom);
	}
	return result;
}

static int findRoom(flib_roomlist *list, const char *name) {
	for(int i=0; i<list->roomCount; i++) {
		if(!strcmp(name, list->rooms[i]->name)) {
			return i;
		}
	}
	return -1;
}

int flib_roomlist_update(flib_roomlist *list, const char *name, char **params) {
	int result = -1;
	if(!list || !name || !params) {
		flib_log_e("null parameter in flib_roomlist_update");
	} else {
		flib_roomlist_room *tmpRoom = fillRoomFromParams(params);
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

flib_roomlist_room *flib_roomlist_find(flib_roomlist *list, const char *name) {
	flib_roomlist_room *result = NULL;
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

int flib_roomlist_delete(flib_roomlist *list, const char *name) {
	int result = -1;
	if(!list || !name) {
		flib_log_e("null parameter in flib_roomlist_delete");
	} else {
		int roomid = findRoom(list, name);
		if(roomid<0) {
			flib_log_w("Attempt to delete unknown room %s", name);
		} else {
			flib_roomlist_room *room = list->rooms[roomid];
			flib_roomlist_room **rooms = flib_list_delete(list->rooms, &list->roomCount, sizeof(*list->rooms), roomid);
			if(rooms || list->roomCount==0) {
				list->rooms = rooms;
				flib_roomlist_room_destroy(room);
				result = 0;
			}
		}
	}
	return result;
}
