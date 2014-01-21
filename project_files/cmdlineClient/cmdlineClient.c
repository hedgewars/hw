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

#include <frontlib.h>
#include <util/logging.h>
#include <util/util.h>
#include <base64/base64.h>
#include <model/schemelist.h>

#include <stdlib.h>
#include <stdbool.h>
#include <assert.h>
#include <string.h>
#include <conio.h>
#include <windows.h>

#define ENGINE_DIR ".\\"
#define CONFIG_DIR "..\\share\\hedgewars"
#define DATA_DIR CONFIG_DIR"\\Data"

static flib_netconn *netconn;
static flib_gameconn *gameconn;
static flib_mapconn *mapconn;
static char nickname[128];
static flib_metascheme *metacfg;
static bool netConnected = false;

// Callback function that will be called when the map is rendered
static void handleMapGenerated(void *context, const uint8_t *bitmap, int numHedgehogs) {
    printf("Drawing map for %i brave little hogs...", numHedgehogs);

    // Draw the map as ASCII art
    for(int y=0; y<MAPIMAGE_HEIGHT; y+=8) {
        for(int x=0; x<MAPIMAGE_WIDTH; x+=6) {
            int pixelnum = x + y*MAPIMAGE_WIDTH;
            bool pixel = bitmap[pixelnum>>3] & (1<<(7-(pixelnum&7)));
            printf(pixel ? "#" : " ");
        }
        printf("\n");
    }

    flib_mapconn_destroy(mapconn);
    mapconn = NULL;
}

static void onGameDisconnect(void *context, int reason) {
    flib_log_i("Connection closed. Reason: %i", reason);
    flib_gameconn_destroy(gameconn);
    gameconn = NULL;
    if(netconn) {
        flib_netconn_send_roundfinished(netconn, reason==GAME_END_FINISHED);
    }
}

// Callback function that will be called on error
static void handleMapFailure(void *context, const char *errormessage) {
    flib_log_e("Map rendering failed: %s", errormessage);
    flib_mapconn_destroy(mapconn);
    mapconn = NULL;
}

static void startEngineMap(int port) {
    char cmdbuffer[255];
    char argbuffer[255];
    snprintf(cmdbuffer, 255, "%shwengine.exe", ENGINE_DIR);
    snprintf(argbuffer, 255, "%s %i landpreview", CONFIG_DIR, port);
    ShellExecute(NULL, NULL, cmdbuffer, argbuffer, NULL, SW_HIDE);
}

static void startEngineGame(int port) {
    char cmdbuffer[255];
    char argbuffer[255];
    char base64PlayerName[255];
    base64_encode(nickname, strlen(nickname), base64PlayerName, sizeof(base64PlayerName));
    snprintf(cmdbuffer, 255, "%shwengine.exe", ENGINE_DIR);
    snprintf(argbuffer, 255, "%s 1024 768 32 %i 0 0 0 10 10 %s 0 0 %s 0 0 en.txt", CONFIG_DIR, port, DATA_DIR, base64PlayerName);
    ShellExecute(NULL, NULL, cmdbuffer, argbuffer, NULL, SW_HIDE);
}

void handleNetDisconnect(void *context, int reason, const char *message) {
    printf("Disconnected: %s", message);
    flib_netconn_destroy(netconn);
    netconn = NULL;
}

/*void printRoomList() {
    const flib_roomlist *roomlist = flib_netconn_get_roomlist(netconn);
    if(roomlist) {
        if(roomlist->roomCount>0) {
            for(int i=0; i<roomlist->roomCount; i++) {
                if(i>0) {
                    printf(", ");
                }
                flib_room *room = roomlist->rooms[i];
                printf("%s", room->name);
            }
        } else {
            puts("Unfortunately, there are no rooms at the moment.");
        }
    } else {
        puts("Sorry, due to an error the room list is not available.");
    }
    puts("\n");
}*/

void printTeamList() {
    flib_gamesetup *setup = flib_netconn_create_gamesetup(netconn);
    if(setup) {
        puts("The following teams are in this room:");
        for(int i=0; i<setup->teamlist->teamCount; i++) {
            if(i>0) {
                printf(", ");
            }
            printf("%s", setup->teamlist->teams[i]->name);
        }
        puts("\n");
    } else {
        puts("Sorry, due to an error the team list is not available.");
    }
    flib_gamesetup_destroy(setup);
}

void handleNetConnected(void *context) {
    printf("You enter the lobby of a strange house inhabited by hedgehogs. Looking around, you see hallways branching off to these rooms:\n");
    //printRoomList();
    printf("\n\nNow, you can chat by just entering text, or join a room with /join <roomname>.");
    printf(" You can also /quit or let me /describe <roomname>. Once in a room, you can /add <teamname> and set yourself /ready. You can also /list the available rooms (in the lobby) or the teams (in a room).\n");
    netConnected = true;
}

void handleChat(void *context, const char *nick, const char *msg) {
    if(gameconn) {
        flib_gameconn_send_chatmsg(gameconn, nick, msg);
    }
    printf("%s: %s\n", nick, msg);
}

void handleEnterRoom(void *context, bool isChief) {
    puts("You have entered the room.");
}

void handleRoomJoin(void *context, const char *nick) {
    if(strcmp(nick, nickname)) {
        printf("%s is here.\n", nick);
    }
}

void handleRoomLeave(void *context, const char *nick, const char *partmsg) {
    if(strcmp(nick, nickname)) {
        printf("%s leaves.\n", nick);
    }
}

void handleReady(void *context, const char *nick, bool ready) {
    if(strcmp(nick, nickname)) {
        if(ready) {
            printf("%s is ready to go.\n", nick);
        } else {
            printf("%s is not ready.\n", nick);
        }
    } else {
        if(ready) {
            printf("You are ready to go.\n");
        } else {
            printf("You are not ready.\n");
        }
    }
}

void handleEmFromNet(void *context, const uint8_t *em, size_t size) {
    if(gameconn) {
        flib_gameconn_send_enginemsg(gameconn, em, size);
    }
}

void handleEmFromEngine(void *context, const uint8_t *em, size_t size) {
    if(netconn) {
        flib_netconn_send_engineMessage(netconn, em, size);
    }
}

void handleChatFromGame(void *context, const char *message, bool teamchat) {
    if(netconn) {
        if(teamchat) {
            flib_netconn_send_teamchat(netconn, message);
        } else {
            flib_netconn_send_chat(netconn, message);
        }
    }
}

void handleRunGame(void *context) {
    flib_gamesetup *gamesetup = flib_netconn_create_gamesetup(netconn);
    if(gameconn) {
        flib_log_e("Request to start game, but a game is already running.");
    } else if(gamesetup) {
        gameconn = flib_gameconn_create(nickname, gamesetup, true);
        flib_gameconn_onEngineMessage(gameconn, handleEmFromEngine, NULL);
        flib_gameconn_onDisconnect(gameconn, onGameDisconnect, NULL);
        flib_gameconn_onChat(gameconn, handleChatFromGame, NULL);
        startEngineGame(flib_gameconn_getport(gameconn));
    }
    flib_gamesetup_destroy(gamesetup);
}

void handleNickTaken(void *context, const char *nick) {
    printf("The nickname %s is already in use, please choose a different one:\n", nick);
    flib_gets(nickname, sizeof(nickname));
    flib_netconn_send_nick(netconn, nickname);
}

void handlePwRequest(void *context, const char *nick) {
    printf("A password is required to log in as %s, please enter (warning: shown in cleartext):\n", nick);
    char password[256];
    flib_gets(password, sizeof(password));
    flib_netconn_send_password(netconn, password);
}

void handleMessage(void *context, int type, const char *msg) {
    if(gameconn) {
        flib_gameconn_send_textmsg(gameconn, 1, msg);
    }
    printf("*** %s\n", msg);
}

void handleTeamAccepted(void *context, const char *teamname) {
    printf("The team %s has been accepted.\n", teamname);
}

void handleMapChanged(void *context, const flib_map *map, int changetype) {
    if(map->mapgen != MAPGEN_NAMED && changetype != NETCONN_MAPCHANGE_THEME) {
        if(mapconn) {
            flib_mapconn_destroy(mapconn);
            mapconn = NULL;
        }
        mapconn = flib_mapconn_create(map);
        if(mapconn) {
            flib_mapconn_onSuccess(mapconn, handleMapGenerated, NULL);
            flib_mapconn_onFailure(mapconn, handleMapFailure, NULL);
            startEngineMap(flib_mapconn_getport(mapconn));
        }
    } else if(map->mapgen == MAPGEN_NAMED) {
        printf("The map %s has been selected.\n", map->name);
    }
}

void handleLeaveRoom(void *context, int reason, const char *msg) {
    if(reason == NETCONN_ROOMLEAVE_ABANDONED) {
        printf("The chief has abandoned the room.");
    } else if(reason == NETCONN_ROOMLEAVE_KICKED) {
        printf("You have been kicked from the room.");
    }
    if(msg) {
        printf(" (%s)", msg);
    }
    puts(" You are back in the lobby.");
}

void handleSchemeChanged(void *context, const flib_scheme *scheme) {
    printf("Game scheme: %s.\n", scheme->name);
}

void handleWeaponsetChanged(void *context, const flib_weaponset *weaponset) {
    printf("Weaponset: %s.\n", weaponset->name);
}

void handleHogcountChanged(void *context, const char *team, int count) {
    printf("Team %s will send %i hogs into the fight.\n", team, count);
}

void handleRoomAdd(void *context, const flib_room *room) {
    printf("%s created a new room called %s.\n", room->owner, room->name);
}

void handleRoomDelete(void *context, const char *roomName) {
    printf("The room %s has collapsed.\n", roomName);
}

void handleScriptChanged(void *context, const char *script) {
    printf("Game Type: %s\n", script);
}

void handleTeamAdd(void *context, const flib_team *team) {
    printf("%s puts the team %s to the planning board.\n", team->ownerName, team->name);
}

void handleTeamDelete(void *context, const char *teamName) {
    printf("The team %s decided not to fight this battle after all.\n", teamName);
}

void handleTeamColorChanged(void *context, const char *name, int colorIndex) {
    static const char* colorNames[] = {"red", "blue", "teal", "purple", "pink", "green", "orange", "brown", "yellow"};
    const char *colorName = "strange";
    if(colorIndex>=0 && colorIndex < 9) {
        colorName = colorNames[colorIndex];
    }
    printf("The team %s will wear %s uniforms today.\n", name, colorName);
}

void tick() {
    if(gameconn) {
        flib_gameconn_tick(gameconn);
    }
    if(netconn) {
        flib_netconn_tick(netconn);
    }
    if(mapconn) {
        flib_mapconn_tick(mapconn);
    }
}

static HANDLE hStdin;

static int init() {
    hStdin = GetStdHandle(STD_INPUT_HANDLE);
    if(hStdin == INVALID_HANDLE_VALUE) {
        flib_log_e("Unable to get stdin handle");
        return 1;
    }
    if(!flib_init(0)) {
        flib_log_setLevel(FLIB_LOGLEVEL_WARNING);
        freopen( "CON", "w", stdout );
        freopen( "CON", "w", stderr );
        metacfg = flib_metascheme_from_ini("metasettings.ini");
        if(!metacfg) {
            flib_quit();
            return -1;
        } else {
            return 0;
        }
    }
    return -1;
}

int main(int argc, char *argv[]) {
    if(init()) {
        return -1;
    }

    puts("Please enter a nickname:");
    flib_gets(nickname, sizeof(nickname));

    netconn = flib_netconn_create(nickname, metacfg, DATA_DIR"\\", "140.247.62.101", 46631);
    if(!netconn) {
        flib_quit();
        return -1;
    }

    flib_netconn_onConnected(netconn, handleNetConnected, NULL);
    flib_netconn_onDisconnected(netconn, handleNetDisconnect, NULL);
    flib_netconn_onChat(netconn, handleChat, NULL);
    flib_netconn_onEnterRoom(netconn, handleEnterRoom, NULL);
    flib_netconn_onRunGame(netconn, handleRunGame, NULL);
    flib_netconn_onEngineMessage(netconn, handleEmFromNet, NULL);
    flib_netconn_onRoomJoin(netconn, handleRoomJoin, NULL);
    flib_netconn_onRoomLeave(netconn, handleRoomLeave, NULL);
    flib_netconn_onReadyState(netconn, handleReady, NULL);
    flib_netconn_onNickTaken(netconn, handleNickTaken, NULL);
    flib_netconn_onPasswordRequest(netconn, handlePwRequest, NULL);
    flib_netconn_onMessage(netconn, handleMessage, NULL);
    flib_netconn_onTeamAccepted(netconn, handleTeamAccepted, NULL);
    flib_netconn_onMapChanged(netconn, handleMapChanged, NULL);
    flib_netconn_onLeaveRoom(netconn, handleLeaveRoom, NULL);
    flib_netconn_onCfgScheme(netconn, handleSchemeChanged, NULL);
    flib_netconn_onWeaponsetChanged(netconn, handleWeaponsetChanged, NULL);
    flib_netconn_onHogCountChanged(netconn, handleHogcountChanged, NULL);
    flib_netconn_onRoomAdd(netconn, handleRoomAdd, NULL);
    flib_netconn_onRoomDelete(netconn, handleRoomDelete, NULL);
    flib_netconn_onScriptChanged(netconn, handleScriptChanged, NULL);
    flib_netconn_onTeamAdd(netconn, handleTeamAdd, NULL);
    flib_netconn_onTeamDelete(netconn, handleTeamDelete, NULL);
    flib_netconn_onTeamColorChanged(netconn, handleTeamColorChanged, NULL);

    INPUT_RECORD inputRecord;
    DWORD eventCount = 0;

    while(netconn || gameconn) {
        tick();
        if(netconn && netConnected) {
            while(PeekConsoleInput(hStdin, &inputRecord, 1, &eventCount) && eventCount>0) {
                if(inputRecord.EventType != KEY_EVENT) {
                    ReadConsoleInput(hStdin, &inputRecord, 1, &eventCount);
                } else {
                    printf("%s: ", nickname);
                    char input[256];
                    if(!flib_gets(input, sizeof(input))) {
                        if(!memcmp("/quit", input, strlen("/quit"))) {
                            flib_netconn_send_quit(netconn, "Player quit.");
                        } else if(!memcmp("/describe ", input, strlen("/describe "))) {
                            const char *roomname = input+strlen("/describe ");
                            /*const flib_roomlist *roomlist = flib_netconn_get_roomlist(netconn);
                            flib_room *room = flib_roomlist_find(roomlist, roomname);
                            if(!room) {
                                puts("Unknown room.");
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
                                    puts(text);
                                }
                                free(text);
                            }*/
                        } else if(!memcmp("/join ", input, strlen("/join "))) {
                            const char *roomname = input+strlen("/join ");
                            flib_netconn_send_joinRoom(netconn, roomname);
                        } else if(!memcmp("/ready", input, strlen("/ready"))) {
                            flib_netconn_send_toggleReady(netconn);
                        } else if(!memcmp("/loglevel ", input, strlen("/loglevel "))) {
                            int loglevel = atoi(input+strlen("/loglevel "));
                            flib_log_setLevel(loglevel);
                        } else if(!memcmp("/list", input, strlen("/list"))) {
                            if(flib_netconn_is_in_room_context(netconn)) {
                                printTeamList();
                            } else {
                                puts("From this big and expansive lobby, hallways branch off to these rooms:");
                                //printRoomList();
                            }
                        } else if(!memcmp("/addteam ", input, strlen("/addteam "))) {
                            const char *teamname = input+strlen("/addteam ");
                            if(!flib_contains_dir_separator(teamname)) {
                                char *teamfilename = flib_asprintf("%s.hwt", teamname);
                                if(teamfilename) {
                                    flib_team *team = flib_team_from_ini(teamfilename);
                                    if(team) {
                                        flib_netconn_send_addTeam(netconn, team);
                                    } else {
                                        printf("Teamfile %s not found.\n", teamfilename);
                                    }
                                    flib_team_destroy(team);
                                }
                                free(teamfilename);
                            }
                        } else if(strlen(input)>0) {
                            flib_netconn_send_chat(netconn, input);
                        }
                    }
                }
            }
        }
        fflush(stdout);
        Sleep(10);
    }


    flib_metascheme_release(metacfg);
    return 0;
}
