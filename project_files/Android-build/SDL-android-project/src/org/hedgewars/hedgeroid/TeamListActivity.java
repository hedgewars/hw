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

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.hedgewars.hedgeroid.Datastructures.FrontendDataUtils;
import org.hedgewars.hedgeroid.Datastructures.Team;

import android.app.ListActivity;
import android.content.Intent;
import android.os.Bundle;
import android.view.ContextMenu;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.AdapterView;
import android.widget.AdapterView.AdapterContextMenuInfo;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ImageButton;
import android.widget.SimpleAdapter;

public class TeamListActivity extends ListActivity implements OnItemClickListener {
    private List<Team> teams;
    private ImageButton addButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_teamlist);
        addButton = (ImageButton)findViewById(R.id.btnAdd);
        addButton.setOnClickListener(new OnClickListener() {
            public void onClick(View v) {
                editTeam(null);
            }
        });
    }

    @Override
    public void onResume() {
        super.onResume();
        updateList();
        getListView().setOnItemClickListener(this);
        registerForContextMenu(getListView());
    }

    public void onItemClick(AdapterView<?> adapterView, View v, int position, long arg3) {
        editTeam(teams.get(position).name);
    }

    @Override
    public void onCreateContextMenu(ContextMenu menu, View v, ContextMenu.ContextMenuInfo menuinfo){
        menu.add(ContextMenu.NONE, 0, ContextMenu.NONE, R.string.edit);
        menu.add(ContextMenu.NONE, 1, ContextMenu.NONE, R.string.delete);
    }

    @Override
    public boolean onContextItemSelected(MenuItem item){
        AdapterView.AdapterContextMenuInfo menuInfo = (AdapterContextMenuInfo) item.getMenuInfo();
        int position = menuInfo.position;
        Team team = teams.get(position);
        switch(item.getItemId()){
        case 0:
            editTeam(team.name);
            return true;
        case 1:
            Team.getTeamfileByName(getApplicationContext(), team.name).delete();
            updateList();
            return true;
        }
        return false;
    }

    private void updateList() {
        teams = FrontendDataUtils.getTeams(getApplicationContext());
        Collections.sort(teams, Team.NAME_ORDER);
        SimpleAdapter adapter = new SimpleAdapter(this, teamsToMaps(teams), R.layout.team_selection_entry_simple, new String[]{"txt", "img"}, new int[]{R.id.txtName, R.id.imgDifficulty});
        setListAdapter(adapter);
    }

    private void editTeam(String teamName) {
        Intent i = new Intent(this, TeamCreatorActivity.class);
        i.putExtra(TeamCreatorActivity.PARAMETER_EXISTING_TEAMNAME, teamName);
        startActivity(i);
    }

    private static final int[] botlevelDrawables = new int[] {
        R.drawable.human, R.drawable.bot5, R.drawable.bot4, R.drawable.bot3, R.drawable.bot2, R.drawable.bot1
    };

    private List<Map<String, ?>> teamsToMaps(List<Team> teams) {
        List<Map<String, ?>> result = new ArrayList<Map<String,?>>();
        for(Team t : teams) {
            HashMap<String, Object> map = new HashMap<String, Object>();
            map.put("team", t);
            map.put("txt", t.name);
            int botlevel = t.hogs.get(0).level;
            if(botlevel<0 || botlevel>=botlevelDrawables.length) {
                map.put("img", R.drawable.bot1);
            } else {
                map.put("img", botlevelDrawables[botlevel]);
            }
            result.add(map);
        }
        return result;
    }
}
