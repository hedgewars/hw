package org.hedgewars.hedgeroid.netplay;
import java.nio.Buffer;
import java.util.Collections;

import android.util.Log;

import com.sun.jna.Callback;
import com.sun.jna.Library;
import com.sun.jna.Native;
import com.sun.jna.NativeLong;
import com.sun.jna.Pointer;
import com.sun.jna.PointerType;
import com.sun.jna.Structure;

class Flib {
	static {
		System.loadLibrary("SDL_net");
	}
	public static final JnaFrontlib INSTANCE = (JnaFrontlib)Native.loadLibrary("frontlib", JnaFrontlib.class, Collections.singletonMap(Library.OPTION_TYPE_MAPPER, FrontlibTypeMapper.INSTANCE));
	
	// Hook frontlib logging into Android logging
	private static final JnaFrontlib.LogCallback logCb = new JnaFrontlib.LogCallback() {
		public void callback(int level, String message) {
			if(level >= JnaFrontlib.FLIB_LOGLEVEL_ERROR) {
				Log.e("Frontlib", message);
			} else if(level == JnaFrontlib.FLIB_LOGLEVEL_WARNING){
				Log.w("Frontlib", message);
			} else if(level == JnaFrontlib.FLIB_LOGLEVEL_INFO){
				Log.i("Frontlib", message);
			} else if(level <= JnaFrontlib.FLIB_LOGLEVEL_DEBUG){
				Log.d("Frontlib", message);
			}
		}
	};
	static {
		INSTANCE.flib_log_setLevel(JnaFrontlib.FLIB_LOGLEVEL_WARNING);
		INSTANCE.flib_log_setCallback(logCb);
	}
}

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
	
	static class RoomArrayPtr extends PointerType { 
		/**
		 * Returns the (native-owned) rooms in this list
		 */
		public Room[] getRooms(int count) {
			Pointer ptr = getPointer();
			if(ptr == null) {
				return new Room[0];
			}
			Pointer[] untypedPtrs = ptr.getPointerArray(0, count);
			Room[] result = new Room[count];
			for(int i=0; i<count; i++) {
				result[i] = RoomPtr.deref(untypedPtrs[i]);
			}
			return result;
		}
	}
	
	static class RoomPtr extends PointerType {
		public RoomPtr() { super(); }
		public RoomPtr(Pointer ptr) { super(ptr); }
		
		public Room deref() {
			return deref(getPointer());
		}
		
		public static Room deref(Pointer p) {
			RoomStruct r = new RoomStruct(p);
			r.read();
			return new Room(r.name, r.map, r.scheme, r.weapons, r.owner, r.playerCount, r.teamCount, r.inProgress);
		}
	}
	
	static class TeamPtr extends PointerType { }
	static class WeaponsetPtr extends PointerType { }
	static class MapRecipePtr extends PointerType { }
	static class SchemePtr extends PointerType { }
	static class GameSetupPtr extends PointerType { }
	
	static class RoomStruct extends Structure {
		public static class byVal extends RoomStruct implements Structure.ByValue {}
		public static class byRef extends RoomStruct implements Structure.ByReference {}
		private static String[] FIELD_ORDER = new String[] {"inProgress", "name", "playerCount", "teamCount", "owner", "map", "scheme", "weapons"};
		
		public RoomStruct() { super(); setFieldOrder(FIELD_ORDER); }
		public RoomStruct(Pointer ptr) { super(ptr); setFieldOrder(FIELD_ORDER); }
		
	    public boolean inProgress;
	    public String name;
	    public int playerCount;
	    public int teamCount;
	    public String owner;
	    public String map;
	    public String scheme;
	    public String weapons;
	}
	
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
		void callback(Pointer context, RoomPtr arg1);
	}
	
	public static interface RoomListCallback extends Callback {
		void callback(Pointer context, RoomArrayPtr arg1, int count);
	}
	
	public static interface StrRoomCallback extends Callback {
		void callback(Pointer context, String arg1, RoomPtr arg2);
	}
	
	public static interface BoolCallback extends Callback {
		void callback(Pointer context, boolean arg1);
	}
	
	public static interface StrBoolCallback extends Callback {
		void callback(Pointer context, String arg1, boolean arg2);
	}
	
	public static interface TeamCallback extends Callback {
		void callback(Pointer context, TeamPtr arg1);
	}
	
	public static interface BytesCallback extends Callback {
		void callback(Pointer context, Pointer buffer, NativeLong size);
	}
	
	public static interface BytesBoolCallback extends Callback {
		void callback(Pointer context, Pointer buffer, NativeLong size, boolean arg3);
	}
	
	public static interface SchemeCallback extends Callback {
		void callback(Pointer context, SchemePtr arg1);
	}
	
	public static interface MapIntCallback extends Callback {
		void callback(Pointer context, MapRecipePtr arg1, int arg2);
	}
	
	public static interface WeaponsetCallback extends Callback {
		void callback(Pointer context, WeaponsetPtr arg1);
	}
	
	public static interface MapimageCallback extends Callback {
		void callback(Pointer context, Pointer buffer, int hedgehogCount);
	}
	
	public static interface LogCallback extends Callback {
		void callback(int level, String logMessage);
	}
	
    int flib_init();
    void flib_quit();
	
	NetconnPtr flib_netconn_create(String playerName, MetaschemePtr meta, String dataDirPath, String host, int port);
	void flib_netconn_destroy(NetconnPtr conn);

	void flib_netconn_tick(NetconnPtr conn);
	boolean flib_netconn_is_chief(NetconnPtr conn);
	boolean flib_netconn_is_in_room_context(NetconnPtr conn);
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
	int flib_netconn_send_engineMessage(NetconnPtr conn, Buffer message, NativeLong size); // TODO check if NativeLong==size_t
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
	int flib_netconn_send_mapDrawdata(NetconnPtr conn, Buffer drawData, NativeLong size);
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
	void flib_netconn_onRoomChiefStatus(NetconnPtr conn, BoolCallback callback, Pointer context);
	void flib_netconn_onReadyState(NetconnPtr conn, StrBoolCallback callback, Pointer context);
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
	void flib_netconn_onCfgScheme(NetconnPtr conn, SchemeCallback callback, Pointer context);
	void flib_netconn_onMapChanged(NetconnPtr conn, MapIntCallback callback, Pointer context);
	void flib_netconn_onScriptChanged(NetconnPtr conn, StrCallback callback, Pointer context);
	void flib_netconn_onWeaponsetChanged(NetconnPtr conn, WeaponsetCallback callback, Pointer context);
	void flib_netconn_onAdminAccess(NetconnPtr conn, VoidCallback callback, Pointer context);
	void flib_netconn_onServerVar(NetconnPtr conn, StrStrCallback callback, Pointer context);

	// Gameconn
	GameconnPtr flib_gameconn_create(String playerName, GameSetupPtr setup, boolean netgame);
	GameconnPtr flib_gameconn_create_playdemo(Buffer demo, NativeLong size);
	GameconnPtr flib_gameconn_create_loadgame(String playerName, Buffer save, NativeLong size);
	GameconnPtr flib_gameconn_create_campaign(String playerName, String seed, String script);

	void flib_gameconn_destroy(GameconnPtr conn);
	int flib_gameconn_getport(GameconnPtr conn);
	void flib_gameconn_tick(GameconnPtr conn);

	int flib_gameconn_send_enginemsg(GameconnPtr conn, Buffer data, NativeLong len);
	int flib_gameconn_send_textmsg(GameconnPtr conn, int msgtype, String msg);
	int flib_gameconn_send_chatmsg(GameconnPtr conn, String playername, String msg);
	
	void flib_gameconn_onConnect(GameconnPtr conn, VoidCallback callback, Pointer context);
	void flib_gameconn_onDisconnect(GameconnPtr conn, IntCallback callback, Pointer context);
	void flib_gameconn_onErrorMessage(GameconnPtr conn, StrCallback callback, Pointer context);
	void flib_gameconn_onChat(GameconnPtr conn, StrBoolCallback callback, Pointer context);
	void flib_gameconn_onGameRecorded(GameconnPtr conn, BytesBoolCallback callback, Pointer context);
	void flib_gameconn_onEngineMessage(GameconnPtr conn, BytesCallback callback, Pointer context);
	
	// MapConn
	MapconnPtr flib_mapconn_create(MapRecipePtr mapdesc);
	void flib_mapconn_destroy(MapconnPtr conn);
	int flib_mapconn_getport(MapconnPtr conn);
	void flib_mapconn_onSuccess(MapconnPtr conn, MapimageCallback callback, Pointer context);
	void flib_mapconn_onFailure(MapconnPtr conn, StrCallback callback, Pointer context);
	void flib_mapconn_tick(MapconnPtr conn);
	
	// GameSetup
	void flib_gamesetup_destroy(GameSetupPtr gamesetup);
	GameSetupPtr flib_gamesetup_copy(GameSetupPtr gamesetup);
	
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
	
	MapRecipePtr flib_map_create_regular(String seed, String theme, int templateFilter);
	MapRecipePtr flib_map_create_maze(String seed, String theme, int mazeSize);
	MapRecipePtr flib_map_create_named(String seed, String name);
	MapRecipePtr flib_map_create_drawn(String seed, String theme, Buffer drawData, NativeLong drawDataSize);
	MapRecipePtr flib_map_copy(MapRecipePtr map);
	MapRecipePtr flib_map_retain(MapRecipePtr map);
	void flib_map_release(MapRecipePtr map);
	
	// Metascheme
	MetaschemePtr flib_metascheme_from_ini(String filename);
	MetaschemePtr flib_metascheme_retain(MetaschemePtr metainfo);
	void flib_metascheme_release(MetaschemePtr metainfo);
	
	public static final int FLIB_LOGLEVEL_ALL = -100;
	public static final int FLIB_LOGLEVEL_DEBUG = -1;
	public static final int FLIB_LOGLEVEL_INFO = 0;
	public static final int FLIB_LOGLEVEL_WARNING = 1;
	public static final int FLIB_LOGLEVEL_ERROR = 2;
	public static final int FLIB_LOGLEVEL_NONE = 100;
	
    void flib_log_setLevel(int level);
    void flib_log_setCallback(LogCallback callback);
}