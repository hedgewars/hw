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

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

import org.hedgewars.hedgeroid.Downloader.DownloadAssets;
import org.hedgewars.hedgeroid.Downloader.DownloadListActivity;
import org.hedgewars.hedgeroid.netplay.LobbyActivity;
import org.hedgewars.hedgeroid.netplay.NetplayService;

import android.app.AlertDialog;
import android.app.Dialog;
import android.app.ProgressDialog;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

public class MainActivity extends FragmentActivity {
	private static final int DIALOG_NO_SDCARD = 0;
	private static final int DIALOG_START_NETGAME = 1;
	
	private static final String PREF_PLAYERNAME = "playerName";
	
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
				if(!NetplayService.isActive()) {
					showDialog(DIALOG_START_NETGAME);
				} else {
					startActivity(new Intent(getApplicationContext(), LobbyActivity.class));
				}
			}
		});

		if(!Utils.isDataPathAvailable()){
			showDialog(DIALOG_NO_SDCARD);
		} else {
			String existingVersion = "";
			try {
				File versionFile = new File(Utils.getCachePath(this), "assetsversion.txt");
				existingVersion = Utils.readToString(new FileInputStream(versionFile));
			} catch(IOException e) {
			}
			
			String newVersion = "";
			try {
				newVersion = Utils.readToString(getAssets().open("assetsversion.txt"));
			} catch(IOException e) {
			}
			
			if(!existingVersion.equals(newVersion)) {
				DownloadAssets assetsAsyncTask = new DownloadAssets(this);
				assetsDialog = ProgressDialog.show(this, "Please wait a moment", "Moving assets to SD card...");
				assetsAsyncTask.execute();
			}
		}
	}

	public Dialog onCreateDialog(int id, Bundle args){
		switch(id) {
		case DIALOG_NO_SDCARD:
			return createNoSdcardDialog();
		case DIALOG_START_NETGAME:
			return createStartNetgameDialog();
		default:
			throw new IndexOutOfBoundsException();
		}
	}

	private Dialog createNoSdcardDialog() {
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

	private Dialog createStartNetgameDialog() {
		final SharedPreferences prefs = getPreferences(MODE_PRIVATE);
		final String playerName = prefs.getString(PREF_PLAYERNAME, "Player");
		final EditText editText = new EditText(this);
		final AlertDialog.Builder builder = new AlertDialog.Builder(this);
		
		editText.setText(playerName);
		editText.setHint(R.string.start_netgame_dialog_playername_hint);
		editText.setId(android.R.id.text1);

		builder.setTitle(R.string.start_netgame_dialog_title);
		builder.setMessage(R.string.start_netgame_dialog_message);
		builder.setView(editText);
		builder.setNegativeButton(android.R.string.cancel, new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int which) {
				editText.setText(playerName);
			}
		});
		builder.setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int which) {
				String playerName = editText.getText().toString();
				if(playerName.length() > 0) {
					Editor edit = prefs.edit();
					edit.putString(PREF_PLAYERNAME, playerName);
					edit.commit();
					
					Intent netplayServiceIntent = new Intent(getApplicationContext(), NetplayService.class);
					netplayServiceIntent.putExtra(NetplayService.EXTRA_PLAYERNAME, playerName);
					startService(netplayServiceIntent);
					
					LocalBroadcastManager.getInstance(getApplicationContext()).registerReceiver(connectedReceiver, new IntentFilter(NetplayService.ACTION_CONNECTED));
				}
			}
		});

		return builder.create();
	}
	
	public void onAssetsDownloaded(boolean result){
		if(!result){
			Toast.makeText(this, R.string.download_failed, Toast.LENGTH_LONG).show();
		}
		assetsDialog.dismiss();
	}

	private OnClickListener downloadClicker = new OnClickListener(){
		public void onClick(View v){
			startActivityForResult(new Intent(getApplicationContext(), DownloadListActivity.class), 0);
		}
	};

	private OnClickListener startGameClicker = new OnClickListener(){
		public void onClick(View v){
			startActivity(new Intent(getApplicationContext(), StartGameActivity.class));
		}
	};
	
	private BroadcastReceiver connectedReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			startActivity(new Intent(getApplicationContext(), LobbyActivity.class));
		}
	};
}
