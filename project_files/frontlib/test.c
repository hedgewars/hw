#include "frontlib.h"
#include "util/logging.h"
#include "util/buffer.h"
#include "util/util.h"
#include "util/list.h"
#include "model/map.h"
#include "model/weapon.h"
#include "model/schemelist.h"
#include "ipc/mapconn.h"
#include "ipc/gameconn.h"
#include "net/netconn.h"

#include <stdlib.h>
#include <stdbool.h>
#include <assert.h>
#include <string.h>

// Callback function that will be called when the map is rendered
static void handleMapSuccess(void *context, const uint8_t *bitmap, int numHedgehogs) {
	printf("Drawing map for %i brave little hogs...", numHedgehogs);

	// Draw the map as ASCII art
	for(int y=0; y<MAPIMAGE_HEIGHT; y++) {
		for(int x=0; x<MAPIMAGE_WIDTH; x++) {
			int pixelnum = x + y*MAPIMAGE_WIDTH;
			bool pixel = bitmap[pixelnum>>3] & (1<<(7-(pixelnum&7)));
			printf(pixel ? "#" : " ");
		}
		printf("\n");
	}

	// Destroy the connection object (this will end the "tick" loop below)
	flib_mapconn **connptr = context;
	flib_mapconn_destroy(*connptr);
	*connptr = NULL;
}

static void onDisconnect(void *context, int reason) {
	flib_log_i("Connection closed. Reason: %i", reason);
	flib_gameconn **connptr = context;
	flib_gameconn_destroy(*connptr);
	*connptr = NULL;
}

static void onGameRecorded(void *context, const uint8_t *record, int size, bool isSavegame) {
	flib_log_i("Writing %s (%i bytes)...", isSavegame ? "savegame" : "demo", size);
	FILE *file = fopen(isSavegame ? "testsave.42.hws" : "testdemo.42.hwd", "wb");
	fwrite(record, 1, size, file);
	fclose(file);
}

// Callback function that will be called on error
static void handleMapFailure(void *context, const char *errormessage) {
	flib_log_e("Map rendering failed: %s", errormessage);

	// Destroy the connection object (this will end the "tick" loop below)
	flib_mapconn **connptr = context;
	flib_mapconn_destroy(*connptr);
	*connptr = NULL;
}

static void startEngineMap(int port) {
	char commandbuffer[255];
	const char *enginePath = "C:\\Programmieren\\Hedgewars\\bin";
	const char *configPath = "C:\\Programmieren\\Hedgewars\\share\\hedgewars";
	snprintf(commandbuffer, 255, "start %s\\hwengine.exe %s %i landpreview", enginePath, configPath, port);
	system(commandbuffer);
}

static void startEngineGame(int port) {
	char commandbuffer[255];
	const char *enginePath = "C:\\Programmieren\\Hedgewars\\bin";
	const char *configPath = "C:\\Programmieren\\Hedgewars\\share\\hedgewars";
	const char *dataPath = "C:\\Programmieren\\Hedgewars\\share\\hedgewars\\Data";
	snprintf(commandbuffer, 255, "start %s\\hwengine.exe %s 1024 768 32 %i 0 0 0 10 10 %s 0 0 TWVkbzQy 0 0 en.txt", enginePath, configPath, port, dataPath);
	flib_log_d("Starting engine with CMD: %s", commandbuffer);
	system(commandbuffer);
}

void testMapPreview() {
	// Create a map description and check that there was no error
	flib_map *map = flib_map_create_maze("This is the seed value", "Jungle", MAZE_SIZE_SMALL_TUNNELS);
	assert(map);

	// Create a new connection to the engine and check that there was no error
	flib_mapconn *mapConnection = flib_mapconn_create(map);
	assert(mapConnection);

	// We don't need the map description anymore
	flib_map_release(map);
	map = NULL;

	// Register the callback functions
	flib_mapconn_onFailure(mapConnection, &handleMapFailure, &mapConnection);
	flib_mapconn_onSuccess(mapConnection, &handleMapSuccess, &mapConnection);

	// Start the engine process and tell it which port the frontlib is listening on
	startEngineMap(flib_mapconn_getport(mapConnection));

	// Usually, flib_mapconn_tick will be called in an event loop that runs several
	// times per second. It handles I/O operations and progress, and calls
	// callbacks when something interesting happens.
	while(mapConnection) {
		flib_mapconn_tick(mapConnection);
	}
}

void testGame() {
	flib_cfg_meta *metaconf = flib_cfg_meta_from_ini("metasettings.ini");
	assert(metaconf);
	flib_weaponset *weapons = flib_weaponset_create("Defaultweaps");
	flib_schemelist *schemelist = flib_schemelist_from_ini(metaconf, "schemes.ini");

	flib_gamesetup setup;
	setup.gamescheme = flib_schemelist_find(schemelist, "Default");
	setup.map = flib_map_create_maze("asparagus", "Jungle", MAZE_SIZE_MEDIUM_TUNNELS);
	setup.script = NULL;
	setup.teamCount = 2;
	setup.teams = calloc(2, sizeof(flib_team*));
	setup.teams[0] = calloc(1, sizeof(flib_team));
	setup.teams[0]->color = 0xffff0000;
	setup.teams[0]->flag = "australia";
	setup.teams[0]->fort = "Plane";
	setup.teams[0]->grave = "Bone";
	setup.teams[0]->hogsInGame = 2;
	setup.teams[0]->name = "Team Awesome";
	setup.teams[0]->voicepack = "British";
	setup.teams[0]->hogs[0].difficulty = 2;
	setup.teams[0]->hogs[0].hat = "NoHat";
	setup.teams[0]->hogs[0].initialHealth = 100;
	setup.teams[0]->hogs[0].name = "Harry 120";
	setup.teams[0]->hogs[1].difficulty = 2;
	setup.teams[0]->hogs[1].hat = "chef";
	setup.teams[0]->hogs[1].initialHealth = 100;
	setup.teams[0]->hogs[1].name = "Chefkoch";
	setup.teams[1] = flib_team_from_ini("Cave Dwellers.hwt");
	setup.teams[1]->color = 0xFF0000F0;
	setup.teams[1]->hogsInGame = 8;
	flib_team_set_weaponset(setup.teams[0], weapons);
	flib_team_set_weaponset(setup.teams[1], weapons);
	flib_weaponset_release(weapons);

	flib_gameconn *gameconn = flib_gameconn_create("Medo42", &setup, false);
	assert(gameconn);

	flib_gameconn_onDisconnect(gameconn, &onDisconnect, &gameconn);
	//flib_gameconn_onGameRecorded(gameconn, &onGameRecorded, &gameconn);

	startEngineGame(flib_gameconn_getport(gameconn));

	while(gameconn) {
		flib_gameconn_tick(gameconn);
	}
}

void testDemo() {
	FILE *demofile = fopen("testdemo.42.hwd", "rb");
	assert(demofile);
	flib_vector *vec = flib_vector_create();
	uint8_t demobuf[512];
	int len;
	while((len=fread(demobuf, 1, 512, demofile))>0) {
		flib_vector_append(vec, demobuf, len);
	}
	fclose(demofile);
	flib_constbuffer constbuf = flib_vector_as_constbuffer(vec);
	flib_gameconn *gameconn = flib_gameconn_create_playdemo(constbuf.data, constbuf.size);
	flib_vector_destroy(vec);
	assert(gameconn);
	flib_gameconn_onDisconnect(gameconn, &onDisconnect, &gameconn);
	flib_gameconn_onGameRecorded(gameconn, &onGameRecorded, &gameconn);
	startEngineGame(flib_gameconn_getport(gameconn));

	while(gameconn) {
		flib_gameconn_tick(gameconn);
	}
}

void testSave() {
	FILE *demofile = fopen("testsave.42.hws", "rb");
	assert(demofile);
	flib_vector *vec = flib_vector_create();
	uint8_t demobuf[512];
	int len;
	while((len=fread(demobuf, 1, 512, demofile))>0) {
		flib_vector_append(vec, demobuf, len);
	}
	fclose(demofile);
	flib_constbuffer constbuf = flib_vector_as_constbuffer(vec);
	flib_gameconn *gameconn = flib_gameconn_create_loadgame("Medo42", constbuf.data, constbuf.size);
	flib_vector_destroy(vec);
	assert(gameconn);
	flib_gameconn_onDisconnect(gameconn, &onDisconnect, &gameconn);
	flib_gameconn_onGameRecorded(gameconn, &onGameRecorded, &gameconn);
	startEngineGame(flib_gameconn_getport(gameconn));

	while(gameconn) {
		flib_gameconn_tick(gameconn);
	}
}

void handleNetDisconnect(void *context, int reason, const char *message) {
	flib_log_i("Disconnected: %s", message);
	flib_netconn_destroy(*(flib_netconn**)context);
	*(flib_netconn**)context = NULL;
}

void handleNetConnected(void *context) {
	const flib_roomlist *roomlist = flib_netconn_get_roomlist(*(flib_netconn**)context);
	flib_log_i("List of rooms:");
	for(int i=0; i<roomlist->roomCount; i++) {
		flib_roomlist_room *room = roomlist->rooms[i];
		flib_log_i("%1s %20s %20s %2i %2i %20s %20s %20s", room->inProgress ? "X" : " ", room->name, room->owner, room->playerCount, room->teamCount, room->map, room->scheme, room->weapons);
	}
}

void handleLobbyJoin(void *context, const char *nick) {
	flib_log_i("%s joined", nick);
}

void handleChat(void *context, const char *nick, const char *msg) {
	flib_log_i("%s: %s", nick, msg);
	if(!memcmp("frontbot ", msg, strlen("frontbot "))) {
		const char *command = msg+strlen("frontbot ");
		if(!memcmp("quit", command, strlen("quit"))) {
			flib_netconn_send_quit(*(flib_netconn**)context, "Yeth Mathter");
		} else if(!memcmp("describe ", command, strlen("describe "))) {
			const char *roomname = command+strlen("describe ");
			const flib_roomlist *roomlist = flib_netconn_get_roomlist(*(flib_netconn**)context);
			flib_roomlist_room *room = flib_roomlist_find((flib_roomlist*)roomlist, roomname);
			if(!room) {
				flib_netconn_send_chat(*(flib_netconn**)context, "Unknown room.");
			} else {
				char *text = flib_asprintf(
						"%s is a room created by %s, where %i players (%i teams) are %s on %s%s, using the %s scheme and %s weaponset.",
						room->name,
						room->owner,
						room->playerCount,
						room->teamCount,
						room->inProgress ? "fighting" : "preparing to fight",
						room->map[0]=='+' ? "" : "the map ",
						!strcmp("+rnd+", room->map) ? "a random map" :
								!strcmp("+maze+", room->map) ? "a random maze" :
								!strcmp("+drawn+", room->map) ? "a hand-drawn map" :
								room->map,
						room->scheme,
						room->weapons);
				if(text) {
					flib_netconn_send_chat(*(flib_netconn**)context, text);
				}
				free(text);
			}
		} else if(!memcmp("join ", command, strlen("join "))) {
			const char *roomname = command+strlen("join ");
			flib_netconn_send_joinRoom(*(flib_netconn**)context, roomname);
		} else if(!memcmp("ready", command, strlen("ready"))) {
			flib_netconn_send_toggleReady(*(flib_netconn**)context);
		}
	}
}

static flib_gamesetup gGamesetup = {0};
static flib_weaponset *gWeaponset = NULL;

void handleEnterRoom(void *context, bool isChief) {
	flib_netconn_send_toggleReady(*(flib_netconn**)context);
}

void handleMap(void *context, const flib_map *map, int changeType) {
	flib_map_release(gGamesetup.map);
	gGamesetup.map = flib_map_copy(map);
}

void handleCfgScheme(void *context, flib_cfg *cfg) {
	flib_cfg_release(gGamesetup.gamescheme);
	gGamesetup.gamescheme = flib_cfg_retain(cfg);
}

void handleWeaponset(void *context, flib_weaponset *weaponset) {
	flib_weaponset_release(gWeaponset);
	gWeaponset = flib_weaponset_retain(weaponset);
}

void handleScript(void *context, const char *script) {
	free(gGamesetup.script);
	gGamesetup.script = flib_strdupnull(script);
}

void handleTeamAdd(void *context, flib_team *team) {
	flib_team *teamptr = flib_team_retain(team);
	gGamesetup.teams = flib_list_insert(gGamesetup.teams, &gGamesetup.teamCount, sizeof(*gGamesetup.teams), &teamptr, 0);
}

void handleTeamRemove(void *context, const char *team) {
	for(int i=0; i<gGamesetup.teamCount; i++) {
		if(!strcmp(team, gGamesetup.teams[i]->name)) {
			flib_team_release(gGamesetup.teams[i]);
			gGamesetup.teams = flib_list_delete(gGamesetup.teams, &gGamesetup.teamCount, sizeof(*gGamesetup.teams), i);
		}
	}
}

int main(int argc, char *argv[]) {
	flib_init(0);
	flib_log_setLevel(FLIB_LOGLEVEL_ALL);

	//testMapPreview();
	//testDemo();
	//testSave();
	//testGame();

	flib_cfg_meta *meta = flib_cfg_meta_from_ini("metasettings.ini");
	assert(meta);
	flib_netconn *conn = flib_netconn_create("frontbot", meta, "140.247.62.101", 46631);
	assert(conn);
	flib_cfg_meta_release(meta);

	flib_netconn_onConnected(conn, handleNetConnected, &conn);
	flib_netconn_onDisconnected(conn, handleNetDisconnect, &conn);
	flib_netconn_onLobbyJoin(conn, handleLobbyJoin, &conn);
	flib_netconn_onChat(conn, handleChat, &conn);
	flib_netconn_onMapChanged(conn, handleMap, conn);
	flib_netconn_onEnterRoom(conn, handleEnterRoom, conn);
	flib_netconn_onCfgScheme(conn, handleCfgScheme, conn);
	flib_netconn_onWeaponsetChanged(conn, handleWeaponset, conn);
	flib_netconn_onScriptChanged(conn, handleScript, conn);
	flib_netconn_onTeamAdd(conn, handleTeamAdd, conn);
	flib_netconn_onTeamRemove(conn, handleTeamRemove, conn);
	flib_netconn_onHogCountChanged(conn, handleHogCountChanged, conn);

	while(conn) {
		flib_netconn_tick(conn);
	}

	flib_quit();
	return 0;
}
