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

package org.hedgewars.hedgeroid.Datastructures;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.util.FileUtils;

import android.content.Context;
import android.content.res.Resources;

/**
 * Represents a map from the data directory
 */
public final class MapFile {
	public static final String MAP_DIRECTORY = "Maps";
	
	public final String name;
	public final boolean isMission;
	
	public MapFile(String name, boolean isMission) {
		this.name = name;
		this.isMission = isMission;
	}
	
	/**
	 * @throws FileNotFoundException if the sdcard is not available. Does NOT throw if the requested map file does not exist.
	 */
	public static File getFileForMapname(Context ctx, String mapname) throws FileNotFoundException {
		return new File(new File(FileUtils.getDataPathFile(ctx), MAP_DIRECTORY), mapname);
	}
	
	public static final Comparator<MapFile> MISSIONS_FIRST_NAME_ORDER = new Comparator<MapFile>() {
		public int compare(MapFile lhs, MapFile rhs) {
			if(lhs.isMission != rhs.isMission) {
				return lhs.isMission && !rhs.isMission ? -1 : 1;
			} else {
				return lhs.name.compareToIgnoreCase(rhs.name);
			}
		}
	};
	
	@Override
	public String toString() {
		return "MapFile [name=" + name + ", isMission=" + isMission + "]";
	}

	public File getPreviewFile(Context c) throws FileNotFoundException {
		return getPreviewFile(c, name);
	}
	
	public static File getPreviewFile(Context c, String mapName) throws FileNotFoundException {
		return new File(FileUtils.getDataPathFile(c), MAP_DIRECTORY + "/" + mapName + "/" + "preview.png");
	}
	
	public static List<String> toDisplayNameList(List<MapFile> mapFiles, Resources res) {
		String missionPrefix = res.getString(R.string.map_mission_prefix);
		List<String> result = new ArrayList<String>();
		for(MapFile mapFile : mapFiles) {
			result.add((mapFile.isMission ? missionPrefix : "") + mapFile.name);
		}
		return result;
	}
}
