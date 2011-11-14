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

import android.os.AsyncTask;
/**
 * This is an AsyncTask which will download a zip from an URL and unzip it to a specified path
 * 
 *  a typical call to start the task would be new DownloadAsyncTask().execute(getExternalStorage(), "www.hedgewars.org/data.zip");
 * @author Xeli
 *
 */
public class DownloadAsyncTask extends AsyncTask<DownloadTask, Object, Long> {

	//private final static String URL_WITHOUT_SUFFIX = "http://www.xelification.com/tmp/firebutton.";
	private final static String URL_ZIP_SUFFIX = ".zip";
	private final static String URL_HASH_SUFFIX = ".hash";
	
	private DownloadService service;
	private long lastUpdateMillis = 0;

	public DownloadAsyncTask(DownloadService _service){
		service = _service;
	}

	/**
	 * 
	 * @param params - A {@link}DownloadTask which gives information about where to download from and store the files to 
	 */
	protected Long doInBackground(DownloadTask...tasks) {
		DownloadTask task = tasks[0];//just use one task per execute call for now
		
		HttpURLConnection conn = null;
		MessageDigest digester = null;
		String rootZipDest = task.getPathToStore();

		File rootDest = new File(rootZipDest);//TODO check for nullpointer, it hints to the absence of an sdcard
		rootDest.mkdir();

		try {
			URL url = new URL(task.getURL() + URL_ZIP_SUFFIX);
			conn = (HttpURLConnection)url.openConnection();
		} catch (IOException e) {
			e.printStackTrace();
			return -1l;
		}

		String contentType = conn.getContentType();

		if(contentType == null || contentType.contains("zip")){ //Seeing as we provide the url if the contentType is unknown lets assume zips
			int bytesDecompressed = 0;
			ZipEntry entry = null;
			ZipInputStream input = null;
			int kbytesToProcess = conn.getContentLength()/1024;

			byte[] buffer = new byte[1024];
			service.start(kbytesToProcess);

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
				if(conn != null) conn.disconnect();
				return -1l;
			}

			while(entry != null){
				if(isCancelled()) break;

				String fileName = entry.getName();
				File f = new File(rootZipDest + fileName);
				bytesDecompressed += entry.getCompressedSize();

				if(entry.isDirectory()){
					f.mkdir();
				}else{
					if(f.exists()){
						f.delete();
					}

					FileOutputStream output = null;
					try {
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
					} catch (FileNotFoundException e) {
						e.printStackTrace();
						if(conn != null) conn.disconnect();
						return -1l;
					} catch (IOException e) {
						e.printStackTrace();
						if(conn != null) conn.disconnect();
						return -1l;
					}finally{
						try {
							if( output != null) output.close();
						} catch (IOException e) {}
					}
				}
				try{
					entry = input.getNextEntry();
				}catch(IOException e){
					e.printStackTrace();
					if(conn != null) conn.disconnect();
					return -1l;
				}
			}//end while(entry != null)

			try {
				input.close();
			} catch (IOException e) {}
		}//end if contentType == "zip"

		if(conn != null) conn.disconnect();

		if(checkMD5(digester, task))return 0l;
		else return -1l;
	}

	//TODO proper result handling
	protected void onPostExecute(Long result){
		service.done(result > -1l);
	}

	protected void onProgressUpdate(Object...objects){
		service.update((Integer)objects[0], (Integer)objects[1], (String)objects[2]);
	}

	private boolean checkMD5(MessageDigest digester, DownloadTask task){
		if(digester != null) {
			byte[] messageDigest = digester.digest();

			try {
				URL url = new URL(task.getURL() + URL_HASH_SUFFIX);
				HttpURLConnection conn = (HttpURLConnection)url.openConnection();

				byte[] buffer = new byte[1024];//size is large enough to hold the entire hash
				BufferedInputStream bis = new BufferedInputStream(conn.getInputStream());
				int bytesRead = bis.read(buffer);
				if(bytesRead > -1){
					String hash = new String(buffer, 0, bytesRead);
					StringBuffer sb = new StringBuffer();
					Integer tmp = 0;
					for(int i = 0; i < messageDigest.length; i++){
						tmp = 0xFF & messageDigest[i];
						if(tmp < 0xF) sb.append('0');
						sb.append(Integer.toHexString(tmp));
					}
					sb.append('\n');//add newline to become identical with the hash file
					
					return hash.equals(sb.toString());
				}
				return false;
			} catch (IOException e) {
				e.printStackTrace();
				return false;
			}
		}else{
			return false;	
		}

	}

}
