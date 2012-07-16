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

import org.hedgewars.hedgeroid.Downloader.DownloadAssets;
import org.hedgewars.hedgeroid.Downloader.DownloadListActivity;
import org.hedgewars.hedgeroid.netplay.LobbyActivity;
import org.hedgewars.hedgeroid.netplay.TestActivity;

import android.app.AlertDialog;
import android.app.Dialog;
import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager.NameNotFoundException;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.support.v4.app.FragmentActivity;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.Toast;

public class MainActivity extends FragmentActivity {
	private Button downloader, startGame;
	private ProgressDialog assetsDialog;

	public void onCreate(Bundle sis){
		super.onCreate(sis);
		setContentView(R.layout.main);

		downloader = (Button)findViewById(R.id.downloader);
		startGame = (Button)findViewById(R.id.startGame);
		Button joinLobby = (Button)findViewById(R.id.joinLobby);

		downloader.setOnClickListener(downloadClicker);
		startGame.setOnClickListener(startGameClicker);
		joinLobby.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				startActivity(new Intent(getApplicationContext(), TestActivity.class));
			}
		});

		if(!Utils.isDataPathAvailable()){
			showDialog(0);
		} else {
			int versionCode = 0;
			try {
				versionCode = this.getPackageManager().getPackageInfo(this.getPackageName(), 0).versionCode;
			} catch (NameNotFoundException e) {

			}
			boolean assetsCopied = PreferenceManager.getDefaultSharedPreferences(this).getInt("latestAssets", 0) >= versionCode;

			if(!assetsCopied){
				DownloadAssets assetsAsyncTask = new DownloadAssets(this);
				assetsDialog = ProgressDialog.show(this, "Please wait a moment", "Moving assets to SD card...");
				assetsAsyncTask.execute();
			}
		}
	}

	public Dialog onCreateDialog(int id, Bundle args){
		AlertDialog.Builder builder = new AlertDialog.Builder(this);
		builder.setTitle(R.string.sdcard_not_mounted_title);
		builder.setMessage(R.string.sdcard_not_mounted);
		builder.setNegativeButton(android.R.string.ok, new DialogInterface.OnClickListener(){
			public void onClick(DialogInterface dialog, int which) {
				finish();				
			}
		});

		return builder.create();
	}

	public void onAssetsDownloaded(boolean result){
		if(result){
			try {
				int versionCode = this.getPackageManager().getPackageInfo(this.getPackageName(), 0).versionCode;
				PreferenceManager.getDefaultSharedPreferences(this).edit().putInt("latestAssets", versionCode).commit();
			} catch (NameNotFoundException e) {}
			
		}else{
			Toast.makeText(this, R.string.download_failed, Toast.LENGTH_LONG);
		}
		assetsDialog.dismiss();
	}

	private OnClickListener downloadClicker = new OnClickListener(){
		public void onClick(View v){
			//startActivityForResult(new Intent(getApplicationContext(), DownloadActivity.class), 0);
			startActivityForResult(new Intent(getApplicationContext(), DownloadListActivity.class), 0);
		}
	};

	private OnClickListener startGameClicker = new OnClickListener(){
		public void onClick(View v){
			startActivity(new Intent(getApplicationContext(), StartGameActivity.class));
		}
	};
}
