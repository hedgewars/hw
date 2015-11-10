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
package org.hedgewars.hedgeroid;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

import org.hedgewars.hedgeroid.Downloader.DownloadAssets;
import org.hedgewars.hedgeroid.Downloader.DownloadListActivity;
import org.hedgewars.hedgeroid.netplay.Netplay;
import org.hedgewars.hedgeroid.netplay.Netplay.State;
import org.hedgewars.hedgeroid.util.FileUtils;

import android.app.AlertDialog;
import android.app.Dialog;
import android.app.ProgressDialog;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentManager;
import android.support.v4.content.LocalBroadcastManager;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.Toast;

public class MainActivity extends FragmentActivity {
    private static final int DIALOG_NO_SDCARD = 0;

    private LocalBroadcastManager broadcastManager;
    private ProgressDialog assetsDialog;

    public void onCreate(Bundle sis){
        super.onCreate(sis);
        setContentView(R.layout.activity_main);

        broadcastManager = LocalBroadcastManager.getInstance(getApplicationContext());
        Button startLocalGame = (Button)findViewById(R.id.startGame);
        Button startNetGame = (Button)findViewById(R.id.joinLobby);

        startLocalGame.setOnClickListener(startGameListener);
        startNetGame.setOnClickListener(startNetGameListener);

        if(!FileUtils.isDataPathAvailable()){
            showDialog(DIALOG_NO_SDCARD);
        } else {
            String existingVersion = "";
            try {
                File versionFile = new File(FileUtils.getCachePath(this), "assetsversion.txt");
                existingVersion = FileUtils.readToString(new FileInputStream(versionFile));
            } catch(IOException e) {
            }

            String newVersion = "";
            try {
                newVersion = FileUtils.readToString(getAssets().open("assetsversion.txt"));
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
    protected void onResume() {
        super.onResume();
        broadcastManager.registerReceiver(connectedReceiver, new IntentFilter(Netplay.ACTION_CONNECTED));
        broadcastManager.registerReceiver(connectionFailedReceiver, new IntentFilter(Netplay.ACTION_DISCONNECTED));
        broadcastManager.registerReceiver(passwordRequestedReceiver, new IntentFilter(Netplay.ACTION_PASSWORD_REQUESTED));
    }

    @Override
    protected void onPause() {
        super.onPause();
        broadcastManager.unregisterReceiver(connectedReceiver);
        broadcastManager.unregisterReceiver(connectionFailedReceiver);
        broadcastManager.unregisterReceiver(passwordRequestedReceiver);
        Netplay netplay = Netplay.getAppInstance(getApplicationContext());
        if(netplay.getState() == State.CONNECTING) {
            netplay.disconnect();
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        super.onCreateOptionsMenu(menu);
        getMenuInflater().inflate(R.menu.main_options, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch(item.getItemId()) {
        case R.id.download:
            startActivityForResult(new Intent(this, DownloadListActivity.class), 0);
            return true;
        case R.id.preferences:
            Toast.makeText(this, R.string.not_implemented_yet, Toast.LENGTH_SHORT).show();
            return true;
        case R.id.edit_weaponsets:
            startActivity(new Intent(this, WeaponsetListActivity.class));
            return true;
        case R.id.edit_teams:
            startActivity(new Intent(this, TeamListActivity.class));
            return true;
        default:
            return super.onOptionsItemSelected(item);
        }
    }

    public Dialog onCreateDialog(int id, Bundle args){
        switch(id) {
        case DIALOG_NO_SDCARD:
            return createNoSdcardDialog();
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

    public void onAssetsDownloaded(boolean result){
        if(!result){
            Toast.makeText(this, R.string.download_failed, Toast.LENGTH_LONG).show();
        }
        assetsDialog.dismiss();
    }

    private final OnClickListener startGameListener = new OnClickListener(){
        public void onClick(View v){
            startActivity(new Intent(getApplicationContext(), LocalRoomActivity.class));
        }
    };

    private final OnClickListener startNetGameListener = new OnClickListener() {
        public void onClick(View v) {
            State state = Netplay.getAppInstance(getApplicationContext()).getState();
            switch(state) {
            case NOT_CONNECTED:
                FragmentManager fm = getSupportFragmentManager();
                StartNetgameDialog startNetgameDialog = new StartNetgameDialog();
                startNetgameDialog.show(fm, "start_netgame_dialog");
                break;
            case CONNECTING:
                onNetConnectingStarted();
                break;
            default:
                startActivity(new Intent(getApplicationContext(), LobbyActivity.class));
                break;
            }
        }
    };

    private BroadcastReceiver connectedReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            startActivity(new Intent(getApplicationContext(), LobbyActivity.class));
        }
    };

    private BroadcastReceiver connectionFailedReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if(intent.getBooleanExtra(Netplay.EXTRA_HAS_ERROR, true)) {
                Toast.makeText(getApplicationContext(), intent.getStringExtra(Netplay.EXTRA_MESSAGE), Toast.LENGTH_LONG).show();
            }
        }
    };

    private BroadcastReceiver passwordRequestedReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            FragmentManager fm = getSupportFragmentManager();
            PasswordDialog passwordDialog = new PasswordDialog(intent.getStringExtra(Netplay.EXTRA_PLAYERNAME));
            passwordDialog.show(fm, "fragment_password_dialog");
        }
    };

    public void onNetConnectingStarted() {
        FragmentManager fm = getSupportFragmentManager();
        ConnectingDialog connectingDialog = new ConnectingDialog();
        connectingDialog.show(fm, "fragment_connecting_dialog");
    }
}
