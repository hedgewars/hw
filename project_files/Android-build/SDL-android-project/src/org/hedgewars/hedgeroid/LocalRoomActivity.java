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

import java.util.ArrayList;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

import org.hedgewars.hedgeroid.Datastructures.GameConfig;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.netplay.Netplay;
import org.hedgewars.hedgeroid.util.UiUtils;

import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TabHost;
import android.widget.Toast;

/**
 * This activity is used to set up and start a local game.
 */
public class LocalRoomActivity extends FragmentActivity implements RoomStateManager.Provider, TeamAddDialog.Listener {
    private TabHost tabHost;
    private RoomStateManager stateManager;
    private Button startButton;

    @Override
    protected void onCreate(Bundle icicle) {
        super.onCreate(icicle);
        // TODO find a better central location / way to set up the default scheme and weaponset
        Netplay netplay = Netplay.getAppInstance(getApplicationContext());
        stateManager = new LocalRoomStateManager(netplay.defaultScheme, netplay.defaultWeaponset);

        setContentView(R.layout.activity_localroom);
        startButton = (Button)findViewById(R.id.startGame);

        startButton.setOnClickListener(startButtonClickListener);

        // Set up a tabbed UI for medium and small screens
        tabHost = (TabHost)findViewById(android.R.id.tabhost);
        if(tabHost != null) {
            tabHost.setup();
            tabHost.getTabWidget().setOrientation(LinearLayout.VERTICAL);

            tabHost.addTab(tabHost.newTabSpec("map").setIndicator(UiUtils.createVerticalTabIndicator(tabHost, R.string.room_tab_map, 0)).setContent(R.id.mapFragment));
            tabHost.addTab(tabHost.newTabSpec("settings").setIndicator(UiUtils.createVerticalTabIndicator(tabHost, R.string.room_tab_settings, 0)).setContent(R.id.settingsFragment));
            tabHost.addTab(tabHost.newTabSpec("teams").setIndicator(UiUtils.createVerticalTabIndicator(tabHost, R.string.room_tab_teams, 0)).setContent(R.id.teamlistContainer));

            if (icicle != null) {
                tabHost.setCurrentTabByTag(icicle.getString("currentTab"));
            }
        }
    }

    @Override
    protected void onSaveInstanceState(Bundle icicle) {
        super.onSaveInstanceState(icicle);
        if(tabHost != null) {
            icicle.putString("currentTab", tabHost.getCurrentTabTag());
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
            Map<String, TeamInGame> teams = stateManager.getTeams();
            Set<Integer> clanColors = new TreeSet<Integer>();
            for(TeamInGame t : teams.values()) {
                clanColors.add(t.ingameAttribs.colorIndex);
            }
            if(clanColors.size()<2) {
                if(tabHost != null) {
                    tabHost.setCurrentTabByTag("teams");
                }
                int errortext = teams.size()<2 ? R.string.not_enough_teams : R.string.not_enough_clans;
                Toast.makeText(getApplicationContext(), errortext, Toast.LENGTH_SHORT).show();
                return;
            }

            SDLActivity.startNetgame = false;
            SDLActivity.startConfig = new GameConfig(
                    stateManager.getGameStyle(),
                    stateManager.getScheme(),
                    stateManager.getMapRecipe(),
                    new ArrayList<TeamInGame>(stateManager.getTeams().values()),
                    stateManager.getWeaponset());
            startActivity(new Intent(LocalRoomActivity.this, SDLActivity.class));
        }
    };
}
