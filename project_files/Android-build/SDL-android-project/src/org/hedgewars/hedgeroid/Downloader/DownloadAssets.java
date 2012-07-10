package org.hedgewars.hedgeroid.Downloader;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;

import org.hedgewars.hedgeroid.MainActivity;
import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Utils;
import org.hedgewars.hedgeroid.Datastructures.Scheme;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.Weapon;

import android.content.res.AssetManager;
import android.os.AsyncTask;
import android.util.Log;

public class DownloadAssets extends AsyncTask<Object, Long, Long>{
	private final MainActivity act;
	
	public DownloadAssets(MainActivity _act){
		act = _act;
	}
	
	private static void copyFileOrDir(AssetManager assetManager, File target, String assetPath) throws IOException {
		try {
			Utils.writeStreamToFile(assetManager.open(assetPath), target);
		} catch(FileNotFoundException e) {
			/*
			 * I can't find a better way to figure out whether an asset entry is
			 * a file or a directory. Checking if assetManager.list(assetPath)
			 * is empty is a bit cleaner, but SLOW.
			 */
			if (!target.isDirectory() && !target.mkdir()) {
				throw new IOException("Unable to create directory "+target);
			}
			for (String asset : assetManager.list(assetPath)) {
				DownloadAssets.copyFileOrDir(assetManager, new File(target, asset), assetPath + "/" + asset);
			}
		}
	}
	
	@Override
	protected Long doInBackground(Object... params) {
		try {
			Utils.resRawToFilesDir(act, R.array.schemes, Scheme.DIRECTORY_SCHEME);
			Utils.resRawToFilesDir(act, R.array.weapons, Weapon.DIRECTORY_WEAPON);
			Utils.resRawToFilesDir(act, R.array.teams, Team.DIRECTORY_TEAMS);
			DownloadAssets.copyFileOrDir(act.getAssets(), Utils.getDataPathFile(act), "Data");
			return 0l;
		} catch(IOException e) {
			Log.e("org.hedgewars.hedgeroid", e.getMessage(), e);
			return 1l;
		}
	}
	
	@Override
	protected void onPostExecute(Long result){
		act.onAssetsDownloaded(result == 0);
	}
}
