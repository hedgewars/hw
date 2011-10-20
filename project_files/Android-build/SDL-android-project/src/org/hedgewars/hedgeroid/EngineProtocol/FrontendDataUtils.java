/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011 Richard Deurwaarder <xeli@xelification.com>
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


package org.hedgewars.hedgeroid.EngineProtocol;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Utils;
import org.hedgewars.hedgeroid.EngineProtocol.Map.MapType;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

public class FrontendDataUtils {


	public static ArrayList<Map> getMaps(Context c){
		File[] files = Utils.getFilesFromRelativeDir(c,"Maps");
		ArrayList<Map> ret = new ArrayList<Map>();

		for(File f : files){
			if(Utils.hasFileWithSuffix(f, ".lua")){
				ret.add(new Map(f,MapType.TYPE_MISSION, c));
			}else{
				ret.add(new Map(f, MapType.TYPE_DEFAULT,c));
			}
		}
		Collections.sort(ret);

		return ret;
	}

	public static String[] getGameplay(Context c){
		String[] files = Utils.getFileNamesFromRelativeDir(c, "Scripts/Multiplayer");
		int retCounter = 0;

		for(int i = 0; i < files.length; i++){
			if(files[i].endsWith(".lua")){
				files[i] = files[i].replace('_', ' ').substring(0, files[i].length()-4); //replace _ by a space and removed the last four characters (.lua)
				retCounter++;
			}else files[i] = null;
		}
		String[] ret = new String[retCounter];
		retCounter = 0;
		for(String s : files){
			if(s != null) ret[retCounter++] = s;
		}
		Arrays.sort(ret);

		return ret;	
	}

	public static String[] getThemes(Context c){
		return Utils.getDirsWithFileSuffix(c, "Themes", "icon.png");
	}

	public static ArrayList<Scheme> getSchemes(Context c){
		return Scheme.getSchemes(c);
	}

	public static ArrayList<Weapon> getWeapons(Context c){
		return Weapon.getWeapons(c);
	}

	public static ArrayList<HashMap<String, ?>> getGraves(Context c){
		String pathPrefix = Utils.getDownloadPath(c) + "Graphics/Graves/";
		ArrayList<String> names = Utils.getFilesFromDirWithSuffix(c, "Graphics/Graves", ".png", true);
		ArrayList<HashMap<String, ?>> data = new ArrayList<HashMap<String, ?>>(names.size());

		for(String s : names){
			HashMap<String, Object> map = new HashMap<String, Object>();
			map.put("txt", s);
			Bitmap b = BitmapFactory.decodeFile(pathPrefix + s + ".png");//create a full path - decode to to a bitmap
			int width = b.getWidth();
			if(b.getHeight() > width){//some pictures contain more 'frames' underneath each other, if so we only use the first frame
				Bitmap tmp = Bitmap.createBitmap(b, 0, 0, width, width);
				b.recycle();
				b = tmp;
			}
			map.put("img", b);
			data.add(map);
		}
		return data;
	}

	public static ArrayList<HashMap<String, ?>> getFlags(Context c){
		String pathPrefix = Utils.getDownloadPath(c) + "Graphics/Flags/";
		ArrayList<String> names = Utils.getFilesFromDirWithSuffix(c, "Graphics/Flags", ".png", true);
		ArrayList<HashMap<String, ?>> data = new ArrayList<HashMap<String, ?>>(names.size());

		for(String s : names){
			HashMap<String, Object> map = new HashMap<String, Object>();
			map.put("txt", s);
			Bitmap b = BitmapFactory.decodeFile(pathPrefix + s + ".png");//create a full path - decode to to a bitmap
			map.put("img", b);
			data.add(map);
		}
		return data;
	}

	public static ArrayList<String> getVoices(Context c){
		File[] files = Utils.getFilesFromRelativeDir(c, "Sounds/voices");
		ArrayList<String> ret = new ArrayList<String>();

		for(File f : files){
			if(f.isDirectory()) ret.add(f.getName());
		}
		return ret;
	}

	public static ArrayList<String> getForts(Context c){
		return Utils.getFilesFromDirWithSuffix(c, "Forts", "L.png", true);
	}
	public static ArrayList<HashMap<String, ?>> getTypes(Context c){
		ArrayList<HashMap<String, ?>> data = new ArrayList<HashMap<String, ?>>(6);
		String[] levels = {c.getString(R.string.human), c.getString(R.string.bot5), c.getString(R.string.bot4), c.getString(R.string.bot3), c.getString(R.string.bot2), c.getString(R.string.bot1)};
		int[] images = {R.drawable.human, R.drawable.bot5, R.drawable.bot4, R.drawable.bot3, R.drawable.bot2, R.drawable.bot1};

		for(int i = 0; i < levels.length; i++){
			HashMap<String, Object> map = new HashMap<String, Object>();
			map.put("txt", levels[i]);
			map.put("img", images[i]);
			data.add(map);
		}

		return data;
	}

	public static ArrayList<HashMap<String, ?>> getHats(Context c){
		ArrayList<String> files = Utils.getFilesFromDirWithSuffix(c, "Graphics/Hats", ".png", true);
		String pathPrefix = Utils.getDownloadPath(c) + "Graphics/Hats/";
		int size = files.size();
		ArrayList<HashMap<String, ?>> data = new ArrayList<HashMap<String, ?>>(size);

		HashMap<String, Object> hashmap; 
		for(String s : files){
			hashmap = new HashMap<String, Object>();
			hashmap.put("txt", s);
			Bitmap b = BitmapFactory.decodeFile(pathPrefix + s + ".png");//create a full path - decode to to a bitmap
			b = Bitmap.createBitmap(b, 0,0,b.getWidth()/2, b.getWidth()/2);
			hashmap.put("img", b);
			data.add(hashmap);
		}

		return data;
	}

	public static ArrayList<HashMap<String, Object>> getTeams(Context c){
		ArrayList<HashMap<String, Object>> ret = new ArrayList<HashMap<String, Object>>();

		File teamsDir = new File(c.getFilesDir().getAbsolutePath() + '/' + Team.DIRECTORY_TEAMS);
		File[] teamFileNames = teamsDir.listFiles();
		if(teamFileNames != null){
			for(File s : teamFileNames){
				Team t = Team.getTeamFromXml(s.getAbsolutePath());
				if(t != null){
					ret.add(teamToHashMap(t));
				}
			}
		}
		return ret;
	}

	public static HashMap<String, Object> teamToHashMap(Team t){
		HashMap<String, Object> hashmap = new HashMap<String, Object>();
		hashmap.put("team", t);
		hashmap.put("txt", t.name);
		hashmap.put("color", t.color);
		hashmap.put("count", t.hogCount);
		switch(t.levels[0]){
		case 0:
			hashmap.put("img", R.drawable.human);
			break;
		case 1:
			hashmap.put("img", R.drawable.bot5);
			break;
		case 2:
			hashmap.put("img", R.drawable.bot4);
			break;
		case 3:
			hashmap.put("img", R.drawable.bot3);
			break;
		case 4:
			hashmap.put("img", R.drawable.bot2);
			break;
		default:
		case 5:
			hashmap.put("img", R.drawable.bot1);
			break;
		}
		return hashmap;
	}
}
