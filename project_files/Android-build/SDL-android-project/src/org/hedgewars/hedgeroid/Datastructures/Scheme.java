/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011-2012 Richard Deurwaarder <xeli@xelification.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

package org.hedgewars.hedgeroid.Datastructures;

import java.util.Map;

import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map.Entry;
import java.util.TreeMap;

import org.hedgewars.hedgeroid.EngineProtocol.EngineProtocolNetwork;
import org.ini4j.Ini;
import org.ini4j.InvalidFileFormatException;
import org.ini4j.Profile.Section;

import android.content.Context;
import android.os.Parcel;
import android.os.Parcelable;
import android.util.Log;

public class Scheme implements Parcelable, Comparable<Scheme>{
	public static final String DIRECTORY_SCHEME = "schemes";
	private static final Map<String, BasicSettingMeta> basicSettingsMeta = new TreeMap<String, BasicSettingMeta>();
	private static final Map<String, GameModMeta> gameModsMeta = new TreeMap<String, GameModMeta>();

	private final String name;
	private final int gamemod;
	private final Map<String, Integer> basic = new TreeMap<String, Integer>();
		
	public Scheme(String _name, Map<String, Integer> _basic, int _gamemod) {
		name = _name;
		gamemod = _gamemod;
		basic.putAll(_basic);
	}
	
	public Scheme(Parcel in){
		name = in.readString();
		gamemod = in.readInt();
		in.readMap(basic, Integer.class.getClassLoader());
	}

	public int getHealth() {
		return basic.get("InitialHealth");
	}
	
	public void sendToEngine(EngineProtocolNetwork epn) throws IOException{ 
		epn.sendToEngine(String.format("e$gmflags %d", gamemod));

		for(Map.Entry<String, Integer> entry : basic.entrySet()) {
			BasicSettingMeta basicflag = basicSettingsMeta.get(entry.getKey());
			
			//Health is a special case, it doesn't need to be send 				                             
			//to the engine yet, we'll do that with the other HH info
			if(!basicflag.command.equals("inithealth")){
				epn.sendToEngine(String.format("%s %d", basicflag.command, entry.getValue()));
			}
		}
	}
	
	public String toString(){
		return name;
	}

	public static List<Scheme> getSchemes(Context c) throws IllegalArgumentException {
		File schemeDir = new File(c.getFilesDir(), DIRECTORY_SCHEME);
		File[] files = schemeDir.listFiles(new FilenameFilter() {
			public boolean accept(File dir, String filename) {
				return filename.toLowerCase().startsWith("scheme_");
			}
		});
		if(files == null) files = new File[0];
		Arrays.sort(files);
		List<Scheme> schemes = new ArrayList<Scheme>();

		for(File file : files) {
			try {
				Ini ini = new Ini(file);
				
				String name = ini.get("Scheme", "name");
				if(name==null) {
					name = file.getName();
				}
				Section basicSettingsSection = ini.get("BasicSettings");
				Section gameModsSection = ini.get("GameMods");
				if(basicSettingsSection == null || gameModsSection == null) {
					Log.e(Scheme.class.getCanonicalName(), "Scheme file "+file+" is missing the BasicSettings or GameMods section - skipping.");
					continue;
				}
				
				Map<String, Integer> basicSettings = new TreeMap<String, Integer>();
				for(Entry<String, BasicSettingMeta> entry : basicSettingsMeta.entrySet()) {
					String key = entry.getKey();
					BasicSettingMeta settingMeta = entry.getValue();
					Integer value = null;
					if(basicSettingsSection.containsKey(key)) {
						try {
							value = Integer.valueOf(basicSettingsSection.get(key));						
						} catch (NumberFormatException e) {
							// ignore
						}
					}
					
					if(value==null) {
						Log.w(Scheme.class.getCanonicalName(), "Scheme file "+file+" setting "+key+" is missing or invalid, using default.");
						value = settingMeta.def;
					}
					
					if(settingMeta.checkOverMax) {
						value = Math.min(value, settingMeta.max);
					}
					if(settingMeta.times1000) {
						value *= 1000;
					}
					
					basicSettings.put(key, value);						
				}
				
				int gamemods = 0;
				for(Entry<String, GameModMeta> entry : gameModsMeta.entrySet()) {
					String key = entry.getKey();
					GameModMeta modMeta = entry.getValue();
					if(Boolean.parseBoolean(gameModsSection.get(key))) {
						gamemods |= (1 << modMeta.bitmaskIndex);
					}
				}
				
				schemes.add(new Scheme(name, basicSettings, gamemods));
			} catch (InvalidFileFormatException e) {
				throw new RuntimeException(e);
			} catch (IOException e) {
				throw new RuntimeException(e);
			}
		}
		return schemes;
	}
	
	/**
	 * This method will parse the basic flags from a prespecified ini file.
	 * In the future we could use one provided by the Data folder.
	 */
	public static void parseConfiguration(Context c) {
		File schemeDir = new File(c.getFilesDir(), DIRECTORY_SCHEME);
		File settingsFile = new File(schemeDir, "basicsettings");
		File gameModsFile = new File(schemeDir, "gamemods");
		
		try {
			Ini ini = new Ini(settingsFile);
			for(Entry<String, Section> sectionEntry : ini.entrySet()) {
				basicSettingsMeta.put(sectionEntry.getKey(), new BasicSettingMeta(sectionEntry.getValue()));
			}
			
			ini = new Ini(gameModsFile);
			for(Entry<String, Section> sectionEntry : ini.entrySet()) {
				gameModsMeta.put(sectionEntry.getKey(), new GameModMeta(sectionEntry.getValue()));
			}
		} catch (InvalidFileFormatException e) {
			throw new RuntimeException(e);
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
	}

	public int describeContents() {
		return 0;
	}

	public void writeToParcel(Parcel dest, int flags) {
		dest.writeString(name);
		dest.writeInt(gamemod);
		dest.writeMap(basic);
	}

	public static final Parcelable.Creator<Scheme> CREATOR = new Parcelable.Creator<Scheme>() {
		public Scheme createFromParcel(Parcel source) {
			return new Scheme(source);
		}
		public Scheme[] newArray(int size) {
			return new Scheme[size];
		}
		
	};

	public int compareTo(Scheme another) {
		return name.compareTo(another.name);
	}
}

class BasicSettingMeta {
	final String command;
	final String title;
	final int def;
	final int min;
	final int max;
	final boolean times1000;
	final boolean checkOverMax;
	
	public BasicSettingMeta(Ini.Section section) {
		command = getRequired(section, "command");
		title = section.get("title", "");
		def = Integer.parseInt(getRequired(section, "default"));
		min = Integer.parseInt(getRequired(section, "min"));
		max = Integer.parseInt(getRequired(section, "max"));
		times1000 = Boolean.parseBoolean(section.get("times1000", "false"));
		checkOverMax = Boolean.parseBoolean(section.get("checkOverMax", "false"));
	}
	
	private String getRequired(Ini.Section section, String key) {
		String result = section.get(key);
		if(result==null) {
			throw new IllegalArgumentException("basicsettings.ini, section "+section.getName()+" is missing required setting "+key+".");
		}
		return result;
	}

	@Override
	public String toString() {
		return String
				.format("BasicSettingMeta [command=%s, title=%s, def=%s, min=%s, max=%s, times1000=%s, checkOverMax=%s]",
						command, title, def, min, max, times1000, checkOverMax);
	}
}

// TODO: Extend with additional metadata
class GameModMeta {
	final int bitmaskIndex;
	
	public GameModMeta(Ini.Section section) {
		bitmaskIndex = Integer.parseInt(getRequired(section, "bitmaskIndex"));
	}
	
	private String getRequired(Ini.Section section, String key) {
		String result = section.get(key);
		if(result==null) {
			throw new IllegalArgumentException("gamemods.ini, section "+section.getName()+" is missing required setting "+key+".");
		}
		return result;
	}

	@Override
	public String toString() {
		return String.format("GameModMeta [bitmaskIndex=%s]", bitmaskIndex);
	}
}