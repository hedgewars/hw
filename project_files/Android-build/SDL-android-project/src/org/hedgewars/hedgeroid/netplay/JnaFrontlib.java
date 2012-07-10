package org.hedgewars.hedgeroid.netplay;
import java.nio.Buffer;

import com.sun.jna.Callback;
import com.sun.jna.Library;
import com.sun.jna.NativeLong;
import com.sun.jna.Pointer;
import com.sun.jna.PointerType;


public interface JnaFrontlib extends Library {
	static final int NETCONN_STATE_CONNECTING = 0;
	static final int NETCONN_STATE_LOBBY = 1;
	static final int NETCONN_STATE_ROOM = 2;
	static final int NETCONN_STATE_INGAME = 3;
	static final int NETCONN_STATE_DISCONNECTED = 10;
	
	static final int NETCONN_DISCONNECT_NORMAL = 0;
	static final int NETCONN_DISCONNECT_SERVER_TOO_OLD = 1;
	static final int NETCONN_DISCONNECT_AUTH_FAILED = 2;
	static final int NETCONN_DISCONNECT_CONNLOST = 3;
	static final int NETCONN_DISCONNECT_INTERNAL_ERROR = 100;
	
	static final int NETCONN_ROOMLEAVE_ABANDONED = 0;
	static final int NETCONN_ROOMLEAVE_KICKED = 1;
	
	static final int NETCONN_MSG_TYPE_PLAYERINFO = 0;
	static final int NETCONN_MSG_TYPE_SERVERMESSAGE = 1;
	static final int NETCONN_MSG_TYPE_WARNING = 2;
	static final int NETCONN_MSG_TYPE_ERROR = 3;
	
	static final int NETCONN_MAPCHANGE_FULL = 0;
	static final int NETCONN_MAPCHANGE_MAP = 1;
	static final int NETCONN_MAPCHANGE_MAPGEN = 2;
	static final int NETCONN_MAPCHANGE_DRAWNMAP = 3;
	static final int NETCONN_MAPCHANGE_MAZE_SIZE = 4;
	static final int NETCONN_MAPCHANGE_TEMPLATE = 5;
	static final int NETCONN_MAPCHANGE_THEME = 6;
	static final int NETCONN_MAPCHANGE_SEED = 7;
	
	static final int  GAME_END_FINISHED = 0;
	static final int  GAME_END_INTERRUPTED = 1;
	static final int  GAME_END_HALTED = 2;
	static final int  GAME_END_ERROR = 3;
	
	static class NetconnPtr extends PointerType { }
	static class MapconnPtr extends PointerType { }
	static class GameconnPtr extends PointerType { }
	static class MetaschemePtr extends PointerType { }
	static class RoomlistPtr extends PointerType { }
	static class RoomPtr extends PointerType { }
	static class TeamPtr extends PointerType { }
	static class WeaponsetPtr extends PointerType { }
	static class MapRecipePtr extends PointerType { }
	static class SchemePtr extends PointerType { }
	static class GameSetupPtr extends PointerType { }
	
	public static interface VoidCallback extends Callback {
		void callback(Pointer context);
	}
	
	public static interface StrCallback extends Callback {
		void callback(Pointer context, String arg1);
	}
	
	public static interface IntCallback extends Callback {
		void callback(Pointer context, int arg1);
	}
	
	public static interface IntStrCallback extends Callback {
		void callback(Pointer context, int arg1, String arg2);
	}
	
	public static interface StrIntCallback extends Callback {
		void callback(Pointer context, String arg1, int arg2);
	}
	
	public static interface StrStrCallback extends Callback {
		void callback(Pointer context, String arg1, String arg2);
	}
	
	public static interface RoomCallback extends Callback {
		void callback(Pointer context, JnaFrontlib.RoomPtr arg1);
	}
	
	public static interface StrRoomCallback extends Callback {
		void callback(Pointer context, String arg1, JnaFrontlib.RoomPtr arg2);
	}
	
	public static interface BoolCallback extends Callback {
		void callback(Pointer context, boolean arg1);
	}
	
	public static interface StrBoolCallback extends Callback {
		void callback(Pointer context, String arg1, boolean arg2);
	}
	
	public static interface TeamCallback extends Callback {
		void callback(Pointer context, JnaFrontlib.TeamPtr arg1);
	}
	
	public static interface BytesCallback extends Callback {
		void callback(Pointer context, Pointer buffer, NativeLong size);
	}
	
	public static interface BytesBoolCallback extends Callback {
		void callback(Pointer context, Pointer buffer, NativeLong size, boolean arg3);
	}
	
	public static interface SchemeCallback extends Callback {
		void callback(Pointer context, JnaFrontlib.SchemePtr arg1);
	}
	
	public static interface MapIntCallback extends Callback {
		void callback(Pointer context, JnaFrontlib.MapRecipePtr arg1, int arg2);
	}
	
	public static interface WeaponsetCallback extends Callback {
		void callback(Pointer context, JnaFrontlib.WeaponsetPtr arg1);
	}
	
	public static interface MapimageCallback extends Callback {
		void callback(Pointer context, Pointer buffer, int hedgehogCount);
	}
	
    int flib_init();
    void flib_quit();
	
	JnaFrontlib.NetconnPtr flib_netconn_create(String playerName, JnaFrontlib.MetaschemePtr meta, String dataDirPath, String host, int port);
	void flib_netconn_destroy(JnaFrontlib.NetconnPtr conn);

	void flib_netconn_tick(JnaFrontlib.NetconnPtr conn);
	JnaFrontlib.RoomlistPtr flib_netconn_get_roomlist(JnaFrontlib.NetconnPtr conn);
	boolean flib_netconn_is_chief(JnaFrontlib.NetconnPtr conn);
	boolean flib_netconn_is_in_room_context(JnaFrontlib.NetconnPtr conn);
	JnaFrontlib.GameSetupPtr flib_netconn_create_gamesetup(JnaFrontlib.NetconnPtr conn);
	int flib_netconn_send_quit(JnaFrontlib.NetconnPtr conn, String quitmsg);
	int flib_netconn_send_chat(JnaFrontlib.NetconnPtr conn, String chat);
	int flib_netconn_send_teamchat(JnaFrontlib.NetconnPtr conn, String msg);
	int flib_netconn_send_password(JnaFrontlib.NetconnPtr conn, String passwd);
	int flib_netconn_send_nick(JnaFrontlib.NetconnPtr conn, String nick);
	int flib_netconn_send_joinRoom(JnaFrontlib.NetconnPtr conn, String room);
	int flib_netconn_send_createRoom(JnaFrontlib.NetconnPtr conn, String room);
	int flib_netconn_send_renameRoom(JnaFrontlib.NetconnPtr conn, String roomName);
	int flib_netconn_send_leaveRoom(JnaFrontlib.NetconnPtr conn, String msg);
	int flib_netconn_send_toggleReady(JnaFrontlib.NetconnPtr conn);
	int flib_netconn_send_addTeam(JnaFrontlib.NetconnPtr conn, JnaFrontlib.TeamPtr team);
	int flib_netconn_send_removeTeam(JnaFrontlib.NetconnPtr conn, String teamname);
	int flib_netconn_send_engineMessage(JnaFrontlib.NetconnPtr conn, Buffer message, NativeLong size); // TODO check if NativeLong==size_t
	int flib_netconn_send_teamHogCount(JnaFrontlib.NetconnPtr conn, String teamname, int hogcount);
	int flib_netconn_send_teamColor(JnaFrontlib.NetconnPtr conn, String teamname, int colorIndex);
	int flib_netconn_send_weaponset(JnaFrontlib.NetconnPtr conn, JnaFrontlib.WeaponsetPtr weaponset);
	int flib_netconn_send_map(JnaFrontlib.NetconnPtr conn, JnaFrontlib.MapRecipePtr map);
	int flib_netconn_send_mapName(JnaFrontlib.NetconnPtr conn, String mapName);
	int flib_netconn_send_mapGen(JnaFrontlib.NetconnPtr conn, int mapGen);
	int flib_netconn_send_mapTemplate(JnaFrontlib.NetconnPtr conn, int templateFilter);
	int flib_netconn_send_mapMazeSize(JnaFrontlib.NetconnPtr conn, int mazeSize);
	int flib_netconn_send_mapSeed(JnaFrontlib.NetconnPtr conn, String seed);
	int flib_netconn_send_mapTheme(JnaFrontlib.NetconnPtr conn, String theme);
	int flib_netconn_send_mapDrawdata(JnaFrontlib.NetconnPtr conn, Buffer drawData, NativeLong size);
	int flib_netconn_send_script(JnaFrontlib.NetconnPtr conn, String scriptName);
	int flib_netconn_send_scheme(JnaFrontlib.NetconnPtr conn, JnaFrontlib.SchemePtr scheme);
	int flib_netconn_send_roundfinished(JnaFrontlib.NetconnPtr conn, boolean withoutError);
	int flib_netconn_send_ban(JnaFrontlib.NetconnPtr conn, String playerName);
	int flib_netconn_send_kick(JnaFrontlib.NetconnPtr conn, String playerName);
	int flib_netconn_send_playerInfo(JnaFrontlib.NetconnPtr conn, String playerName);
	int flib_netconn_send_playerFollow(JnaFrontlib.NetconnPtr conn, String playerName);
	int flib_netconn_send_startGame(JnaFrontlib.NetconnPtr conn);
	int flib_netconn_send_toggleRestrictJoins(JnaFrontlib.NetconnPtr conn);
	int flib_netconn_send_toggleRestrictTeams(JnaFrontlib.NetconnPtr conn);
	int flib_netconn_send_clearAccountsCache(JnaFrontlib.NetconnPtr conn);
	int flib_netconn_send_setServerVar(JnaFrontlib.NetconnPtr conn, String name, String value);
	int flib_netconn_send_getServerVars(JnaFrontlib.NetconnPtr conn);
	
	void flib_netconn_onMessage(JnaFrontlib.NetconnPtr conn, JnaFrontlib.IntStrCallback callback, Pointer context);
	void flib_netconn_onChat(JnaFrontlib.NetconnPtr conn, JnaFrontlib.StrStrCallback callback, Pointer context);
	void flib_netconn_onConnected(JnaFrontlib.NetconnPtr conn, JnaFrontlib.VoidCallback callback, Pointer context);
	void flib_netconn_onDisconnected(JnaFrontlib.NetconnPtr conn, JnaFrontlib.IntStrCallback callback, Pointer context);
	void flib_netconn_onRoomAdd(JnaFrontlib.NetconnPtr conn, JnaFrontlib.RoomCallback callback, Pointer context);
	void flib_netconn_onRoomDelete(JnaFrontlib.NetconnPtr conn, JnaFrontlib.StrCallback callback, Pointer context);
	void flib_netconn_onRoomUpdate(JnaFrontlib.NetconnPtr conn, JnaFrontlib.StrRoomCallback callback, Pointer context);
	void flib_netconn_onLobbyJoin(JnaFrontlib.NetconnPtr conn, JnaFrontlib.StrCallback callback, Pointer context);
	void flib_netconn_onLobbyLeave(JnaFrontlib.NetconnPtr conn, JnaFrontlib.StrStrCallback callback, Pointer context);
	void flib_netconn_onNickTaken(JnaFrontlib.NetconnPtr conn, JnaFrontlib.StrCallback callback, Pointer context);
	void flib_netconn_onPasswordRequest(JnaFrontlib.NetconnPtr conn, JnaFrontlib.StrCallback callback, Pointer context);
	void flib_netconn_onEnterRoom(JnaFrontlib.NetconnPtr conn, JnaFrontlib.BoolCallback callback, Pointer context);
	void flib_netconn_onRoomChiefStatus(JnaFrontlib.NetconnPtr conn, JnaFrontlib.BoolCallback callback, Pointer context);
	void flib_netconn_onReadyState(JnaFrontlib.NetconnPtr conn, JnaFrontlib.StrBoolCallback callback, Pointer context);
	void flib_netconn_onLeaveRoom(JnaFrontlib.NetconnPtr conn, JnaFrontlib.IntStrCallback callback, Pointer context);
	void flib_netconn_onTeamAdd(JnaFrontlib.NetconnPtr conn, JnaFrontlib.TeamCallback callback, Pointer context);
	void flib_netconn_onTeamDelete(JnaFrontlib.NetconnPtr conn, JnaFrontlib.StrCallback callback, Pointer context);
	void flib_netconn_onRoomJoin(JnaFrontlib.NetconnPtr conn, JnaFrontlib.StrCallback callback, Pointer context);
	void flib_netconn_onRoomLeave(JnaFrontlib.NetconnPtr conn, JnaFrontlib.StrStrCallback callback, Pointer context);
	void flib_netconn_onRunGame(JnaFrontlib.NetconnPtr conn, JnaFrontlib.VoidCallback callback, Pointer context);
	void flib_netconn_onTeamAccepted(JnaFrontlib.NetconnPtr conn, JnaFrontlib.StrCallback callback, Pointer context);
	void flib_netconn_onHogCountChanged(JnaFrontlib.NetconnPtr conn, JnaFrontlib.StrIntCallback callback, Pointer context);
	void flib_netconn_onTeamColorChanged(JnaFrontlib.NetconnPtr conn, JnaFrontlib.StrIntCallback callback, Pointer context);
	void flib_netconn_onEngineMessage(JnaFrontlib.NetconnPtr conn, JnaFrontlib.BytesCallback callback, Pointer context);
	void flib_netconn_onCfgScheme(JnaFrontlib.NetconnPtr conn, JnaFrontlib.SchemeCallback callback, Pointer context);
	void flib_netconn_onMapChanged(JnaFrontlib.NetconnPtr conn, JnaFrontlib.MapIntCallback callback, Pointer context);
	void flib_netconn_onScriptChanged(JnaFrontlib.NetconnPtr conn, JnaFrontlib.StrCallback callback, Pointer context);
	void flib_netconn_onWeaponsetChanged(JnaFrontlib.NetconnPtr conn, JnaFrontlib.WeaponsetCallback callback, Pointer context);
	void flib_netconn_onAdminAccess(JnaFrontlib.NetconnPtr conn, JnaFrontlib.VoidCallback callback, Pointer context);
	void flib_netconn_onServerVar(JnaFrontlib.NetconnPtr conn, JnaFrontlib.StrStrCallback callback, Pointer context);

	// Gameconn
	JnaFrontlib.GameconnPtr flib_gameconn_create(String playerName, JnaFrontlib.GameSetupPtr setup, boolean netgame);
	JnaFrontlib.GameconnPtr flib_gameconn_create_playdemo(Buffer demo, NativeLong size);
	JnaFrontlib.GameconnPtr flib_gameconn_create_loadgame(String playerName, Buffer save, NativeLong size);
	JnaFrontlib.GameconnPtr flib_gameconn_create_campaign(String playerName, String seed, String script);

	void flib_gameconn_destroy(JnaFrontlib.GameconnPtr conn);
	int flib_gameconn_getport(JnaFrontlib.GameconnPtr conn);
	void flib_gameconn_tick(JnaFrontlib.GameconnPtr conn);

	int flib_gameconn_send_enginemsg(JnaFrontlib.GameconnPtr conn, Buffer data, NativeLong len);
	int flib_gameconn_send_textmsg(JnaFrontlib.GameconnPtr conn, int msgtype, String msg);
	int flib_gameconn_send_chatmsg(JnaFrontlib.GameconnPtr conn, String playername, String msg);
	
	void flib_gameconn_onConnect(JnaFrontlib.GameconnPtr conn, JnaFrontlib.VoidCallback callback, Pointer context);
	void flib_gameconn_onDisconnect(JnaFrontlib.GameconnPtr conn, JnaFrontlib.IntCallback callback, Pointer context);
	void flib_gameconn_onErrorMessage(JnaFrontlib.GameconnPtr conn, JnaFrontlib.StrCallback callback, Pointer context);
	void flib_gameconn_onChat(JnaFrontlib.GameconnPtr conn, JnaFrontlib.StrBoolCallback callback, Pointer context);
	void flib_gameconn_onGameRecorded(JnaFrontlib.GameconnPtr conn, JnaFrontlib.BytesBoolCallback callback, Pointer context);
	void flib_gameconn_onEngineMessage(JnaFrontlib.GameconnPtr conn, JnaFrontlib.BytesCallback callback, Pointer context);
	
	// MapConn
	JnaFrontlib.MapconnPtr flib_mapconn_create(JnaFrontlib.MapRecipePtr mapdesc);
	void flib_mapconn_destroy(JnaFrontlib.MapconnPtr conn);
	int flib_mapconn_getport(JnaFrontlib.MapconnPtr conn);
	void flib_mapconn_onSuccess(JnaFrontlib.MapconnPtr conn, JnaFrontlib.MapimageCallback callback, Pointer context);
	void flib_mapconn_onFailure(JnaFrontlib.MapconnPtr conn, JnaFrontlib.StrCallback callback, Pointer context);
	void flib_mapconn_tick(JnaFrontlib.MapconnPtr conn);
	
	// GameSetup
	void flib_gamesetup_destroy(JnaFrontlib.GameSetupPtr gamesetup);
	JnaFrontlib.GameSetupPtr flib_gamesetup_copy(JnaFrontlib.GameSetupPtr gamesetup);
	
	// MapRecipe
	public static final int MAPGEN_REGULAR = 0;
	public static final int MAPGEN_MAZE = 1;
	public static final int MAPGEN_DRAWN = 2;
	public static final int MAPGEN_NAMED = 3;

	public static final int TEMPLATEFILTER_ALL = 0;
	public static final int TEMPLATEFILTER_SMALL = 1;
	public static final int TEMPLATEFILTER_MEDIUM = 2;
	public static final int TEMPLATEFILTER_LARGE = 3;
	public static final int TEMPLATEFILTER_CAVERN = 4;
	public static final int TEMPLATEFILTER_WACKY = 5;

	public static final int MAZE_SIZE_SMALL_TUNNELS = 0;
	public static final int MAZE_SIZE_MEDIUM_TUNNELS = 1;
	public static final int MAZE_SIZE_LARGE_TUNNELS = 2;
	public static final int MAZE_SIZE_SMALL_ISLANDS = 3;
	public static final int MAZE_SIZE_MEDIUM_ISLANDS = 4;
	public static final int MAZE_SIZE_LARGE_ISLANDS = 5;
	
	JnaFrontlib.MapRecipePtr flib_map_create_regular(String seed, String theme, int templateFilter);
	JnaFrontlib.MapRecipePtr flib_map_create_maze(String seed, String theme, int mazeSize);
	JnaFrontlib.MapRecipePtr flib_map_create_named(String seed, String name);
	JnaFrontlib.MapRecipePtr flib_map_create_drawn(String seed, String theme, Buffer drawData, NativeLong drawDataSize);
	JnaFrontlib.MapRecipePtr flib_map_copy(JnaFrontlib.MapRecipePtr map);
	JnaFrontlib.MapRecipePtr flib_map_retain(JnaFrontlib.MapRecipePtr map);
	void flib_map_release(JnaFrontlib.MapRecipePtr map);
	
	// Metascheme
	JnaFrontlib.MetaschemePtr flib_metascheme_from_ini(String filename);
	JnaFrontlib.MetaschemePtr flib_metascheme_retain(JnaFrontlib.MetaschemePtr metainfo);
	void flib_metascheme_release(JnaFrontlib.MetaschemePtr metainfo);
	
    void flib_log_setLevel(int level);
}