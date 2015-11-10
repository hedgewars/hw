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

import org.hedgewars.hedgeroid.NetplayStateFragment.NetplayStateListener;
import org.hedgewars.hedgeroid.netplay.Netplay;
import org.hedgewars.hedgeroid.netplay.Netplay.State;
import org.hedgewars.hedgeroid.util.TextInputDialog;
import org.hedgewars.hedgeroid.util.TextInputDialog.TextInputDialogListener;
import org.hedgewars.hedgeroid.util.UiUtils;

import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentTransaction;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.LinearLayout;
import android.widget.TabHost;

/**
 * Activity for the server lobby of a hedgewars server. Allows you to chat, join
 * and create rooms and interact with a list of players.
 *
 * Most of the functionality is handled by various fragments.
 */
public class LobbyActivity extends FragmentActivity implements TextInputDialogListener, NetplayStateListener {
    private static final int DIALOG_CREATE_ROOM = 0;

    private TabHost tabHost;
    private Netplay netplay;

    @Override
    protected void onCreate(Bundle icicle) {
        super.onCreate(icicle);

        setContentView(R.layout.activity_lobby);
        ChatFragment chatFragment = (ChatFragment)getSupportFragmentManager().findFragmentById(R.id.chatFragment);
        chatFragment.setInRoom(false);

        FragmentTransaction trans = getSupportFragmentManager().beginTransaction();
        trans.add(new NetplayStateFragment(), "netplayFragment");
        trans.commit();

        netplay = Netplay.getAppInstance(getApplicationContext());

        // Set up a tabbed UI for medium and small screens
        tabHost = (TabHost)findViewById(android.R.id.tabhost);
        if(tabHost != null) {
            tabHost.setup();
            tabHost.getTabWidget().setOrientation(LinearLayout.VERTICAL);

            tabHost.addTab(tabHost.newTabSpec("rooms").setIndicator(UiUtils.createVerticalTabIndicator(tabHost, R.string.lobby_tab_rooms, R.drawable.roomlist_ingame)).setContent(R.id.roomListFragment));
            tabHost.addTab(tabHost.newTabSpec("chat").setIndicator(UiUtils.createVerticalTabIndicator(tabHost, R.string.lobby_tab_chat, R.drawable.edit)).setContent(R.id.chatFragment));
            tabHost.addTab(tabHost.newTabSpec("players").setIndicator(UiUtils.createVerticalTabIndicator(tabHost, R.string.lobby_tab_players, R.drawable.human)).setContent(R.id.playerListFragment));

            if (icicle != null) {
                tabHost.setCurrentTabByTag(icicle.getString("currentTab"));
            }
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        super.onCreateOptionsMenu(menu);
        getMenuInflater().inflate(R.menu.lobby_options, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch(item.getItemId()) {
        case R.id.room_create:
            TextInputDialog dialog = new TextInputDialog(DIALOG_CREATE_ROOM, R.string.dialog_create_room_title, 0, R.string.dialog_create_room_hint);
            dialog.show(getSupportFragmentManager(), "create_room_dialog");
            return true;
        case R.id.disconnect:
            netplay.disconnect();
            return true;
        default:
            return super.onOptionsItemSelected(item);
        }
    }

    @Override
    public void onBackPressed() {
        netplay.disconnect();
    }

    @Override
    protected void onSaveInstanceState(Bundle icicle) {
        super.onSaveInstanceState(icicle);
        if(tabHost != null) {
            icicle.putString("currentTab", tabHost.getCurrentTabTag());
        }
    }

    public void onTextInputDialogSubmitted(int dialogId, String text) {
        if(text != null && text.length()>0) {
            netplay.sendCreateRoom(text);
        }
    }

    public void onTextInputDialogCancelled(int dialogId) {
    }

    public void onNetplayStateChanged(State newState) {
        switch(newState) {
        case CONNECTING:
        case NOT_CONNECTED:
            finish();
            break;
        case ROOM:
            startActivity(new Intent(getApplicationContext(), NetRoomActivity.class));
            break;
        case LOBBY:
            // Do nothing
            break;
        default:
            throw new IllegalStateException("Unknown connection state: "+newState);
        }
    }
}
