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


package org.hedgewars.mobile.Downloader;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import android.os.AsyncTask;
import android.util.Log;
/**
 * This is an AsyncTask which will download a zip from an URL and unzip it to a specified path
 * 
 *  a typical call to start the task would be new DownloadAsyncTask().execute(getExternalStorage(), "www.hedgewars.org/data.zip");
 * @author Xeli
 *
 */
public class DownloadAsyncTask extends AsyncTask<String, Object, Long> {

	private DownloadService service;
	private long lastUpdateMillis = 0;
	
	public DownloadAsyncTask(DownloadService _service){
		service = _service;
	}
	
	/**
	 * 
	 * @param params - 2 Strings, first is the path where the unzipped files will be stored, second is the URL to download from
	 */
	protected Long doInBackground(String... params) {
		HttpURLConnection conn = null;
		try {
			String rootZipDest = params[0];

			File rootDest = new File(rootZipDest);//TODO check for nullpointer, it hints to the absence of an sdcard
			rootDest.mkdir();
			
			URL url = new URL(params[1]);
			conn = (HttpURLConnection)url.openConnection();
			String contentType = conn.getContentType();

			if(contentType == null || contentType.contains("zip")){ //Seeing as we provide the url if the contentType is unknown lets assume zips
				ZipInputStream input = new ZipInputStream(conn.getInputStream());
				int bytesDecompressed = 0;
				final int kbytesToProcess = conn.getContentLength()/1024;
				
				service.start(kbytesToProcess);
				
				ZipEntry entry = null;
				while((entry = input.getNextEntry()) != null){
					String fileName = entry.getName();
					
					if(isCancelled()) break;
					else if(System.currentTimeMillis() - lastUpdateMillis > 1000){
						lastUpdateMillis = System.currentTimeMillis();
						publishProgress(bytesDecompressed, kbytesToProcess, fileName);
					}
					
					Log.e("bla", fileName);
					bytesDecompressed += entry.getCompressedSize();
					
					File f = new File(rootZipDest + fileName);

					if(entry.isDirectory()){
						f.mkdir();
					}else{
						if(f.exists()){
							f.delete();
						}

						try {
							f.createNewFile();
							FileOutputStream out = new FileOutputStream(f);

							byte[] buffer = new byte[1024];
							int count = 0;
							while((count = input.read(buffer)) != -1){
								out.write(buffer, 0, count);
							}
							out.flush();
							out.close();
							input.closeEntry();
						} catch (FileNotFoundException e) {
							e.printStackTrace();
						} catch (IOException e) {
							e.printStackTrace();
						}
					}
				}
				input.close();
			}else{
				Log.e("bla", "contenttype = " + contentType);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}finally{
			if(conn != null) conn.disconnect();
		}
		return null;
	}
	
	//TODO propper result handling
	protected void onPostExecute(Long result){
		service.done(true);
	}
	
	protected void onProgressUpdate(Object...objects){
		service.update((Integer)objects[0], (Integer)objects[1], (String)objects[2]);
	}

}
