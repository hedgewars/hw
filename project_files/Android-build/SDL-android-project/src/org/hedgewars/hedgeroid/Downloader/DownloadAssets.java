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

public class DownloadAssets extends AsyncTask<Object, Long, Boolean> {
	private static final String VERSION_FILENAME = "assetsversion.txt";
	private final MainActivity act;
	
	public DownloadAssets(MainActivity act){
		this.act = act;
	}
	
	private void copyFileOrDir(AssetManager assetManager, File target, String assetPath) throws IOException {
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
				copyFileOrDir(assetManager, new File(target, asset), assetPath + "/" + asset);
			}
		}
	}
	
	@Override
	protected Boolean doInBackground(Object... params) {
		try {
			Utils.resRawToFilesDir(act, R.array.schemes, Scheme.DIRECTORY_SCHEME);
			Utils.resRawToFilesDir(act, R.array.weapons, Weapon.DIRECTORY_WEAPON);
			Utils.resRawToFilesDir(act, R.array.teams, Team.DIRECTORY_TEAMS);
			copyFileOrDir(act.getAssets(), Utils.getDataPathFile(act), "Data");
			copyFileOrDir(act.getAssets(), new File(Utils.getCachePath(act), VERSION_FILENAME), VERSION_FILENAME);
			return Boolean.TRUE;
		} catch(IOException e) {
			Log.e("DownloadAssets", e.getMessage(), e);
			return Boolean.FALSE;
		}
	}
	
	@Override
	protected void onPostExecute(Boolean result){
		act.onAssetsDownloaded(result);
	}
}
