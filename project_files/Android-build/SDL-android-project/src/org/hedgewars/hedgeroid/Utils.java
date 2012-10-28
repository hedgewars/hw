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


package org.hedgewars.hedgeroid;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import android.content.Context;
import android.content.res.TypedArray;
import android.os.Build;
import android.os.Environment;
import android.util.Log;

public class Utils {

	private static final String ROOT_DIR = "Data/";

	/**
	 * get the path to which we should download all the data files
	 * @param c context 
	 * @return absolute path
	 */
	public static String getCachePath(Context c){
		if(Build.VERSION.SDK_INT < 8){//8 == Build.VERSION_CODES.FROYO
			return PreFroyoSDCardDir.getDownloadPath(c) + '/';
		}else{
			return FroyoSDCardDir.getDownloadPath(c) + '/';
		}
	}

	public static String getDataPath(Context c){
		return getCachePath(c) + ROOT_DIR;
	}

	static class FroyoSDCardDir{
		public static String getDownloadPath(Context c){
			File f =  c.getExternalCacheDir();
			if(f != null){
				return f.getAbsolutePath();
			}else{
				return null;
			}	
		}
	}

	static class PreFroyoSDCardDir{
		public static String getDownloadPath(Context c){
			if(Environment.getExternalStorageState().equals(Environment.MEDIA_MOUNTED)){
				if(Environment.getExternalStorageDirectory() != null)
					return Environment.getExternalStorageDirectory().getAbsolutePath() + "/Hedgewars/";				
			}
			return null;
		}
	}

	/**
	 * Get files from dirName, dir name is relative to {@link getDownloadPath}
	 * @param dirName
	 * @param c context
	 * @return string of files
	 */
	public static String[] getFileNamesFromRelativeDir(Context c, String dirName){
		String prefix = getDataPath(c);
		File f = new File(prefix + dirName);

		if(f.exists() && f.isDirectory()) return f.list();
		else{

			Log.e("Utils::", "Couldn't find dir: " + dirName);
			return new String[0];
		}
	}

	/**
	 * Return a File array with all the files from dirName
	 * @param c
	 * @param dirName
	 * @return
	 */
	public static File[] getFilesFromRelativeDir(Context c, String dirName){
		String prefix = getDataPath(c);
		File f = new File(prefix + dirName);

		if(f.exists() && f.isDirectory()) return f.listFiles();
		else {
			Log.e("Utils::", "Dir not found: " + dirName);
			return new File[0];
		}
	}

	/**
	 * Checks if this directory has a file with suffix suffix
	 * @param f - directory
	 * @return
	 */
	public static boolean hasFileWithSuffix(File f, String suffix){
		if(f.isDirectory()){
			for(String s : f.list()){
				if(s.endsWith(suffix)) return true;
			}
			return false;
		}else{
			return false;
		}
	}

	/**
	 * Gives back all dirs which contain a file with suffix fileSuffix
	 * @param c
	 * @param path
	 * @param fileSuffix
	 * @return
	 */
	public static List<String> getDirsWithFileSuffix(Context c, String path, String fileSuffix){
		File[] files = getFilesFromRelativeDir(c,path);
		ArrayList<String> ret = new ArrayList<String>();

		for(File f : files){
			if(hasFileWithSuffix(f, fileSuffix)) ret.add(f.getName());
		}
		return ret;
	}

	/**
	 * Get all files from directory dir which have the given suffix
	 * @param c
	 * @param dir
	 * @param suffix
	 * @param removeSuffix
	 * @return
	 */
	public static ArrayList<String> getFilesFromDirWithSuffix(Context c, String dir, String suffix, boolean removeSuffix){
		String[] files = Utils.getFileNamesFromRelativeDir(c, dir);
		ArrayList<String> ret = new ArrayList<String>();
		for(String s : files){
			if(s.endsWith(suffix)){
				if(removeSuffix) ret.add(s.substring(0, s.length()-suffix.length()));
				else ret.add(s);
			}
		}
		return ret;
	}

	/**
	 * Moves resources pointed to by sourceResId (from @res/raw/) to the app's private data directory
	 * @param c
	 * @param sourceResId
	 * @param directory
	 */
	public static void resRawToFilesDir(Context c, int sourceResId, String directory){
		byte[] buffer = new byte[1024];
		InputStream bis = null;
		BufferedOutputStream bos = null;
		File schemesDirFile = new File(c.getFilesDir().getAbsolutePath() + '/' + directory);
		schemesDirFile.mkdirs();
		String schemesDirPath = schemesDirFile.getAbsolutePath() + '/';

		//Get an array with the resource files ID
		TypedArray ta = c.getResources().obtainTypedArray(sourceResId);
		int[] resIds = new int[ta.length()];
		for(int i = 0; i < ta.length(); i++){
			resIds[i] = ta.getResourceId(i, 0);
		}

		for(int id : resIds){
			String fileName = c.getResources().getResourceEntryName(id);
			File f = new File(schemesDirPath + fileName);
			try {
				if(!f.createNewFile()){
					f.delete();
					f.createNewFile();
				}

				bis = c.getResources().openRawResource(id);
				bos = new BufferedOutputStream(new FileOutputStream(f), 1024);
				int read = 0;
				while((read = bis.read(buffer)) != -1){
					bos.write(buffer, 0, read);
				}

			} catch (IOException e) {
				e.printStackTrace();
			}finally{
				if(bis != null)
					try { 
						bis.close();
					} catch (IOException e) {
						e.printStackTrace();
					}
					if(bos != null)
						try {
							bos.close();
						} catch (IOException e) {
							e.printStackTrace();
						}
			}
		}
	}
}
