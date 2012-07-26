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
import org.hedgewars.hedgeroid.netplay.Netplay;
import org.hedgewars.hedgeroid.netplay.Netplay.State;

import android.app.AlertDialog;
import android.app.Dialog;
import android.app.ProgressDialog;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.DialogInterface.OnCancelListener;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.support.v4.content.LocalBroadcastManager;
import android.text.InputType;
import android.text.method.PasswordTransformationMethod;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

public class MainActivity extends FragmentActivity {
	private static final int DIALOG_NO_SDCARD = 0;
	private static final int DIALOG_START_NETGAME = 1;
	private static final int DIALOG_CONNECTING = 2;
	private static final int DIALOG_PASSWORD = 3;
	
	private static final String PREF_PLAYERNAME = "playerName";
	
	private LocalBroadcastManager broadcastManager;
	
	private Button downloader, startGame;
	private ProgressDialog assetsDialog;
	private String passwordedUsername; // TODO ugly - move dialogs to fragments to get rid of e.g. this

	public void onCreate(Bundle sis){
		super.onCreate(sis);
		if(sis != null) {
			passwordedUsername = sis.getString(PREF_PLAYERNAME);
		}
		setContentView(R.layout.main);

		broadcastManager = LocalBroadcastManager.getInstance(getApplicationContext());
		downloader = (Button)findViewById(R.id.downloader);
		startGame = (Button)findViewById(R.id.startGame);
		Button joinLobby = (Button)findViewById(R.id.joinLobby);

		downloader.setOnClickListener(downloadClicker);
		startGame.setOnClickListener(startGameClicker);
		joinLobby.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				State state = Netplay.getAppInstance(getApplicationContext()).getState();
				switch(state) {
				case NOT_CONNECTED:
					showDialog(DIALOG_START_NETGAME);
					break;
				case CONNECTING:
					startWaitingForConnection();
					break;
				default:
					startActivity(new Intent(getApplicationContext(), LobbyActivity.class));
					break;
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

	@Override
	protected void onSaveInstanceState(Bundle outState) {
		super.onSaveInstanceState(outState);
		outState.putString(PREF_PLAYERNAME, passwordedUsername);
	}
	
	@Override
	protected void onDestroy() {
		super.onDestroy();
		stopWaitingForConnection();
	}
	
	@Override
	protected void onStart() {
		super.onStart();
		Netplay.getAppInstance(getApplicationContext()).requestFastTicks();
	}
	
	@Override
	protected void onStop() {
		super.onStop();
		Netplay netplay = Netplay.getAppInstance(getApplicationContext());
		netplay.unrequestFastTicks();
		if(netplay.getState() == State.CONNECTING) {
			netplay.disconnect();
		}
	}
	
	public Dialog onCreateDialog(int id, Bundle args){
		switch(id) {
		case DIALOG_NO_SDCARD:
			return createNoSdcardDialog();
		case DIALOG_START_NETGAME:
			return createStartNetgameDialog();
		case DIALOG_CONNECTING:
			return createConnectingDialog();
		case DIALOG_PASSWORD:
			return createPasswordDialog();
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
					
					startWaitingForConnection();
					Netplay.getAppInstance(getApplicationContext()).connectToDefaultServer(playerName);
				}
			}
		});

		return builder.create();
	}
	
	private Dialog createConnectingDialog() {
		ProgressDialog dialog = new ProgressDialog(this);
		dialog.setOnCancelListener(new OnCancelListener() {
			public void onCancel(DialogInterface dialog) {
				Netplay.getAppInstance(getApplicationContext()).disconnect();
			}
		});
		dialog.setIndeterminate(true);
		dialog.setProgressStyle(ProgressDialog.STYLE_SPINNER);
		dialog.setTitle(R.string.dialog_connecting_title);
		dialog.setMessage(getString(R.string.dialog_connecting_message));
		return dialog;
	}
	
	private Dialog createPasswordDialog() {
		final AlertDialog.Builder builder = new AlertDialog.Builder(this);
		final EditText editText = new EditText(this);
		editText.setHint(R.string.dialog_password_hint);
		editText.setFreezesText(true);
		editText.setId(android.R.id.text1);
		editText.setInputType(InputType.TYPE_TEXT_VARIATION_PASSWORD);
		editText.setTransformationMethod(PasswordTransformationMethod.getInstance());
		builder.setView(editText);
		builder.setTitle(R.string.dialog_password_title);
		builder.setMessage(getString(R.string.dialog_password_message, passwordedUsername));
		builder.setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int which) {
				String password = editText.getText().toString();
				editText.setText("");
				Netplay.getAppInstance(getApplicationContext()).sendPassword(password);
			}
		});
		builder.setOnCancelListener(new OnCancelListener() {
			public void onCancel(DialogInterface dialog) {
				Netplay.getAppInstance(getApplicationContext()).disconnect();
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
	
	private void startWaitingForConnection() {
		broadcastManager.registerReceiver(connectedReceiver, new IntentFilter(Netplay.ACTION_CONNECTED));
		broadcastManager.registerReceiver(connectionFailedReceiver, new IntentFilter(Netplay.ACTION_DISCONNECTED));
		broadcastManager.registerReceiver(passwordRequestedReceiver, new IntentFilter(Netplay.ACTION_PASSWORD_REQUESTED));
		showDialog(DIALOG_CONNECTING);
	}
	
	private void stopWaitingForConnection() {
		broadcastManager.unregisterReceiver(connectedReceiver);
		broadcastManager.unregisterReceiver(connectionFailedReceiver);
		broadcastManager.unregisterReceiver(passwordRequestedReceiver);
	}
	
	private BroadcastReceiver connectedReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			stopWaitingForConnection();
			dismissDialog(DIALOG_CONNECTING);
			startActivity(new Intent(getApplicationContext(), LobbyActivity.class));
		}
	};
	
	private BroadcastReceiver connectionFailedReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			stopWaitingForConnection();
			dismissDialog(DIALOG_CONNECTING);
			if(intent.getBooleanExtra(Netplay.EXTRA_HAS_ERROR, true)) {
				Toast.makeText(getApplicationContext(), intent.getStringExtra(Netplay.EXTRA_MESSAGE), Toast.LENGTH_LONG).show();
			}
		}
	};
	
	private BroadcastReceiver passwordRequestedReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			passwordedUsername = intent.getStringExtra(Netplay.EXTRA_PLAYERNAME);
			showDialog(DIALOG_PASSWORD);
		}
	};
}
