/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011-2012 Richard Deurwaarder <xeli@xelification.com>
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


package org.hedgewars.hedgeroid.Downloader;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import org.hedgewars.hedgeroid.Downloader.DownloadService.DownloadTask;

import android.os.AsyncTask;
/**
 * This is an AsyncTask which will download a zip from an URL and unzip it to a specified path
 *
 *  a typical call to start the task would be new DownloadAsyncTask().execute(getExternalStorage(), "www.hedgewars.org/data.zip");
 * @author Xeli
 *
 */
public class DownloadAsyncTask extends AsyncTask<DownloadPackage, Object, Integer> {

    //private final static String URL_WITHOUT_SUFFIX = "http://www.xelification.com/tmp/firebutton.";
    private final static String URL_ZIP_SUFFIX = ".zip";
    private final static String URL_HASH_SUFFIX = ".hash";

    public static final int EXIT_SUCCESS = 0;
    public static final int EXIT_URLFAIL = 1;
    public static final int EXIT_CONNERROR = 2;
    public static final int EXIT_FNF = 3;
    public static final int EXIT_MD5 = 4;
    public static final int EXIT_CANCELLED = 5;

    private DownloadTask task;
    private long lastUpdateMillis = 0;

    public DownloadAsyncTask(DownloadTask _task){
        task = _task;
    }

    /**
     *
     * @param params - A {@link}DownloadTask which gives information about where to download from and store the files to
     */
    protected Integer doInBackground(DownloadPackage...packages) {
        DownloadPackage pack = packages[0];//just use one task per execute call for now

        HttpURLConnection conn = null;
        MessageDigest digester = null;
        String rootZipDest = pack.getPathToStore();

        File rootDest = new File(rootZipDest);//TODO check for nullpointer, it hints to the absence of an sdcard
        rootDest.mkdirs();

        try {
            URL url = new URL(pack.getURL() + URL_ZIP_SUFFIX);
            conn = (HttpURLConnection)url.openConnection();
        } catch (IOException e) {
            e.printStackTrace();
            return EXIT_URLFAIL;
        }

        String contentType = conn.getContentType();

        if(contentType == null || contentType.contains("zip")){ //Seeing as we provide the url if the contentType is unknown lets assume zips
            int bytesDecompressed = 0;
            ZipEntry entry = null;
            ZipInputStream input = null;
            FileOutputStream output = null;
            int kbytesToProcess = conn.getContentLength()/1024;

            byte[] buffer = new byte[1024];
            task.start(kbytesToProcess);

            try {
                digester = MessageDigest.getInstance("MD5");

            } catch (NoSuchAlgorithmException e1) {
                e1.printStackTrace();
            }

            try{
                input = new ZipInputStream(conn.getInputStream());
                entry = input.getNextEntry();
            }catch(IOException e){
                e.printStackTrace();
                conn.disconnect();
                return EXIT_CONNERROR;
            }



            while(entry != null){

                if(isCancelled()) break;

                try {
                    String fileName = entry.getName();
                    File f = new File(rootZipDest + fileName);
                    bytesDecompressed += entry.getCompressedSize();

                    if(entry.isDirectory()){
                        f.mkdir();
                    }else{
                        if(f.exists()){
                            f.delete();
                        }
                        f.createNewFile();
                        output = new FileOutputStream(f);

                        int count = 0;
                        while((count = input.read(buffer)) != -1){
                            output.write(buffer, 0, count);
                            digester.update(buffer, 0, count);
                            if(System.currentTimeMillis() - lastUpdateMillis > 1000){
                                lastUpdateMillis = System.currentTimeMillis();
                                publishProgress(bytesDecompressed, kbytesToProcess, fileName);
                            }
                        }
                        output.flush();
                        input.closeEntry();
                    }//if isDir
                    entry = input.getNextEntry();
                } catch (FileNotFoundException e) {
                    e.printStackTrace();
                    if(conn != null) conn.disconnect();
                    return EXIT_FNF;
                } catch (IOException e) {
                    e.printStackTrace();
                    if(conn != null) conn.disconnect();
                    return EXIT_CONNERROR;
                }finally{
                    try {
                        if( output != null) output.close();

                    } catch (IOException e) {}
                }
            }//end while(entry != null)
            if( input != null)
                try {
                    input.close();
                } catch (IOException e) {}
        }else{//end if contentType == "zip"
            return EXIT_URLFAIL;
        }
        if(conn != null) conn.disconnect();

        if(checkMD5(digester, pack))return EXIT_SUCCESS;
        else return EXIT_MD5;
    }

    //TODO proper result handling
    protected void onPostExecute(Integer result){
        task.done(result);
    }

    protected void onProgressUpdate(Object...objects){
        task.update((Integer)objects[0], (Integer)objects[1], (String)objects[2]);
    }

    protected void onCancelled(){
        onPostExecute(EXIT_CANCELLED);
    }

    private boolean checkMD5(MessageDigest digester, DownloadPackage task){
        if(digester != null) {
            byte[] messageDigest = digester.digest();

            try {
                URL url = new URL(task.getURL() + URL_HASH_SUFFIX);
                HttpURLConnection conn = (HttpURLConnection)url.openConnection();

                byte[] buffer = new byte[1024];//size is large enough to hold the entire hash
                BufferedInputStream bis = new BufferedInputStream(conn.getInputStream());
                int bytesRead = bis.read(buffer);
                String hash = null;
                if(bytesRead > -1){
                    hash = new String(buffer, 0, bytesRead);
                }
                StringBuffer sb = new StringBuffer();
                Integer tmp = 0;
                for(int i = 0; i < messageDigest.length; i++){
                    tmp = 0xFF & messageDigest[i];
                    if(tmp < 0xF) sb.append('0');
                    sb.append(Integer.toHexString(tmp));
                }
                sb.append('\n');//add newline to become identical with the hash file

                return hash.equals(sb.toString());
            } catch (IOException e) {
                e.printStackTrace();
                return true;
            }
        }else{
            return true;
        }

    }

}
