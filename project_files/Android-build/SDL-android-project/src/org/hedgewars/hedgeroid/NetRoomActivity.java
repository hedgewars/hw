/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
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

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Datastructures.GameConfig;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.NetplayStateFragment.NetplayStateListener;
import org.hedgewars.hedgeroid.netplay.Netplay;
import org.hedgewars.hedgeroid.netplay.RunGameListener;
import org.hedgewars.hedgeroid.netplay.Netplay.State;
import org.hedgewars.hedgeroid.util.UiUtils;

import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentTransaction;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TabHost;

/**
 * This activity is used to set up and start a game on the server.
 */
public class NetRoomActivity extends FragmentActivity implements NetplayStateListener, TeamAddDialog.Listener, RoomStateManager.Provider, RunGameListener {
    private TabHost tabHost;
    private Netplay netplay;
    private RoomStateManager stateManager;
    private Button startButton;

    @Override
    protected void onCreate(Bundle icicle) {
        super.onCreate(icicle);
        netplay = Netplay.getAppInstance(getApplicationContext());
        netplay.registerRunGameListener(this);
        stateManager = netplay.getRoomStateManager();
        stateManager.addListener(roomStateChangeListener);

        setContentView(R.layout.activity_netroom);
        startButton = (Button)findViewById(R.id.startGame);

        ChatFragment chatFragment = (ChatFragment)getSupportFragmentManager().findFragmentById(R.id.chatFragment);
        chatFragment.setInRoom(true);

        FragmentTransaction trans = getSupportFragmentManager().beginTransaction();
        trans.add(new NetplayStateFragment(), "netplayFragment");
        trans.commit();

        startButton.setVisibility(netplay.isChief() ? View.VISIBLE : View.GONE);
        startButton.setOnClickListener(startButtonClickListener);

        // Set up a tabbed UI for medium and small screens
        tabHost = (TabHost)findViewById(android.R.id.tabhost);
        if(tabHost != null) {
            tabHost.setup();
            tabHost.getTabWidget().setOrientation(LinearLayout.VERTICAL);

            tabHost.addTab(tabHost.newTabSpec("map").setIndicator(UiUtils.createVerticalTabIndicator(tabHost, R.string.room_tab_map, 0)).setContent(R.id.mapFragment));
            tabHost.addTab(tabHost.newTabSpec("settings").setIndicator(UiUtils.createVerticalTabIndicator(tabHost, R.string.room_tab_settings, 0)).setContent(R.id.settingsFragment));
            tabHost.addTab(tabHost.newTabSpec("teams").setIndicator(UiUtils.createVerticalTabIndicator(tabHost, R.string.room_tab_teams, 0)).setContent(R.id.teamlistFragment));
            tabHost.addTab(tabHost.newTabSpec("chat").setIndicator(UiUtils.createVerticalTabIndicator(tabHost, R.string.room_tab_chat, 0)).setContent(R.id.chatFragment));
            tabHost.addTab(tabHost.newTabSpec("players").setIndicator(UiUtils.createVerticalTabIndicator(tabHost, R.string.room_tab_players, 0)).setContent(R.id.playerListContainer));

            if (icicle != null) {
                tabHost.setCurrentTabByTag(icicle.getString("currentTab"));
            }
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        stateManager.removeListener(roomStateChangeListener);
        netplay.unregisterRunGameListener(this);
    }

    @Override
    public void onBackPressed() {
        netplay.sendLeaveRoom(null);
    }

    @Override
    protected void onSaveInstanceState(Bundle icicle) {
        super.onSaveInstanceState(icicle);
        if(tabHost != null) {
            icicle.putString("currentTab", tabHost.getCurrentTabTag());
        }
    }

    public void onNetplayStateChanged(State newState) {
        switch(newState) {
        case NOT_CONNECTED:
        case CONNECTING:
        case LOBBY:
            finish();
            break;
        case ROOM:
            // Do nothing
            break;
        default:
            throw new IllegalStateException("Unknown connection state: "+newState);
        }
    }

    public void onTeamAddDialogSubmitted(Team newTeam) {
        stateManager.requestAddTeam(newTeam, TeamInGame.getUnusedOrRandomColorIndex(stateManager.getTeams().values()));
    }

    public RoomStateManager getRoomStateManager() {
        return stateManager;
    }

    private final OnClickListener startButtonClickListener = new OnClickListener() {
        public void onClick(View v) {
            netplay.sendStartGame();
        }
    };

    private final RoomStateManager.Listener roomStateChangeListener = new RoomStateManager.ListenerAdapter() {
        @Override
        public void onChiefStatusChanged(boolean isChief) {
            startButton.setVisibility(isChief ? View.VISIBLE : View.GONE);
        }
    };

    public void runGame(GameConfig config) {
        SDLActivity.startConfig = config;
        SDLActivity.startNetgame = true;
        startActivity(new Intent(this, SDLActivity.class));
    }
}
