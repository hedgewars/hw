/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011-2012 Richard Deurwaarder <xeli@xelification.com>
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
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.util.FileUtils;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

public class FrontendDataUtils {

	/**
	 * @throws FileNotFoundException if the sdcard isn't available or the Maps directory doesn't exist
	 */
	public static List<MapFile> getMaps(Context c) throws FileNotFoundException {
		File[] files = FileUtils.getFilesFromRelativeDir(c,"Maps");
		List<MapFile> ret = new ArrayList<MapFile>();

		for(File f : files) {
			boolean isMission = FileUtils.hasFileWithSuffix(f, ".lua");
			ret.add(new MapFile(f.getName(), isMission));
		}

		return ret;
	}

	/**
	 * Returns a list of all multiplayer scripts (game styles)
	 * @throws FileNotFoundException if the sdcard isn't available or the Scripts/Multiplayer directory doesn't exist
	 */
	public static List<String> getGameStyles(Context c) throws FileNotFoundException {
		File[] files = FileUtils.getFilesFromRelativeDir(c, "Scripts/Multiplayer");
		List<String> ret = new ArrayList<String>();
		/*
		 * Caution: It is important that the "empty" style has this exact name, because
		 * it will be interpreted as "don't load a script" by the frontlib, and also by
		 * the QtFrontend in a netgame. This should probably be improved some time
		 * (maybe TODO add a dummy script called "Normal" to the MP scripts?) 
		 */
		ret.add("Normal");
		for(int i = 0; i < files.length; i++) {
			String name = files[i].getName();
			if(name.endsWith(".lua")){
				//replace _ by a space and removed the last four characters (.lua)
				ret.add(name.replace('_', ' ').substring(0, name.length()-4));
			}
		}
		return ret;
	}

	/**
	 * @throws FileNotFoundException if the sdcard isn't available or the Themes directory doesn't exist
	 */
	public static List<String> getThemes(Context c) throws FileNotFoundException {
		return FileUtils.getDirsWithFileSuffix(c, "Themes", "icon.png");
	}

	/**
	 * @throws FileNotFoundException if the sdcard isn't available or the Graphics/Graves directory doesn't exist
	 */
	public static List<Map<String, ?>> getGraves(Context c) throws FileNotFoundException {
		File gravePath = FileUtils.getDataPathFile(c, "Graphics", "Graves");
		List<String> names = FileUtils.getFileNamesFromDirWithSuffix(c,"Graphics/Graves", ".png", true);
		List<Map<String, ?>> data = new ArrayList<Map<String, ?>>(names.size());

		for(String s : names){
			HashMap<String, Object> map = new HashMap<String, Object>();
			map.put("txt", s);
			Bitmap b = BitmapFactory.decodeFile(new File(gravePath, s + ".png").getAbsolutePath());
			int width = b.getWidth();
			if(b.getHeight() > width){
				// some pictures contain more 'frames' underneath each other, if so we only use the first frame
				b = Bitmap.createBitmap(b, 0, 0, width, width);
			}
			map.put("img", b);
			data.add(map);
		}
		return data;
	}

	/**
	 * @throws FileNotFoundException if the sdcard isn't available or the Graphics/Graves directory doesn't exist
	 */
	public static List<Map<String, ?>> getFlags(Context c) throws FileNotFoundException {
		File flagsPath = FileUtils.getDataPathFile(c, "Graphics", "Flags");
		List<String> names = FileUtils.getFileNamesFromDirWithSuffix(c, "Graphics/Flags", ".png", true);
		List<Map<String, ?>> data = new ArrayList<Map<String, ?>>(names.size());

		for(String s : names){
			Map<String, Object> map = new HashMap<String, Object>();
			map.put("txt", s);
			Bitmap b = BitmapFactory.decodeFile(new File(flagsPath, s + ".png").getAbsolutePath());
			map.put("img", b);
			data.add(map);
		}
		return data;
	}

	/**
	 * @throws FileNotFoundException if the sdcard isn't available or the Sounds/voices directory doesn't exist
	 */
	public static List<String> getVoices(Context c) throws FileNotFoundException {
		File[] files = FileUtils.getFilesFromRelativeDir(c, "Sounds/voices");
		List<String> ret = new ArrayList<String>();

		for(File f : files){
			if(f.isDirectory()) ret.add(f.getName());
		}
		return ret;
	}

	/**
	 * @throws FileNotFoundException if the sdcard isn't available or the Forts directory doesn't exist
	 */
	public static List<String> getForts(Context c) throws FileNotFoundException {
		return FileUtils.getFileNamesFromDirWithSuffix(c,"Forts", "L.png", true);
	}
	
	public static List<Map<String, ?>> getTypes(Context c){
		List<Map<String, ?>> data = new ArrayList<Map<String, ?>>(6);
		String[] levels = {c.getString(R.string.human), c.getString(R.string.bot5), c.getString(R.string.bot4), c.getString(R.string.bot3), c.getString(R.string.bot2), c.getString(R.string.bot1)};
		int[] images = {R.drawable.human, R.drawable.bot5, R.drawable.bot4, R.drawable.bot3, R.drawable.bot2, R.drawable.bot1};

		for(int i = 0; i < levels.length; i++){
			Map<String, Object> map = new HashMap<String, Object>();
			map.put("txt", levels[i]);
			map.put("img", images[i]);
			map.put("level", i);
			
			data.add(map);
		}

		return data;
	}

	/**
	 * @throws FileNotFoundException if the sdcard isn't available or the Graphics/Hats directory doesn't exist
	 */
	public static List<Map<String, ?>> getHats(Context c) throws FileNotFoundException {
		List<String> files = FileUtils.getFileNamesFromDirWithSuffix(c,"Graphics/Hats", ".png", true);
		File hatsPath = FileUtils.getDataPathFile(c, "Graphics", "Hats");
		int size = files.size();
		List<Map<String, ?>> data = new ArrayList<Map<String, ?>>(size);

		for(String s : files){
			Map<String, Object> hashmap = new HashMap<String, Object>();
			hashmap.put("txt", s);
			Bitmap b = BitmapFactory.decodeFile(new File(hatsPath, s + ".png").getAbsolutePath());
			b = Bitmap.createBitmap(b, 0,0,b.getWidth()/2, b.getWidth()/2);
			hashmap.put("img", b);
			data.add(hashmap);
		}

		return data;
	}

	public static List<Team> getTeams(Context c) {
		List<Team> ret = new ArrayList<Team>();
		
		File teamsDir = new File(c.getFilesDir(), Team.DIRECTORY_TEAMS);
		File[] teamFileNames = teamsDir.listFiles();
		if(teamFileNames != null){
			for(File file : teamFileNames){
				if(file.getName().endsWith(".hwt")) {
					Team team = Team.load(file);
					if(team != null){
						ret.add(team);
					}
				}
			}
		}
		return ret;
	}
}
