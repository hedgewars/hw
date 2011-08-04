package org.hedgewars.mobile;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;

import android.content.Context;
import android.content.res.TypedArray;
import android.widget.Toast;

public class Utils {

	
	/**
	 * get the path to which we should download all the data files
	 * @param c context 
	 * @return absolute path
	 */
	public static String getDownloadPath(Context c){
		File f =  c.getExternalCacheDir();
		if(f != null){
			return f.getAbsolutePath() + "/Data/";
		}else{
			Toast.makeText(c, R.string.sdcard_not_mounted, Toast.LENGTH_LONG);
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
		String prefix = getDownloadPath(c);
		File f = new File(prefix + dirName);
		
		if(f.exists() && f.isDirectory()) return f.list();
		else throw new IllegalArgumentException("File not a directory or doesn't exist dirName = " + f.getAbsolutePath());
	}
	
	/**
	 * Return a File array with all the files from dirName
	 * @param c
	 * @param dirName
	 * @return
	 */
	public static File[] getFilesFromRelativeDir(Context c, String dirName){
		String prefix = getDownloadPath(c);
		File f = new File(prefix + dirName);
		
		if(f.exists() && f.isDirectory()) return f.listFiles();
		else throw new IllegalArgumentException("File not a directory or doesn't exist dirName = " + f.getAbsolutePath());
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
	public static String[] getDirsWithFileSuffix(Context c, String path, String fileSuffix){
		File[] files = getFilesFromRelativeDir(c,path);
		String[] validFiles = new String[files.length];
		int validCounter = 0;
		
		for(File f : files){
			if(hasFileWithSuffix(f, fileSuffix)) validFiles[validCounter++] = f.getName();
		}
		String[] ret = new String[validCounter];
		System.arraycopy(validFiles, 0, ret, 0, validCounter);
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
