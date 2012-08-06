package org.hedgewars.hedgeroid.frontlib;
import java.nio.Buffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.hedgewars.hedgeroid.Datastructures.Hog;
import org.hedgewars.hedgeroid.Datastructures.MetaScheme;
import org.hedgewars.hedgeroid.Datastructures.MetaScheme.Mod;
import org.hedgewars.hedgeroid.Datastructures.MetaScheme.Setting;
import org.hedgewars.hedgeroid.Datastructures.RoomlistRoom;
import org.hedgewars.hedgeroid.Datastructures.Scheme;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.Datastructures.TeamIngameAttributes;
import org.hedgewars.hedgeroid.EngineProtocol.GameConfig;

import com.sun.jna.Callback;
import com.sun.jna.Library;
import com.sun.jna.Memory;
import com.sun.jna.NativeLong;
import com.sun.jna.Pointer;
import com.sun.jna.PointerType;
import com.sun.jna.Structure;

public interface Frontlib extends Library {
	static final int NATIVE_INT_SIZE = 4;
	static final int NATIVE_BOOL_SIZE = 1;
	
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
	
	static final int GAME_END_FINISHED = 0;
	static final int GAME_END_INTERRUPTED = 1;
	static final int GAME_END_HALTED = 2;
	static final int GAME_END_ERROR = 3;
	
	static final int HEDGEHOGS_PER_TEAM = 8;
	
	public static class NetconnPtr extends PointerType { }
	public static class MapconnPtr extends PointerType { }
	public static class GameconnPtr extends PointerType { }
	public static class MetaschemePtr extends PointerType { }
	
	public static class RoomArrayPtr extends PointerType { 
		/**
		 * Returns the (native-owned) rooms in this list
		 */
		public RoomlistRoom[] getRooms(int count) {
			Pointer ptr = getPointer();
			if(ptr == null) {
				return new RoomlistRoom[0];
			}
			Pointer[] untypedPtrs = ptr.getPointerArray(0, count);
			RoomlistRoom[] result = new RoomlistRoom[count];
			for(int i=0; i<count; i++) {
				result[i] = RoomPtr.deref(untypedPtrs[i]);
			}
			return result;
		}
	}
	
	public static class RoomPtr extends PointerType {
		public RoomPtr() { super(); }
		public RoomPtr(Pointer ptr) { super(ptr); }
		
		public RoomlistRoom deref() {
			return deref(getPointer());
		}
		
		public static RoomlistRoom deref(Pointer p) {
			RoomStruct r = new RoomStruct(p);
			r.read();
			return new RoomlistRoom(r.name, r.map, r.scheme, r.weapons, r.owner, r.playerCount, r.teamCount, r.inProgress);
		}
	}
	
	public static class TeamPtr extends PointerType {
		public TeamInGame deref() {
			return deref(getPointer());
		}
		
		public static TeamInGame deref(Pointer p) {
			TeamStruct ts = new TeamStruct(p);
			ts.read();
			List<Hog> hogs = new ArrayList<Hog>();
			for(int i=0; i<ts.hogs.length; i++) {
				HogStruct hog = ts.hogs[i];
				hogs.add(new Hog(hog.name, hog.hat, hog.difficulty));
			}
			Team team = new Team(ts.name, ts.grave, ts.flag, ts.voicepack, ts.fort, hogs);
			TeamIngameAttributes attrs = new TeamIngameAttributes(ts.ownerName, ts.colorIndex, ts.hogsInGame, ts.remoteDriven);
			return new TeamInGame(team, attrs);
		}

		public static TeamPtr createJavaOwned(Team t) {
			return createJavaOwned(new TeamInGame(t, null));
		}
		
		public static TeamPtr createJavaOwned(TeamInGame ingameTeam) {
			TeamStruct ts = TeamStruct.from(ingameTeam.team, ingameTeam.ingameAttribs);
			ts.write();
			TeamPtr result = new TeamPtr();
			result.setPointer(ts.getPointer());
			return result;
		}
	}
	
	public static class WeaponsetPtr extends PointerType { }
	public static class MapRecipePtr extends PointerType { }
	public static class SchemePtr extends PointerType { }
	public static class SchemelistPtr extends PointerType {
		private SchemelistStruct javaOwnedInstance;
		
		public List<Scheme> deref() {
			return deref(getPointer());
		}
		
		public static List<Scheme> deref(Pointer p) {
			SchemelistStruct sls = new SchemelistStruct(p);
			sls.read();
			return sls.toSchemeList();
		}
		
		public static SchemelistPtr createJavaOwned(List<Scheme> schemes) {
			SchemelistPtr result = new SchemelistPtr();
			result.javaOwnedInstance = new SchemelistStruct();
			result.javaOwnedInstance.fillFrom(schemes);
			result.javaOwnedInstance.autoWrite();
			result.setPointer(result.javaOwnedInstance.getPointer());
			return result;
		}
	}
	
	public static class GameSetupPtr extends PointerType {
		public static GameSetupPtr createJavaOwned(GameConfig conf) {
			GameSetupStruct gss = GameSetupStruct.from(conf);
			gss.write();
			GameSetupPtr result = new GameSetupPtr();
			result.setPointer(gss.getPointer());
			return result;
		}
	}
	
	static class HogStruct extends Structure {
		public static class ByVal extends HogStruct implements Structure.ByValue {}
		public static class ByRef extends HogStruct implements Structure.ByReference {}
		private static String[] FIELD_ORDER = new String[] {"name", "hat", "rounds", "kills", "deaths", "suicides", "difficulty", "initialHealth", "weaponset"};

		public HogStruct() { super(); setFieldOrder(FIELD_ORDER); }
		public HogStruct(Pointer ptr) { super(ptr); setFieldOrder(FIELD_ORDER); }
		
		public static HogStruct from(Hog hog) {
			HogStruct hs = new HogStruct();
			hs.difficulty = hog.level;
			hs.hat = hog.hat;
			hs.name = hog.name;
			// TODO weaponset
			// TODO initialHealth
			return hs;
		}
		
		public String name;
		public String hat;
		
		public int rounds;
		public int kills;
		public int deaths;
		public int suicides;
	
		public int difficulty;
		
		public int initialHealth;
		public WeaponsetPtr weaponset;
	}
	
	static class TeamStruct extends Structure {
		public static class ByVal extends TeamStruct implements Structure.ByValue {}
		public static class ByRef extends TeamStruct implements Structure.ByReference {}
		private static String[] FIELD_ORDER = new String[] {"hogs", "name", "grave", "fort", "voicepack", "flag", "bindings", "bindingCount", "rounds", "wins", "campaignProgress", "colorIndex", "hogsInGame", "remoteDriven", "ownerName"};

		public TeamStruct() { super(); setFieldOrder(FIELD_ORDER); }
		public TeamStruct(Pointer ptr) { super(ptr); setFieldOrder(FIELD_ORDER); }
		
		public static TeamStruct from(Team team, TeamIngameAttributes attrs) {
			TeamStruct ts = new TeamStruct();
			if(team != null) {
				ts.name = team.name;
				ts.grave = team.grave;
				ts.flag = team.flag;
				ts.voicepack = team.voice;
				ts.fort = team.fort;
				if(team.hogs.size() != HEDGEHOGS_PER_TEAM) {
					throw new IllegalArgumentException();
				}
				for(int i=0; i<ts.hogs.length; i++) {
					ts.hogs[i] = HogStruct.from(team.hogs.get(i));
				}
			}
			
			if(attrs != null) {
				ts.hogsInGame = attrs.hogCount;
				ts.ownerName = attrs.ownerName;
				ts.colorIndex = attrs.colorIndex;
				ts.remoteDriven = attrs.remoteDriven;
			}
			return ts;
		}
		
		public HogStruct[] hogs = new HogStruct[HEDGEHOGS_PER_TEAM];
		public String name;
		public String grave;
		public String fort;
		public String voicepack;
		public String flag;
		
		public Pointer bindings;
		public int bindingCount;
		
		public int rounds;
		public int wins;
		public int campaignProgress;
		
		public int colorIndex;
		public int hogsInGame;
		public boolean remoteDriven;
		public String ownerName;
	}
	
	static class RoomStruct extends Structure {
		public static class ByVal extends RoomStruct implements Structure.ByValue {}
		public static class ByRef extends RoomStruct implements Structure.ByReference {}
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
	
	static class MapRecipeStruct extends Structure {
		public static class ByVal extends MapRecipeStruct implements Structure.ByValue {}
		public static class ByRef extends MapRecipeStruct implements Structure.ByReference {}
		private static String[] FIELD_ORDER = new String[] {"_referenceCount", "mapgen", "name", "seed", "theme", "drawData", "drawDataSize", "templateFilter", "mazeSize"};
		
		public MapRecipeStruct() { super(); setFieldOrder(FIELD_ORDER); }
		public MapRecipeStruct(Pointer ptr) { super(ptr); setFieldOrder(FIELD_ORDER); }
		
		public int _referenceCount;
		public int mapgen;
		public String name;
		public String seed;
		public String theme;
		public Pointer drawData;
		public int drawDataSize;
		public int templateFilter;
		public int mazeSize;
	}
	
	static class MetaschemeSettingStruct extends Structure {
		public static class ByVal extends MetaschemeSettingStruct implements Structure.ByValue {}
		public static class ByRef extends MetaschemeSettingStruct implements Structure.ByReference {}
		private static String[] FIELD_ORDER = new String[] {"name", "engineCommand", "maxMeansInfinity", "times1000", "min", "max", "def"};
		
		public MetaschemeSettingStruct() { super(); setFieldOrder(FIELD_ORDER); }
		public MetaschemeSettingStruct(Pointer ptr) { super(ptr); setFieldOrder(FIELD_ORDER); }
		
		public void fillFrom(Setting setting) {
			name = setting.name;
			engineCommand = setting.engineCommand;
			maxMeansInfinity = setting.maxMeansInfinity;
			times1000 = setting.times1000;
			min = setting.min;
			max = setting.max;
			def = setting.def;
		}
		
		public MetaScheme.Setting toMetaSchemeSetting() {
			return new MetaScheme.Setting(name, engineCommand, maxMeansInfinity, times1000, min, max, def);
		}
		
		public String name;
		public String engineCommand;
		public boolean maxMeansInfinity;
		public boolean times1000;
		public int min;
		public int max;
		public int def;
	}
	
	static class MetaschemeModStruct extends Structure {
		public static class ByVal extends MetaschemeModStruct implements Structure.ByValue {}
		public static class ByRef extends MetaschemeModStruct implements Structure.ByReference {}
		private static String[] FIELD_ORDER = new String[] {"name", "bitmaskIndex"};
		
		public MetaschemeModStruct() { super(); setFieldOrder(FIELD_ORDER); }
		public MetaschemeModStruct(Pointer ptr) { super(ptr); setFieldOrder(FIELD_ORDER); }
		
		public void fillFrom(Mod mod) {
			name = mod.name;
			bitmaskIndex = mod.bitmaskIndex;
		}
		
		public MetaScheme.Mod toMetaSchemeMod() {
			return new MetaScheme.Mod(name, bitmaskIndex);
		}

		public String name;
		public int bitmaskIndex;

	}
	
	static class MetaschemeStruct extends Structure {
		public static class ByVal extends MetaschemeStruct implements Structure.ByValue {}
		public static class ByRef extends MetaschemeStruct implements Structure.ByReference {}

		private static String[] FIELD_ORDER = new String[] {"_referenceCount", "settingCount", "modCount", "settings", "mods"};
		
		public MetaschemeStruct() { super(); setFieldOrder(FIELD_ORDER); }
		public MetaschemeStruct(Pointer ptr) { super(ptr); setFieldOrder(FIELD_ORDER); }
		
		public void fillFrom(MetaScheme metascheme) {
			settingCount = metascheme.settings.size();
			modCount = metascheme.mods.size();
			
			settings = new MetaschemeSettingStruct.ByRef();
			Structure[] settingStructs = settings.toArray(settingCount);
			mods = new MetaschemeModStruct.ByRef();
			Structure[] modStructs = mods.toArray(modCount);
			
			for(int i=0; i<settingCount; i++) {
				MetaschemeSettingStruct mss = (MetaschemeSettingStruct)settingStructs[i];
				mss.fillFrom(metascheme.settings.get(i));
			}
			
			for(int i=0; i<modCount; i++) {
				MetaschemeModStruct mms = (MetaschemeModStruct)modStructs[i];
				mms.fillFrom(metascheme.mods.get(i));
			}
		}
		
		/**
		 * Only use on native-owned structs!
		 * Calling this method on a Java-owned struct could cause garbage collection of referenced
		 * structures.
		 */
		public MetaScheme toMetaScheme() {
			List<MetaScheme.Setting> settingList = new ArrayList<MetaScheme.Setting>(settingCount);
			List<MetaScheme.Mod> modList = new ArrayList<MetaScheme.Mod>(modCount);
			
			Structure[] settingStructs = settings.toArray(settingCount);
			Structure[] modStructs = mods.toArray(modCount);
			
			for(int i=0; i<settingCount; i++) {
				MetaschemeSettingStruct mss = (MetaschemeSettingStruct)settingStructs[i];
				settingList.add(mss.toMetaSchemeSetting());
			}
			
			for(int i=0; i<modCount; i++) {
				MetaschemeModStruct mms = (MetaschemeModStruct)modStructs[i];
				modList.add(mms.toMetaSchemeMod());
			}
			
			return new MetaScheme(modList, settingList);
		}
		
		public int _referenceCount;
		public int settingCount;
		public int modCount;
		public MetaschemeSettingStruct.ByRef settings;
		public MetaschemeModStruct.ByRef mods;
	}
	
	static class SchemeStruct extends Structure {
		public static class ByVal extends SchemeStruct implements Structure.ByValue {}
		public static class ByRef extends SchemeStruct implements Structure.ByReference {}
		private static String[] FIELD_ORDER = new String[] {"_referenceCount", "meta", "name", "settings", "mod"};
		
		public SchemeStruct() { super(); setFieldOrder(FIELD_ORDER); }
		public SchemeStruct(Pointer ptr) { super(ptr); setFieldOrder(FIELD_ORDER); }
		
		public void fillFrom(Scheme scheme) {
			meta = new MetaschemeStruct.ByRef();
			meta.fillFrom(scheme.metascheme);
			name = scheme.name;
			settings = new Memory(NATIVE_INT_SIZE * scheme.metascheme.settings.size());
			for(int i=0; i<scheme.metascheme.settings.size(); i++) {
				Integer value = scheme.settings.get(scheme.metascheme.settings.get(i).name);
				settings.setInt(NATIVE_INT_SIZE*i, value);
			}
			mods = new Memory(NATIVE_BOOL_SIZE * scheme.metascheme.mods.size());
			for(int i=0; i<scheme.metascheme.mods.size(); i++) {
				Boolean value = scheme.mods.get(scheme.metascheme.mods.get(i).name);
				mods.setByte(NATIVE_BOOL_SIZE*i, (byte)(value ? 1 : 0));
			}
		}

		public Scheme toScheme() {
			MetaScheme metaScheme = meta.toMetaScheme();
			Map<String, Integer> settingsMap = new HashMap<String, Integer>();
			for(int i=0; i<metaScheme.settings.size(); i++) {
				settingsMap.put(metaScheme.settings.get(i).name, settings.getInt(NATIVE_INT_SIZE*i));
			}
			Map<String, Boolean> modsMap = new HashMap<String, Boolean>();
			for(int i=0; i<metaScheme.mods.size(); i++) {
				modsMap.put(metaScheme.mods.get(i).name, mods.getByte(i) != 0 ? Boolean.TRUE : Boolean.FALSE);
			}
			return new Scheme(metaScheme, name, settingsMap, modsMap);
		}
		
		public int _referenceCount;
		public MetaschemeStruct.ByRef meta;
		public String name;
		public Pointer settings;
		public Pointer mods;
	}
	
	/**
	 * Represents a flib_scheme*, for use as part of a flib_scheme**
	 */
	static class SchemePointerByReference extends Structure implements Structure.ByReference {
		private static String[] FIELD_ORDER = new String[] {"scheme"};
		
		public SchemePointerByReference() { super(); setFieldOrder(FIELD_ORDER); }
		public SchemePointerByReference(Pointer ptr) { super(ptr); setFieldOrder(FIELD_ORDER); }
		
		public SchemeStruct.ByRef scheme;
	}
	
	static class SchemelistStruct extends Structure {
		public static class ByVal extends SchemelistStruct implements Structure.ByValue {}
		public static class ByRef extends SchemelistStruct implements Structure.ByReference {}
		private static String[] FIELD_ORDER = new String[] {"schemeCount", "schemes"};
		
		public SchemelistStruct() { super(); setFieldOrder(FIELD_ORDER); }
		public SchemelistStruct(Pointer ptr) { super(ptr); setFieldOrder(FIELD_ORDER); }
		
		/**
		 * Only use on native-owned structs!
		 * Calling this method on a Java-owned struct could cause garbage collection of referenced
		 * structures.
		 */
		public List<Scheme> toSchemeList() {
			if(schemeCount<=0) {
				return new ArrayList<Scheme>();
			} else {
				List<Scheme> schemeList = new ArrayList<Scheme>(schemeCount);
				
				Structure[] schemePtrStructs = schemes.toArray(schemeCount);
				
				for(int i=0; i<schemeCount; i++) {
					SchemePointerByReference spbr2 = (SchemePointerByReference)schemePtrStructs[i];
					schemeList.add(spbr2.scheme.toScheme());
				}
				return schemeList;
			}
		}
		
		public void fillFrom(List<Scheme> schemeList) {
			schemeCount = schemeList.size();
			schemes = new SchemePointerByReference();
			Structure[] schemePtrStructs = schemes.toArray(schemeCount);
			
			for(int i=0; i<this.schemeCount; i++) {
				SchemePointerByReference spbr = (SchemePointerByReference)schemePtrStructs[i];
				spbr.scheme = new SchemeStruct.ByRef();
				spbr.scheme.fillFrom(schemeList.get(i));
			}
		}
		
		public int schemeCount;
		public SchemePointerByReference schemes;
	}
	
	static class TeamlistStruct extends Structure {
		public static class ByVal extends TeamlistStruct implements Structure.ByValue {}
		public static class ByRef extends TeamlistStruct implements Structure.ByReference {}
		private static String[] FIELD_ORDER = new String[] {"teamCount", "teams"};
		
		public TeamlistStruct() { super(); setFieldOrder(FIELD_ORDER); }
		public TeamlistStruct(Pointer ptr) { super(ptr); setFieldOrder(FIELD_ORDER); }
		
		public int teamCount;
		public Pointer teams;
	}
	
	static class GameSetupStruct extends Structure {
		public static class ByVal extends GameSetupStruct implements Structure.ByValue {}
		public static class ByRef extends GameSetupStruct implements Structure.ByReference {}
		private static String[] FIELD_ORDER = new String[] {"script", "gamescheme", "map", "teamlist"};
		
		public GameSetupStruct() { super(); setFieldOrder(FIELD_ORDER); }
		public GameSetupStruct(Pointer ptr) { super(ptr); setFieldOrder(FIELD_ORDER); }
		
		public static GameSetupStruct from(GameConfig conf) {
			GameSetupStruct gss = new GameSetupStruct();
			gss.gamescheme = new SchemeStruct.ByRef();
			gss.gamescheme.fillFrom(conf.scheme);
			gss.map = new MapRecipeStruct.ByRef();
			// TODO gss.map.fillFrom(conf.map, conf.seed, conf.theme);
			gss.script = conf.style;
			gss.teamlist = new TeamlistStruct.ByRef();
			// TODO gss.teamlist.fillFrom(conf.teams, conf.weapon);
			return gss;
		}

		public String script;
		public SchemeStruct.ByRef gamescheme;
		public MapRecipeStruct.ByRef map;
		public TeamlistStruct.ByRef teamlist;
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

	// Scheme lists
	SchemelistPtr flib_schemelist_from_ini(MetaschemePtr meta, String filename);
	int flib_schemelist_to_ini(String filename, SchemelistPtr list);
	void flib_schemelist_destroy(SchemelistPtr list);
	
	// Team
	void flib_team_destroy(TeamPtr team);
	TeamPtr flib_team_from_ini(String filename);
	int flib_team_to_ini(String filename, TeamPtr team);
	void flib_team_set_weaponset(TeamPtr team, WeaponsetPtr set);
	void flib_team_set_health(TeamPtr team, int health);
	
	// Logging
	public static final int FLIB_LOGLEVEL_ALL = -100;
	public static final int FLIB_LOGLEVEL_DEBUG = -1;
	public static final int FLIB_LOGLEVEL_INFO = 0;
	public static final int FLIB_LOGLEVEL_WARNING = 1;
	public static final int FLIB_LOGLEVEL_ERROR = 2;
	public static final int FLIB_LOGLEVEL_NONE = 100;
	
    void flib_log_setLevel(int level);
    void flib_log_setCallback(LogCallback callback);
}