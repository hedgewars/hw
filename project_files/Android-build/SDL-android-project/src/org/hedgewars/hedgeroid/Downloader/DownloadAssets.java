package org.hedgewars.hedgeroid.Downloader;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import org.hedgewars.hedgeroid.MainActivity;
import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Utils;
import org.hedgewars.hedgeroid.Datastructures.Scheme;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.Weapon;

import android.content.Context;
import android.content.res.AssetManager;
import android.os.AsyncTask;
import android.util.Log;

public class DownloadAssets extends AsyncTask<Object, Long, Long>{
	
	private MainActivity act;
	private static byte[] buffer = null;
	
	public DownloadAssets(MainActivity _act){
		act = _act;
	}
	
	public static Long copyFileOrDir(Context c, String path) {
	    AssetManager assetManager = c.getAssets();
	    String assets[] = null;
	    try {
	        assets = assetManager.list(path);
	        if (assets.length == 0) {
	            return DownloadAssets.copyFile(c, path);
	        } else {
	            String fullPath = Utils.getCachePath(c) + path;
	            File dir = new File(fullPath);
	            if (!dir.exists())
	                dir.mkdir();
	            for (int i = 0; i < assets.length; ++i) {
	                Long result = DownloadAssets.copyFileOrDir(c, path + "/" + assets[i]);
	                if(result > 0) return 1l;
	            }
	        }
	    } catch (IOException ex) {
	    	ex.printStackTrace();
	        Log.e("tag", "I/O Exception", ex);
	        return 1l;
	    }
	    return 0l;
	}
	
	private static Long copyFile(Context c, String filename) {
	    AssetManager assetManager = c.getAssets();

	    InputStream in = null;
	    OutputStream out = null;
	    try {
	        in = assetManager.open(filename);
	        in = new BufferedInputStream(in, 8192);
	        
	        String newFileName = Utils.getCachePath(c) + filename;
	        out = new FileOutputStream(newFileName);
	        out = new BufferedOutputStream(out, 8192);

	        int read;
	        while ((read = in.read(buffer)) != -1) {
	            out.write(buffer, 0, read);
	        }
	        in.close();
	        in = null;
	        out.flush();
	        out.close();
	        out = null;
	    } catch (Exception e) {
	    	e.printStackTrace();
	        Log.e("tag", e.getMessage());
	        return 1l;
	    }
	    return 0l;

	}

	protected Long doInBackground(Object... params) {
		Utils.resRawToFilesDir(act,R.array.schemes, Scheme.DIRECTORY_SCHEME);
		Utils.resRawToFilesDir(act, R.array.weapons, Weapon.DIRECTORY_WEAPON);
		Utils.resRawToFilesDir(act, R.array.teams, Team.DIRECTORY_TEAMS);
		buffer = new byte[8192];//allocate the buffer
		return DownloadAssets.copyFileOrDir(act, "Data");
	}
	
	protected void onPostExecute(Long result){
		act.onAssetsDownloaded(result == 0);
		buffer = null;
	}
}
