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

package org.hedgewars.hedgeroid.util;

import java.io.ByteArrayOutputStream;
import java.io.Closeable;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.res.Resources;
import android.content.res.TypedArray;
import android.os.Build;
import android.os.Environment;
import android.util.Log;

public class FileUtils {
    private static final String ROOT_DIR = "Data";
    private static final String TAG = FileUtils.class.getSimpleName();

    /**
     * @return true if the data path is currently available. However, it can vanish at any time so
     * normally you should just try to use it and rely on the exceptions.
     */
    public static boolean isDataPathAvailable() {
        return Environment.MEDIA_MOUNTED.equals(Environment.getExternalStorageState());
    }

    /**
     * get the path to which we should download all the data files
     * @param c context
     * @return The directory
     * @throws FileNotFoundException if external storage is not available at the moment
     */
    public static File getCachePath(Context c) throws FileNotFoundException {
        File cachePath = null;
        if(Build.VERSION.SDK_INT < 8){//8 == Build.VERSION_CODES.FROYO
            cachePath = PreFroyoSDCardDir.getDownloadPath(c);
        } else {
            cachePath = FroyoSDCardDir.getDownloadPath(c);
        }
        if(cachePath==null) {
            throw new FileNotFoundException("External storage is currently unavailable");
        } else {
            return cachePath;
        }
    }

    public static File getDataPathFile(Context c, String...subpath) throws FileNotFoundException {
        File file = new File(getCachePath(c), ROOT_DIR);
        for(String pathcomponent : subpath) {
            file = new File(file, pathcomponent);
        }
        return file;
    }

    @TargetApi(8)
    private static class FroyoSDCardDir{
        public static File getDownloadPath(Context c){
            return c.getExternalCacheDir();
        }
    }

    private static class PreFroyoSDCardDir{
        public static File getDownloadPath(Context c){
            if(Environment.getExternalStorageState().equals(Environment.MEDIA_MOUNTED)){
                File extStorageDir = Environment.getExternalStorageDirectory();
                if(extStorageDir != null) {
                    return new File(extStorageDir, "Hedgewars");
                }
            }
            return null;
        }
    }

    /**
     * Return a File array with all the files from dirName
     * @param c
     * @param dirName
     * @return
     * @throws FileNotFoundException If the sdcard is not available or the subdirectory "dirName" does not exist
     */
    public static File[] getFilesFromRelativeDir(Context c, String dirName) throws FileNotFoundException {
        File f = getDataPathFile(c, dirName);

        if(f.isDirectory()) {
            return f.listFiles();
        } else {
            throw new FileNotFoundException("Directory "+dirName+" does not exist.");
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
     * @throws FileNotFoundException If the sdcard is not available or the subdirectory "path" does not exist
     */
    public static List<String> getDirsWithFileSuffix(Context c, String path, String fileSuffix) throws FileNotFoundException{
        File[] files = getFilesFromRelativeDir(c,path);
        ArrayList<String> ret = new ArrayList<String>();

        for(File f : files){
            if(hasFileWithSuffix(f, fileSuffix)) ret.add(f.getName());
        }
        return ret;
    }

    /**
     * Get all files from directory dir which have the given suffix
     * @throws FileNotFoundException If the sdcard is not available or the subdirectory "dir" does not exist
     */
    public static List<String> getFileNamesFromDirWithSuffix(Context c, String dir, String suffix, boolean removeSuffix) throws FileNotFoundException{
        File[] files = FileUtils.getFilesFromRelativeDir(c, dir);
        List<String> ret = new ArrayList<String>();
        for(File file : files){
            String s = file.getName();
            if(s.endsWith(suffix)){
                if(removeSuffix) ret.add(s.substring(0, s.length()-suffix.length()));
                else ret.add(s);
            }
        }
        return ret;
    }

    /**
     * Close a resource (possibly null), ignoring any IOException.
     */
    public static void closeQuietly(Closeable c) {
        if(c!=null) {
            try {
                c.close();
            } catch(IOException e) {
                Log.w(TAG, e);
            }
        }
    }

    /**
     * Write all data from the input stream to the file, creating or overwriting it.
     * The input stream will be closed.
     *
     * @throws IOException
     */
    public static void writeStreamToFile(InputStream is, File file) throws IOException {
        OutputStream os = null;
        byte[] buffer = new byte[8192];
        try {
            os = new FileOutputStream(file);
            int size;
            while((size=is.read(buffer)) != -1) {
                os.write(buffer, 0, size);
            }
            os.close(); // Important to close this non-quietly, in case of exceptions when flushing
        } finally {
            FileUtils.closeQuietly(is);
            FileUtils.closeQuietly(os);
        }
    }

    /**
     * Moves resources pointed to by sourceResId (from @res/raw/) to the app's private data directory
     * @param c
     * @param sourceResId
     * @param directory
     */
    public static void resRawToFilesDir(Context c, int sourceResId, int targetFilenames, String directory) throws IOException {
        File targetDir = new File(c.getFilesDir(), directory);
        targetDir.mkdirs();

        //Get an array with the resource files ID
        Resources resources = c.getResources();
        TypedArray ta = resources.obtainTypedArray(sourceResId);
        TypedArray filenames = resources.obtainTypedArray(targetFilenames);
        for(int i = 0; i < ta.length(); i++){
            int resId =  ta.getResourceId(i, 0);
            String fileName = filenames.getString(i);
            File f = new File(targetDir, fileName);
            writeStreamToFile(resources.openRawResource(resId), f);
        }
    }

    public static String readToString(InputStream is) throws IOException {
        try {
            ByteArrayOutputStream os = new ByteArrayOutputStream();
            byte[] buffer = new byte[8192];
            int size;
            while((size=is.read(buffer)) != -1) {
                os.write(buffer, 0, size);
            }
            return new String(os.toByteArray());
        } finally {
            closeQuietly(is);
        }
    }

    private static final char[] badFilenameChars = new char[] { '/', '\\', ':', '*', '?', '\"', '<', '>', '|', '.', '\0' };

    /**
     * Modify the given String so that it can be used as part of a filename
     * without causing problems from illegal/special characters.
     *
     * The result should be similar to the input, but isn't necessarily
     * reversible.
     */
    public static String replaceBadChars(String name) {
        if (name == null || name.trim().length()==0) {
            return "_";
        }
        name = name.trim();
        for (char badChar : badFilenameChars) {
            name = name.replace(badChar, '_');
        }
        return name;
    }
}
