/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
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


package org.hedgewars.hedgeroid.frontlib;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.hedgewars.hedgeroid.Datastructures.Hog;
import org.hedgewars.hedgeroid.Datastructures.MapRecipe;
import org.hedgewars.hedgeroid.Datastructures.MetaScheme;
import org.hedgewars.hedgeroid.Datastructures.MetaScheme.Mod;
import org.hedgewars.hedgeroid.Datastructures.MetaScheme.Setting;
import org.hedgewars.hedgeroid.Datastructures.GameConfig;
import org.hedgewars.hedgeroid.Datastructures.Room;
import org.hedgewars.hedgeroid.Datastructures.Scheme;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.Datastructures.TeamIngameAttributes;
import org.hedgewars.hedgeroid.Datastructures.Weaponset;

import com.sun.jna.Callback;
import com.sun.jna.Library;
import com.sun.jna.Memory;
import com.sun.jna.Pointer;
import com.sun.jna.PointerType;
import com.sun.jna.Structure;

/**
 * Here is an introduction to the most important aspects of the JNA code.
 *
 * This interface permits access to the Hedgewars frontend library (frontlib)
 * from Java. Each function directly contained in the Frontlib interface
 * represents a mapped C function. The Structure classes (ending in -Struct) are
 * mappings of C structs, and the PointerType classes (ending in -Ptr) represent
 * pointers to structs.
 *
 * Quick notes for USING these classes from outside this package:
 *
 * Usage should be fairly straightforward, but there are a few surprising
 * gotchas. First, when you implement callbacks, YOU are responsible for
 * ensuring that the callback objects are not garbage-collected while they might
 * still be called! So make sure you keep them in member variables or similar,
 * because Java will not know if there are still native references to them.
 *
 * When using Frontlib from outside its package, you only interact with structs
 * via the PointerType classes. They allow you to get at the data of the struct
 * with a function called deref(), which creates a plain normal Java object
 * representing the data (e.g. SchemePtr.deref() will give you a Scheme object).
 *
 * Remember that you usually have to destroy structs that you receive from the
 * library, because they are owned by the native code, not Java. The recommended
 * pattern for most cases is to call deref() on the pointer to get a Java object
 * (that you can keep as long as you like), and then immediately destroy the
 * struct if it needs destroying. To find out whether and how the struct needs
 * to be destroyed, see the library's documentation of the function that you got
 * the struct from.
 *
 * To pass new structs to the library, you can use the static createJavaOwned()
 * function in each PointerType, which creates a new struct from the Java object
 * you provide, and returns a pointer to that struct that you can pass to
 * library functions. This new structure's memory is owned and managed by Java
 * code, so do not destroy it with frontlib functions!
 *
 * There is a slight mismatch between the data model for the game setup. The
 * frontlib supports setting initial health and weaponset per-hog, because the
 * engine allows for that, but currently neither the networking protocol nor the
 * PC frontend support this feature, so the Android version does not take
 * advantage of it either and treats both as per-game settings. The initial
 * health is contained in the game scheme, the weaponset is explicitly part of
 * the GameConfig. When converting GameConfig to a native flib_gamesetup, both
 * are automatically copied to all hogs in the game, and for the reverse
 * conversion the weaponset of the first hog of the first team is used as the
 * GameConfig weaponset. This means that GameConfig.weaponset will be null if
 * there are no teams in the game.
 *
 * When starting a network game, you only need to query the GameSetupPtr from
 * the netconn and use it to create the gameconn - this is preferable to using
 * your own recreation of the game setup, because that way the same piece of
 * code is used to determine the game setup on all platforms.
 *
 * The "context" parameter of the callbacks is never needed here because JNA
 * generates function code for each callback object. Don't worry about it, just
 * pass null for context and ignore the context parameter in the callbacks.
 *
 * Finally, the library functions are documented in the actual library, not
 * here, so check the docs there to find out what exactly each function does!
 *
 * Notes about the structure of this class (for the next one who has to touch
 * this...):
 *
 * Java/C interop is quite fiddly and error-prone, so as long as things work,
 * try to stick to the established patterns.
 *
 * Structure types should always be hidden from the outside world, because they
 * can be misused too easily. For example, if you get a Structure from the
 * library, change a String value in there and pass it back, JNA will re-write
 * that string using Java-owned memory without freeing the old native-owned
 * string, which causes a memory leak and possibly a double-free or other Bad
 * Things (tm). To avoid problems like this, Structure types are only used
 * internally, to map existing structures to Java types (without modifying them)
 * or to create brand-new, Java-owned structures. Both operations are exposed to
 * the outside through the PointerType classes corresponding to the structures
 * in question.
 *
 * Since all of the struct mapping happens in Java, it is never checked against
 * the actual struct declarations in the library. That means strange things can
 * start happening at runtime if the frontlib structs are modified without
 * changing the mappings here to match. This also applies to the function
 * signatures: JNA checks whether the functions actually exist when loading the
 * library, but it has no way of knowing whether the signatures are correct. If
 * the signatures here deviate from those in the frontlib, you might get stack
 * corruption.
 *
 * In order to check at least the function signatures, take a look at the file
 * extra/jnacontrol.c in the frontlib sources. You can validate whether the
 * function signatures are still correct by copy-pasting them into jnaControl.c
 * and compiling it against the frontlib headers. The typedefs and #defines in
 * that file will make the compiler see the Java method signatures as C function
 * declarations. Since the same functions are already declared in the frontlib
 * headers, the compiler will give you errors if the signatures don't match.
 */
public interface Frontlib extends Library {
    public static class NetconnPtr extends PointerType { }
    public static class MapconnPtr extends PointerType { }
    public static class GameconnPtr extends PointerType { }

    public static class MetaschemePtr extends PointerType {
        public MetaScheme deref() {
            return deref(getPointer());
        }

        public static MetaScheme deref(Pointer p) {
            MetaschemeStruct struct = new MetaschemeStruct(p);
            struct.read();
            return struct.toMetaScheme();
        }
    }

    public static class RoomArrayPtr extends PointerType {
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

    public static class RoomPtr extends PointerType {
        public Room deref() {
            return deref(getPointer());
        }

        public static Room deref(Pointer p) {
            RoomStruct struct = new RoomStruct(p);
            struct.read();
            return struct.toRoomlistRoom();
        }
    }

    public static class TeamPtr extends PointerType {
        private TeamStruct javaOwnedInstance;

        public TeamInGame deref() {
            TeamStruct struct = new TeamStruct(getPointer());
            struct.read();
            return struct.toTeamInGame();
        }

        public static TeamPtr createJavaOwned(Team t) {
            return createJavaOwned(new TeamInGame(t, null));
        }

        public static TeamPtr createJavaOwned(TeamInGame ingameTeam) {
            TeamPtr result = new TeamPtr();
            result.javaOwnedInstance = new TeamStruct();
            result.javaOwnedInstance.fillFrom(ingameTeam.team, ingameTeam.ingameAttribs);
            result.javaOwnedInstance.autoWrite();
            result.setPointer(result.javaOwnedInstance.getPointer());
            return result;
        }
    }

    public static class WeaponsetPtr extends PointerType {
        private WeaponsetStruct javaOwnedInstance;

        public Weaponset deref() {
            WeaponsetStruct struct = new WeaponsetStruct(getPointer());
            struct.read();
            return struct.toWeaponset();
        }

        public static WeaponsetPtr createJavaOwned(Weaponset weaponset) {
            WeaponsetPtr result = new WeaponsetPtr();
            result.javaOwnedInstance = new WeaponsetStruct();
            result.javaOwnedInstance.fillFrom(weaponset);
            result.javaOwnedInstance.autoWrite();
            result.setPointer(result.javaOwnedInstance.getPointer());
            return result;
        }
    }

    public static class WeaponsetListPtr extends PointerType {
        private WeaponsetListStruct javaOwnedInstance;

        public List<Weaponset> deref() {
            WeaponsetListStruct struct = new WeaponsetListStruct(getPointer());
            struct.read();
            return struct.toWeaponsetList();
        }

        public static WeaponsetListPtr createJavaOwned(List<Weaponset> list) {
            WeaponsetListPtr result = new WeaponsetListPtr();
            result.javaOwnedInstance = new WeaponsetListStruct();
            result.javaOwnedInstance.fillFrom(list);
            result.javaOwnedInstance.autoWrite();
            result.setPointer(result.javaOwnedInstance.getPointer());
            return result;
        }
    }

    public static class MapRecipePtr extends PointerType {
        private MapRecipeStruct javaOwnedInstance;

        public MapRecipe deref() {
            MapRecipeStruct struct = new MapRecipeStruct(getPointer());
            struct.read();
            return struct.toMapRecipe();
        }

        public static MapRecipePtr createJavaOwned(MapRecipe recipe) {
            MapRecipePtr result = new MapRecipePtr();
            result.javaOwnedInstance = new MapRecipeStruct();
            result.javaOwnedInstance.fillFrom(recipe);
            result.javaOwnedInstance.autoWrite();
            result.setPointer(result.javaOwnedInstance.getPointer());
            return result;
        }
    }

    public static class SchemePtr extends PointerType {
        private SchemeStruct javaOwnedInstance;

        public Scheme deref() {
            SchemeStruct struct = new SchemeStruct(getPointer());
            struct.read();
            return struct.toScheme();
        }

        public static SchemePtr createJavaOwned(Scheme scheme) {
            SchemePtr result = new SchemePtr();
            result.javaOwnedInstance = new SchemeStruct();
            result.javaOwnedInstance.fillFrom(scheme);
            result.javaOwnedInstance.autoWrite();
            result.setPointer(result.javaOwnedInstance.getPointer());
            return result;
        }
    }

    public static class SchemelistPtr extends PointerType {
        private SchemelistStruct javaOwnedInstance;

        public List<Scheme> deref() {
            SchemelistStruct struct = new SchemelistStruct(getPointer());
            struct.read();
            return struct.toSchemeList();
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
        private GameSetupStruct javaOwnedInstance;

        public GameConfig deref() {
            GameSetupStruct struct = new GameSetupStruct(getPointer());
            struct.read();
            return struct.toGameConfig();
        }

        public static GameSetupPtr createJavaOwned(GameConfig conf) {
            GameSetupPtr result = new GameSetupPtr();
            result.javaOwnedInstance = new GameSetupStruct();
            result.javaOwnedInstance.fillFrom(conf);
            result.javaOwnedInstance.autoWrite();
            result.setPointer(result.javaOwnedInstance.getPointer());
            return result;
        }
    }

    public static class ByteArrayPtr extends PointerType {
        public byte[] deref(int size) {
            return getPointer().getByteArray(0, size);
        }

        public static byte[] deref(ByteArrayPtr ptr, int size) {
            if(ptr==null && size==0) {
                return null;
            } else {
                return ptr.deref(size);
            }
        }

        public static ByteArrayPtr createJavaOwned(byte[] buffer) {
            if(buffer == null || buffer.length == 0) {
                return null;
            }
            // no need for javaOwnedInstance here because PointerType
            // remembers the memory as its Pointer
            Pointer ptr = new Memory(buffer.length);
            ptr.write(0, buffer, 0, buffer.length);
            ByteArrayPtr result = new ByteArrayPtr();
            result.setPointer(ptr);
            return result;
        }
    }

    static class HogStruct extends Structure {
        public static class ByVal extends HogStruct implements Structure.ByValue {}
        public static class ByRef extends HogStruct implements Structure.ByReference {}

        public HogStruct() { super(); }
        public HogStruct(Pointer ptr) { super(ptr); }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("name", "hat", "rounds", "kills", "deaths", "suicides", "difficulty", "initialHealth", "weaponset");
        }

        public void fillFrom(Hog hog) {
            difficulty = hog.level;
            hat = hog.hat;
            name = hog.name;
        }

        public Hog toHog() {
            return new Hog(name, hat, difficulty);
        }

        public String name;
        public String hat;

        public int rounds;
        public int kills;
        public int deaths;
        public int suicides;

        public int difficulty;

        public int initialHealth;
        public WeaponsetStruct.ByRef weaponset;
    }

    static class TeamStruct extends Structure {
        public static class ByVal extends TeamStruct implements Structure.ByValue {}
        public static class ByRef extends TeamStruct implements Structure.ByReference {}

        public TeamStruct() { super(); }
        public TeamStruct(Pointer ptr) { super(ptr); }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("hogs", "name", "grave", "fort", "voicepack", "flag", "bindings", "bindingCount", "rounds", "wins", "campaignProgress", "colorIndex", "hogsInGame", "remoteDriven", "ownerName");
        }

        public void fillFrom(Team team, TeamIngameAttributes attrs) {
            if(team != null) {
                name = team.name;
                grave = team.grave;
                flag = team.flag;
                voicepack = team.voice;
                fort = team.fort;
                if(team.hogs.size() != Team.HEDGEHOGS_PER_TEAM) {
                    throw new IllegalArgumentException();
                }
                for(int i=0; i<hogs.length; i++) {
                    hogs[i] = new HogStruct();
                    hogs[i].fillFrom(team.hogs.get(i));
                }
            }

            if(attrs != null) {
                hogsInGame = attrs.hogCount;
                ownerName = attrs.ownerName;
                colorIndex = attrs.colorIndex;
                remoteDriven = attrs.remoteDriven;
            }
        }

        public void fillFrom(TeamInGame team, WeaponsetStruct.ByRef weaponset, int initialHealth) {
            fillFrom(team.team, team.ingameAttribs);
            for(int i=0; i<hogs.length; i++) {
                hogs[i].initialHealth = initialHealth;
                hogs[i].weaponset = weaponset;
            }
        }

        public Team toTeam() {
            List<Hog> hogList = new ArrayList<Hog>();
            for(int i=0; i<hogs.length; i++) {
                hogList.add(hogs[i].toHog());
            }
            return new Team(name, grave, flag, voicepack, fort, hogList);
        }

        public TeamIngameAttributes toTeamIngameAttributes() {
            return new TeamIngameAttributes(ownerName, colorIndex, hogsInGame, remoteDriven);
        }

        public TeamInGame toTeamInGame() {
            return new TeamInGame(toTeam(), toTeamIngameAttributes());
        }

        public HogStruct[] hogs = new HogStruct[Team.HEDGEHOGS_PER_TEAM];
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

    static class WeaponsetStruct extends Structure {
        public static class ByVal extends WeaponsetStruct implements Structure.ByValue {}
        public static class ByRef extends WeaponsetStruct implements Structure.ByReference {}

        public WeaponsetStruct() { super(); }
        public WeaponsetStruct(Pointer ptr) { super(ptr); }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("loadout", "crateprob", "crateammo", "delay", "name");
        }

        public void fillFrom(Weaponset weaponset) {
            fillWeaponInfo(loadout, weaponset.loadout);
            fillWeaponInfo(crateprob, weaponset.crateProb);
            fillWeaponInfo(crateammo, weaponset.crateAmmo);
            fillWeaponInfo(delay, weaponset.delay);
            name = weaponset.name;
        }

        private static void fillWeaponInfo(byte[] array, String str) {
            for(int i=0; i<array.length-1; i++) {
                array[i] = (byte) (i<str.length() ? str.charAt(i) : '0');
            }
            array[array.length-1] = (byte)0;
        }

        public Weaponset toWeaponset() {
            return new Weaponset(name, weaponInfoToString(loadout), weaponInfoToString(crateprob), weaponInfoToString(crateammo), weaponInfoToString(delay));
        }

        private static String weaponInfoToString(byte[] array) {
            try {
                return new String(array, 0, array.length-1, "ASCII");
            } catch (UnsupportedEncodingException e) {
                throw new AssertionError();
            }
        }

        public byte[] loadout = new byte[Weaponset.WEAPONS_COUNT+1];
        public byte[] crateprob = new byte[Weaponset.WEAPONS_COUNT+1];
        public byte[] crateammo = new byte[Weaponset.WEAPONS_COUNT+1];
        public byte[] delay = new byte[Weaponset.WEAPONS_COUNT+1];
        public String name;
    }

    /**
     * Represents a flib_weaponset*, for use as part of a flib_weaponset**
     */
    static class WeaponsetPointerByReference extends Structure implements Structure.ByReference {
        public WeaponsetPointerByReference() { super(); }
        public WeaponsetPointerByReference(Pointer ptr) { super(ptr); }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("weaponset");
        }

        public WeaponsetStruct.ByRef weaponset;
    }

    static class WeaponsetListStruct extends Structure {
        public static class ByVal extends WeaponsetListStruct implements Structure.ByValue {}
        public static class ByRef extends WeaponsetListStruct implements Structure.ByReference {}

        public WeaponsetListStruct() { super(); }
        public WeaponsetListStruct(Pointer ptr) { super(ptr); }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("weaponsetCount", "weaponsets");
        }

        public void fillFrom(List<Weaponset> list) {
            weaponsetCount = list.size();
            if(weaponsetCount<=0) {
                weaponsets = null;
            } else {
                weaponsets = new WeaponsetPointerByReference();
                Structure[] structs = weaponsets.toArray(weaponsetCount);

                for(int i=0; i<weaponsetCount; i++) {
                    WeaponsetPointerByReference pstruct = (WeaponsetPointerByReference)structs[i];
                    pstruct.weaponset = new WeaponsetStruct.ByRef();
                    pstruct.weaponset.fillFrom(list.get(i));
                }
            }
        }

        /**
         * Only use on native-owned structs!
         * Calling this method on a Java-owned struct could cause garbage collection of referenced
         * structures.
         */
        public List<Weaponset> toWeaponsetList() {
            if(weaponsetCount<=0) {
                return new ArrayList<Weaponset>();
            } else {
                List<Weaponset> list = new ArrayList<Weaponset>(weaponsetCount);
                Structure[] structs = weaponsets.toArray(weaponsetCount);

                for(int i=0; i<weaponsetCount; i++) {
                    WeaponsetPointerByReference pstruct = (WeaponsetPointerByReference)structs[i];
                    list.add(pstruct.weaponset.toWeaponset());
                }
                return list;
            }
        }

        public int weaponsetCount;
        public WeaponsetPointerByReference weaponsets;
    }

    static class RoomStruct extends Structure {
        public static class ByVal extends RoomStruct implements Structure.ByValue {}
        public static class ByRef extends RoomStruct implements Structure.ByReference {}

        public RoomStruct() { super(); }
        public RoomStruct(Pointer ptr) { super(ptr); }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("inProgress", "name", "playerCount", "teamCount", "owner", "map", "scheme", "weapons");
        }

        public Room toRoomlistRoom() {
            return new Room(name, map, scheme, weapons, owner, playerCount, teamCount, inProgress);
        }

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

        public MapRecipeStruct() { super(); }
        public MapRecipeStruct(Pointer ptr) { super(ptr); }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("mapgen", "name", "seed", "theme", "drawData", "drawDataSize", "templateFilter", "mazeSize");
        }

        public void fillFrom(MapRecipe map) {
            mapgen = map.mapgen;
            name = map.name;
            seed = map.seed;
            theme = map.theme;
            byte[] buf = map.getDrawData();
            drawData = ByteArrayPtr.createJavaOwned(buf);
            drawDataSize = NativeSizeT.valueOf(buf==null ? 0 : buf.length);
            templateFilter = map.templateFilter;
            mazeSize = map.mazeSize;
        }

        public MapRecipe toMapRecipe() {
            byte[] buf = ByteArrayPtr.deref(drawData, drawDataSize.intValue());
            return new MapRecipe(mapgen, templateFilter, mazeSize, name, seed, theme, buf);
        }

        public int mapgen;
        public String name;
        public String seed;
        public String theme;
        public ByteArrayPtr drawData;
        public NativeSizeT drawDataSize;
        public int templateFilter;
        public int mazeSize;
    }

    static class MetaschemeSettingStruct extends Structure {
        public static class ByVal extends MetaschemeSettingStruct implements Structure.ByValue {}
        public static class ByRef extends MetaschemeSettingStruct implements Structure.ByReference {}

        public MetaschemeSettingStruct() { super(); }
        public MetaschemeSettingStruct(Pointer ptr) { super(ptr); }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("name", "engineCommand", "maxMeansInfinity", "times1000", "min", "max", "def");
        }

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

        public MetaschemeModStruct() { super(); }
        public MetaschemeModStruct(Pointer ptr) { super(ptr); }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("name", "bitmaskIndex");
        }

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

        public MetaschemeStruct() { super(); }
        public MetaschemeStruct(Pointer ptr) { super(ptr); }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("settingCount", "modCount", "settings", "mods");
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

        public int settingCount;
        public int modCount;
        public MetaschemeSettingStruct.ByRef settings;
        public MetaschemeModStruct.ByRef mods;
    }

    static class SchemeStruct extends Structure {
        public static class ByVal extends SchemeStruct implements Structure.ByValue {}
        public static class ByRef extends SchemeStruct implements Structure.ByReference {}

        public SchemeStruct() { super(); }
        public SchemeStruct(Pointer ptr) { super(ptr); }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("name", "settings", "mods");
        }

        public void fillFrom(Scheme scheme) {
            MetaScheme meta = MetaScheme.INSTANCE;
            name = scheme.name;
            settings = new Memory(AndroidTypeMapper.NATIVE_INT_SIZE * meta.settings.size());
            for(int i=0; i<meta.settings.size(); i++) {
                Integer value = scheme.settings.get(meta.settings.get(i).name);
                settings.setInt(AndroidTypeMapper.NATIVE_INT_SIZE*i, value);
            }
            mods = new Memory(AndroidTypeMapper.NATIVE_BOOL_SIZE * meta.mods.size());
            for(int i=0; i<meta.mods.size(); i++) {
                Boolean value = scheme.mods.get(meta.mods.get(i).name);
                mods.setByte(AndroidTypeMapper.NATIVE_BOOL_SIZE*i, (byte)(value ? 1 : 0));
            }
        }

        public Scheme toScheme() {
            Map<String, Integer> settingsMap = new HashMap<String, Integer>();
            MetaScheme meta = MetaScheme.INSTANCE;
            for(int i=0; i<meta.settings.size(); i++) {
                settingsMap.put(meta.settings.get(i).name, settings.getInt(AndroidTypeMapper.NATIVE_INT_SIZE*i));
            }
            Map<String, Boolean> modsMap = new HashMap<String, Boolean>();
            for(int i=0; i<meta.mods.size(); i++) {
                modsMap.put(meta.mods.get(i).name, mods.getByte(i) != 0 ? Boolean.TRUE : Boolean.FALSE);
            }
            return new Scheme(name, settingsMap, modsMap);
        }

        public String name;
        public Pointer settings;
        public Pointer mods;
    }

    /**
     * Represents a flib_scheme*, for use as part of a flib_scheme**
     */
    static class SchemePointerByReference extends Structure implements Structure.ByReference {
        public SchemePointerByReference() { super(); }
        public SchemePointerByReference(Pointer ptr) { super(ptr); }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("scheme");
        }

        public SchemeStruct.ByRef scheme;
    }

    static class SchemelistStruct extends Structure {
        public static class ByVal extends SchemelistStruct implements Structure.ByValue {}
        public static class ByRef extends SchemelistStruct implements Structure.ByReference {}

        public SchemelistStruct() { super(); }
        public SchemelistStruct(Pointer ptr) { super(ptr); }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("schemeCount", "schemes");
        }

        public void fillFrom(List<Scheme> schemeList) {
            schemeCount = schemeList.size();
            if(schemeCount<=0) {
                schemes = null;
            } else {
                schemes = new SchemePointerByReference();
                Structure[] schemePtrStructs = schemes.toArray(schemeCount);

                for(int i=0; i<this.schemeCount; i++) {
                    SchemePointerByReference spbr = (SchemePointerByReference)schemePtrStructs[i];
                    spbr.scheme = new SchemeStruct.ByRef();
                    spbr.scheme.fillFrom(schemeList.get(i));
                }
            }
        }

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

        public int schemeCount;
        public SchemePointerByReference schemes;
    }

    /**
     * Represents a flib_team*, for use as part of a flib_team**
     */
    static class TeamPointerByReference extends Structure implements Structure.ByReference {
        public TeamPointerByReference() { super(); }
        public TeamPointerByReference(Pointer ptr) { super(ptr); }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("team");
        }

        public TeamStruct.ByRef team;
    }

    static class TeamlistStruct extends Structure {
        public static class ByVal extends TeamlistStruct implements Structure.ByValue {}
        public static class ByRef extends TeamlistStruct implements Structure.ByReference {}

        public TeamlistStruct() { super(); }
        public TeamlistStruct(Pointer ptr) { super(ptr); }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("teamCount", "teams");
        }

        public void fillFrom(List<TeamInGame> teamList, WeaponsetStruct.ByRef weaponset, int initialHealth) {
            teamCount = teamList.size();
            if(teamCount <= 0) {
                teams = null;
            } else {
                teams = new TeamPointerByReference();
                Structure[] teamPtrStructs = teams.toArray(teamCount);

                for(int i=0; i<this.teamCount; i++) {
                    TeamPointerByReference tpbr = (TeamPointerByReference)teamPtrStructs[i];
                    tpbr.team = new TeamStruct.ByRef();
                    tpbr.team.fillFrom(teamList.get(i), weaponset, initialHealth);
                }
            }
        }

        public List<TeamInGame> toTeamInGameList() {
            if(teamCount<=0) {
                return new ArrayList<TeamInGame>();
            } else {
                List<TeamInGame> result = new ArrayList<TeamInGame>(teamCount);
                Structure[] structs = teams.toArray(teamCount);

                for(int i=0; i<teamCount; i++) {
                    TeamPointerByReference struct = (TeamPointerByReference)structs[i];
                    result.add(struct.team.toTeamInGame());
                }
                return result;
            }
        }

        public int teamCount;
        public TeamPointerByReference teams;
    }

    static class GameSetupStruct extends Structure {
        public static class ByVal extends GameSetupStruct implements Structure.ByValue {}
        public static class ByRef extends GameSetupStruct implements Structure.ByReference {}

        public GameSetupStruct() { super(); }
        public GameSetupStruct(Pointer ptr) { super(ptr); }

        @Override
        protected List<String> getFieldOrder() {
            return Arrays.asList("script", "gamescheme", "map", "teamlist");
        }

        public void fillFrom(GameConfig conf) {
            script = conf.style;
            gamescheme = new SchemeStruct.ByRef();
            gamescheme.fillFrom(conf.scheme);
            map = new MapRecipeStruct.ByRef();
            map.fillFrom(conf.map);

            /*
             * At this point we deviate from the usual copying pattern because the frontlib
             * expects per-hog weapons and initial health, but the UI models them as per-
             * game, so we extract them from the config here and pass them on to be included
             * in each hog.
             */
            WeaponsetStruct.ByRef wss = new WeaponsetStruct.ByRef();
            wss.fillFrom(conf.weaponset);
            int initialHealth = conf.scheme.getHealth();

            teamlist = new TeamlistStruct.ByRef();
            teamlist.fillFrom(conf.teams, wss, initialHealth);
        }

        public GameConfig toGameConfig() {
            Scheme scheme = gamescheme != null ? gamescheme.toScheme() : null;
            MapRecipe mapRecipe = map != null ? map.toMapRecipe() : null;
            List<TeamInGame> teams = teamlist != null ? teamlist.toTeamInGameList() : null;

            WeaponsetStruct weaponsetStruct = teamlist != null && teamlist.teamCount>0 ? teamlist.teams.team.hogs[0].weaponset : null;
            Weaponset weaponset = weaponsetStruct != null ? weaponsetStruct.toWeaponset() : null;
            return new GameConfig(script, scheme, mapRecipe, teams, weaponset);
        }

        public String script;
        public SchemeStruct.ByRef gamescheme;
        public MapRecipeStruct.ByRef map;
        public TeamlistStruct.ByRef teamlist;
    }

    /*
     * Callback interfaces. The context parameter is never needed here and
     * should always be ignored. Be sure to keep a reference to each callback
     * for as long as they might be called by native code, to avoid premature
     * garbage collection.
     */
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

    public static interface StrStrBoolCallback extends Callback {
        void callback(Pointer context, String arg1, String arg2, boolean arg3);
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
        void callback(Pointer context, ByteArrayPtr buffer, NativeSizeT size);
    }

    public static interface BytesBoolCallback extends Callback {
        void callback(Pointer context, ByteArrayPtr buffer, NativeSizeT size, boolean arg3);
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
        void callback(Pointer context, ByteArrayPtr buffer, int hedgehogCount);
    }

    public static interface LogCallback extends Callback {
        void callback(int level, String logMessage);
    }

    // frontlib.h
    int flib_init();
    void flib_quit();

    // hwconsts.h
    int flib_get_teamcolor(int colorIndex);
    int flib_get_teamcolor_count();
    int flib_get_hedgehogs_per_team();
    int flib_get_weapons_count();
    MetaschemePtr flib_get_metascheme();

    // net/netconn.h
    static final int NETCONN_STATE_CONNECTING = 0;
    static final int NETCONN_STATE_LOBBY = 1;
    static final int NETCONN_STATE_ROOM = 2;
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
    static final int GAME_END_FINISHED = 0;
    static final int GAME_END_INTERRUPTED = 1;
    static final int GAME_END_HALTED = 2;
    static final int GAME_END_ERROR = 3;

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
    public static final int MAPIMAGE_WIDTH = 256;
    public static final int MAPIMAGE_HEIGHT = 128;
    public static final int MAPIMAGE_BYTES = (MAPIMAGE_WIDTH/8*MAPIMAGE_HEIGHT);

    MapconnPtr flib_mapconn_create(MapRecipePtr mapdesc);
    void flib_mapconn_destroy(MapconnPtr conn);
    int flib_mapconn_getport(MapconnPtr conn);
    void flib_mapconn_onSuccess(MapconnPtr conn, MapimageCallback callback, Pointer context);
    void flib_mapconn_onFailure(MapconnPtr conn, StrCallback callback, Pointer context);
    void flib_mapconn_tick(MapconnPtr conn);

    // model/map.h
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
    public static final int FLIB_LOGLEVEL_ALL = -100;
    public static final int FLIB_LOGLEVEL_DEBUG = -1;
    public static final int FLIB_LOGLEVEL_INFO = 0;
    public static final int FLIB_LOGLEVEL_WARNING = 1;
    public static final int FLIB_LOGLEVEL_ERROR = 2;
    public static final int FLIB_LOGLEVEL_NONE = 100;

    void flib_log_setLevel(int level);
    void flib_log_setCallback(LogCallback callback);
}