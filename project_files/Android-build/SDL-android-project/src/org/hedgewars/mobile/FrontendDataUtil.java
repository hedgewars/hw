package org.hedgewars.mobile;

import java.io.File;
import java.util.Arrays;

import android.content.Context;

public class FrontendDataUtil {

	private static final String MISSION_PREFIX = "Mission: ";
	
	public static String[] getMaps(Context c){
		File[] files = Utils.getFilesFromRelativeDir(c,"Maps");
		String[] maps = new String[files.length];
		String[] missions = new String[maps.length];
		int mapsCounter = 0, missionsCounter = 0;
		
		for(File f : files){
			if(Utils.hasFileWithSuffix(f, ".lua")){
				missions[missionsCounter++] = MISSION_PREFIX + f.getName();
			}else{
				maps[mapsCounter++] = f.getName();
			}
		}
		String[] ret = new String[maps.length];
		System.arraycopy(missions, 0, ret, 0, missionsCounter);
		System.arraycopy(maps, 0, ret, missionsCounter, mapsCounter);
		Arrays.sort(ret, 0, missionsCounter);
		Arrays.sort(ret, missionsCounter, ret.length);
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
	
	public static Scheme[] getSchemes(Context c){
		return Scheme.getSchemes(c);
	}
	
	public static Weapon[] getWeapons(Context c){
		return Weapon.getWeapons(c);
	}
}
