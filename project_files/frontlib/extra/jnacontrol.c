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

/*
 * This file is not directly part of the frontlib and is not required to build it.
 * However, it is recommended to include it in compilation when building for Android. The purpose of this file
 * is to ensure consistency between the function signatures of the JNA Java bindings of the Android port and the
 * frontlib functions.
 *
 * This file, in essence, consists only of function declarations. They are duplicates of function declarations
 * from the frontlib headers that are referenced from JNA bindings. If the signature of one of these functions
 * changes in the frontlib, it will no longer match the signature in this file, and the compiler will show an error.
 * If that happens, you need to update the JNA bindings in Hedgeroid to match the new function signature, and then
 * update this file.
 *
 * The reason for all this is that JNA does not actually know the function signatures of the functions it binds,
 * it derives them from Java method declarations. If those do not match the actual function signatures, you will
 * only notice when you suddenly get strange (and possibly hard to track down) problems at runtime. This file is
 * an attempt to detect these problems at compile time instead. Notice that it will NOT detect changes to structs
 * or constants though, which also require updates to the JNA bindings.
 */

/*
 * Before we include the frontlib headers, we define away the const keyword. This is necessary because there is no
 * distinction between const and non-const types on the JNA side, and we don't want the compiler to complain because
 * of bad constness.
 *
 * This is so evil, but it works...
 */
#define const

#include "../frontlib.h"

/*
 * Now we map the Java types to the corresponding C types...
 */
typedef flib_netconn *NetconnPtr;
typedef flib_gameconn *GameconnPtr;
typedef flib_mapconn *MapconnPtr;
typedef flib_metascheme *MetaschemePtr;
typedef flib_room **RoomArrayPtr;
typedef flib_weaponset *WeaponsetPtr;
typedef flib_weaponsetlist *WeaponsetListPtr;
typedef flib_map *MapRecipePtr;
typedef flib_scheme *SchemePtr;
typedef flib_schemelist *SchemelistPtr;

typedef flib_room *RoomPtr;
typedef flib_team *TeamPtr;
typedef flib_gamesetup *GameSetupPtr;
typedef bool boolean;
typedef size_t NativeSizeT;
typedef void *Pointer;
typedef uint8_t *ByteArrayPtr;
typedef char *String;

/*
 * Mapping callback types
 */
typedef void (*VoidCallback)(Pointer context);
typedef void (*StrCallback)(Pointer context, String arg1);
typedef void (*IntCallback)(Pointer context, int arg1);
typedef void (*IntStrCallback)(Pointer context, int arg1, String arg2);
typedef void (*StrIntCallback)(Pointer context, String arg1, int arg2);
typedef void (*StrStrCallback)(Pointer context, String arg1, String arg2);
typedef void (*StrStrBoolCallback)(Pointer context, String arg1, String arg2, boolean arg3);
typedef void (*RoomCallback)(Pointer context, RoomPtr arg1);
typedef void (*RoomListCallback)(Pointer context, RoomArrayPtr arg1, int arg2);
typedef void (*StrRoomCallback)(Pointer context, String arg1, RoomPtr arg2);
typedef void (*BoolCallback)(Pointer context, boolean arg1);
typedef void (*StrBoolCallback)(Pointer context, String arg1, boolean arg2);
typedef void (*TeamCallback)(Pointer context, TeamPtr arg1);
typedef void (*BytesCallback)(Pointer context, const uint8_t *buffer, NativeSizeT size);
typedef void (*BytesBoolCallback)(Pointer context, const uint8_t *buffer, NativeSizeT size, boolean arg3);
typedef void (*SchemeCallback)(Pointer context, SchemePtr arg1);
typedef void (*MapIntCallback)(Pointer context, MapRecipePtr arg1, int arg2);
typedef void (*WeaponsetCallback)(Pointer context, WeaponsetPtr arg1);
typedef void (*MapimageCallback)(Pointer context, const uint8_t *mapimage, int hogs);
typedef void (*LogCallback)(int arg1, String arg2);

/*
 * Below here are the copypasted method declarations from the JNA bindings
 */

    // frontlib.h
    int flib_init();
    void flib_quit();

    // hwconsts.h
    int flib_get_teamcolor_count();
    int flib_get_hedgehogs_per_team();
    int flib_get_weapons_count();
    MetaschemePtr flib_get_metascheme();

    // net/netconn.h
    NetconnPtr flib_netconn_create(String playerName, String dataDirPath, String host, int port);
    void flib_netconn_destroy(NetconnPtr conn);

    void flib_netconn_tick(NetconnPtr conn);
    boolean flib_netconn_is_chief(NetconnPtr conn);
    String flib_netconn_get_playername(NetconnPtr conn);
    GameSetupPtr flib_netconn_create_gamesetup(NetconnPtr conn);
    int flib_netconn_send_quit(NetconnPtr conn, String quitmsg);
    int flib_netconn_send_chat(NetconnPtr conn, String chat);
    int flib_netconn_send_teamchat(NetconnPtr conn, String msg);
    int flib_netconn_send_password(NetconnPtr conn, String passwd);
    int flib_netconn_send_nick(NetconnPtr conn, String nick);
    int flib_netconn_send_request_roomlist(NetconnPtr conn);
    int flib_netconn_send_joinRoom(NetconnPtr conn, String room);
    int flib_netconn_send_createRoom(NetconnPtr conn, String room);
    int flib_netconn_send_renameRoom(NetconnPtr conn, String roomName);
    int flib_netconn_send_leaveRoom(NetconnPtr conn, String msg);
    int flib_netconn_send_toggleReady(NetconnPtr conn);
    int flib_netconn_send_addTeam(NetconnPtr conn, TeamPtr team);
    int flib_netconn_send_removeTeam(NetconnPtr conn, String teamname);
    int flib_netconn_send_engineMessage(NetconnPtr conn, ByteArrayPtr message, NativeSizeT size);
    int flib_netconn_send_teamHogCount(NetconnPtr conn, String teamname, int hogcount);
    int flib_netconn_send_teamColor(NetconnPtr conn, String teamname, int colorIndex);
    int flib_netconn_send_weaponset(NetconnPtr conn, WeaponsetPtr weaponset);
    int flib_netconn_send_map(NetconnPtr conn, MapRecipePtr map);
    int flib_netconn_send_mapName(NetconnPtr conn, String mapName);
    int flib_netconn_send_mapGen(NetconnPtr conn, int mapGen);
    int flib_netconn_send_mapTemplate(NetconnPtr conn, int templateFilter);
    int flib_netconn_send_mapMazeSize(NetconnPtr conn, int mazeSize);
    int flib_netconn_send_mapSeed(NetconnPtr conn, String seed);
    int flib_netconn_send_mapTheme(NetconnPtr conn, String theme);
    int flib_netconn_send_mapDrawdata(NetconnPtr conn, ByteArrayPtr drawData, NativeSizeT size);
    int flib_netconn_send_script(NetconnPtr conn, String scriptName);
    int flib_netconn_send_scheme(NetconnPtr conn, SchemePtr scheme);
    int flib_netconn_send_roundfinished(NetconnPtr conn, boolean withoutError);
    int flib_netconn_send_ban(NetconnPtr conn, String playerName);
    int flib_netconn_send_kick(NetconnPtr conn, String playerName);
    int flib_netconn_send_playerInfo(NetconnPtr conn, String playerName);
    int flib_netconn_send_playerFollow(NetconnPtr conn, String playerName);
    int flib_netconn_send_startGame(NetconnPtr conn);
    int flib_netconn_send_toggleRestrictJoins(NetconnPtr conn);
    int flib_netconn_send_toggleRestrictTeams(NetconnPtr conn);
    int flib_netconn_send_clearAccountsCache(NetconnPtr conn);
    int flib_netconn_send_setServerVar(NetconnPtr conn, String name, String value);
    int flib_netconn_send_getServerVars(NetconnPtr conn);

    void flib_netconn_onMessage(NetconnPtr conn, IntStrCallback callback, Pointer context);
    void flib_netconn_onClientFlags(NetconnPtr conn, StrStrBoolCallback callback, Pointer context);
    void flib_netconn_onChat(NetconnPtr conn, StrStrCallback callback, Pointer context);
    void flib_netconn_onConnected(NetconnPtr conn, VoidCallback callback, Pointer context);
    void flib_netconn_onDisconnected(NetconnPtr conn, IntStrCallback callback, Pointer context);
    void flib_netconn_onRoomlist(NetconnPtr conn, RoomListCallback callback, Pointer context);
    void flib_netconn_onRoomAdd(NetconnPtr conn, RoomCallback callback, Pointer context);
    void flib_netconn_onRoomDelete(NetconnPtr conn, StrCallback callback, Pointer context);
    void flib_netconn_onRoomUpdate(NetconnPtr conn, StrRoomCallback callback, Pointer context);
    void flib_netconn_onLobbyJoin(NetconnPtr conn, StrCallback callback, Pointer context);
    void flib_netconn_onLobbyLeave(NetconnPtr conn, StrStrCallback callback, Pointer context);
    void flib_netconn_onNickTaken(NetconnPtr conn, StrCallback callback, Pointer context);
    void flib_netconn_onPasswordRequest(NetconnPtr conn, StrCallback callback, Pointer context);
    void flib_netconn_onEnterRoom(NetconnPtr conn, BoolCallback callback, Pointer context);
    void flib_netconn_onLeaveRoom(NetconnPtr conn, IntStrCallback callback, Pointer context);
    void flib_netconn_onTeamAdd(NetconnPtr conn, TeamCallback callback, Pointer context);
    void flib_netconn_onTeamDelete(NetconnPtr conn, StrCallback callback, Pointer context);
    void flib_netconn_onRoomJoin(NetconnPtr conn, StrCallback callback, Pointer context);
    void flib_netconn_onRoomLeave(NetconnPtr conn, StrStrCallback callback, Pointer context);
    void flib_netconn_onRunGame(NetconnPtr conn, VoidCallback callback, Pointer context);
    void flib_netconn_onTeamAccepted(NetconnPtr conn, StrCallback callback, Pointer context);
    void flib_netconn_onHogCountChanged(NetconnPtr conn, StrIntCallback callback, Pointer context);
    void flib_netconn_onTeamColorChanged(NetconnPtr conn, StrIntCallback callback, Pointer context);
    void flib_netconn_onEngineMessage(NetconnPtr conn, BytesCallback callback, Pointer context);
    void flib_netconn_onSchemeChanged(NetconnPtr conn, SchemeCallback callback, Pointer context);
    void flib_netconn_onMapChanged(NetconnPtr conn, MapIntCallback callback, Pointer context);
    void flib_netconn_onScriptChanged(NetconnPtr conn, StrCallback callback, Pointer context);
    void flib_netconn_onWeaponsetChanged(NetconnPtr conn, WeaponsetCallback callback, Pointer context);
    void flib_netconn_onServerVar(NetconnPtr conn, StrStrCallback callback, Pointer context);

    // ipc/gameconn.h

    GameconnPtr flib_gameconn_create(String playerName, GameSetupPtr setup, boolean netgame);
    GameconnPtr flib_gameconn_create_playdemo(ByteArrayPtr demo, NativeSizeT size);
    GameconnPtr flib_gameconn_create_loadgame(String playerName, ByteArrayPtr save, NativeSizeT size);
    GameconnPtr flib_gameconn_create_campaign(String playerName, String seed, String script);

    void flib_gameconn_destroy(GameconnPtr conn);
    int flib_gameconn_getport(GameconnPtr conn);
    void flib_gameconn_tick(GameconnPtr conn);

    int flib_gameconn_send_enginemsg(GameconnPtr conn, ByteArrayPtr data, NativeSizeT len);
    int flib_gameconn_send_textmsg(GameconnPtr conn, int msgtype, String msg);
    int flib_gameconn_send_chatmsg(GameconnPtr conn, String playername, String msg);
    int flib_gameconn_send_quit(GameconnPtr conn);
    int flib_gameconn_send_cmd(GameconnPtr conn, String cmdString);

    void flib_gameconn_onConnect(GameconnPtr conn, VoidCallback callback, Pointer context);
    void flib_gameconn_onDisconnect(GameconnPtr conn, IntCallback callback, Pointer context);
    void flib_gameconn_onErrorMessage(GameconnPtr conn, StrCallback callback, Pointer context);
    void flib_gameconn_onChat(GameconnPtr conn, StrBoolCallback callback, Pointer context);
    void flib_gameconn_onGameRecorded(GameconnPtr conn, BytesBoolCallback callback, Pointer context);
    void flib_gameconn_onEngineMessage(GameconnPtr conn, BytesCallback callback, Pointer context);

    // ipc/mapconn.h
    MapconnPtr flib_mapconn_create(MapRecipePtr mapdesc);
    void flib_mapconn_destroy(MapconnPtr conn);
    int flib_mapconn_getport(MapconnPtr conn);
    void flib_mapconn_onSuccess(MapconnPtr conn, MapimageCallback callback, Pointer context);
    void flib_mapconn_onFailure(MapconnPtr conn, StrCallback callback, Pointer context);
    void flib_mapconn_tick(MapconnPtr conn);

    // model/schemelist.h
    SchemelistPtr flib_schemelist_from_ini(String filename);
    int flib_schemelist_to_ini(String filename, SchemelistPtr list);
    void flib_schemelist_destroy(SchemelistPtr list);

    // model/team.h
    TeamPtr flib_team_from_ini(String filename);
    int flib_team_to_ini(String filename, TeamPtr team);
    void flib_team_destroy(TeamPtr team);

    // model/weapon.h
    WeaponsetListPtr flib_weaponsetlist_from_ini(String filename);
    int flib_weaponsetlist_to_ini(String filename, WeaponsetListPtr weaponsets);
    void flib_weaponsetlist_destroy(WeaponsetListPtr list);

    // model/gamesetup.h
    void flib_gamesetup_destroy(GameSetupPtr gamesetup);

    // util/logging.h
    void flib_log_setLevel(int level);
    void flib_log_setCallback(LogCallback callback);
