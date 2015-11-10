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

package org.hedgewars.hedgeroid.Downloader;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;

import org.hedgewars.hedgeroid.MainActivity;
import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Datastructures.Schemes;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.Weaponsets;
import org.hedgewars.hedgeroid.util.FileUtils;

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
            FileUtils.writeStreamToFile(assetManager.open(assetPath), target);
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
            FileUtils.writeStreamToFile(act.getResources().openRawResource(R.raw.schemes_builtin), Schemes.getBuiltinSchemesFile(act));
            FileUtils.writeStreamToFile(act.getResources().openRawResource(R.raw.weapons_builtin), Weaponsets.getBuiltinWeaponsetsFile(act));
            FileUtils.resRawToFilesDir(act, R.array.teams, R.array.teamFilenames, Team.DIRECTORY_TEAMS);
            copyFileOrDir(act.getAssets(), FileUtils.getDataPathFile(act), "Data");
            copyFileOrDir(act.getAssets(), new File(FileUtils.getCachePath(act), VERSION_FILENAME), VERSION_FILENAME);
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
