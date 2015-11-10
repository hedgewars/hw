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
import java.util.Collection;
import java.util.List;
import java.util.Map;

import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.Datastructures.TeamIngameAttributes;

import android.os.Bundle;
import android.support.v4.app.ListFragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.Button;

public class TeamlistFragment extends ListFragment implements TeamlistAdapter.Listener {
    private TeamlistAdapter adapter;
    private Button addTeamButton;
    private RoomStateManager stateManager;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        try {
            stateManager = ((RoomStateManager.Provider)getActivity()).getRoomStateManager();
        } catch(ClassCastException e) {
            throw new RuntimeException("Hosting activity must implement RoomStateManager.Provider.", e);
        }
        adapter = new TeamlistAdapter();
        adapter.updateTeamlist(stateManager.getTeams().values());
        adapter.setColorHogcountEnabled(stateManager.getChiefStatus());
        adapter.setListener(this);
        setListAdapter(adapter);
        stateManager.addListener(roomStateChangeListener);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
            Bundle savedInstanceState) {
        View v = inflater.inflate(R.layout.fragment_teamlist, container, false);
        addTeamButton = (Button)v.findViewById(R.id.addTeamButton);
        addTeamButton.setOnClickListener(new OnClickListener() {
            public void onClick(View v) {
                new TeamAddDialog(getCurrentTeamNames()).show(getFragmentManager(), "team_add_dialog");
            }
        });

        addTeamButton.setEnabled(stateManager.getTeams().size() < Team.maxNumberOfTeams);

        return v;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        adapter.setListener(null);
        stateManager.removeListener(roomStateChangeListener);
    }

    private Collection<String> getCurrentTeamNames() {
        List<String> names = new ArrayList<String>();
        for(TeamInGame team : stateManager.getTeams().values()) {
            names.add(team.team.name);
        }
        return names;
    }

    public void onColorClicked(TeamInGame team) {
        stateManager.changeTeamColorIndex(team.team.name, (team.ingameAttribs.colorIndex+1)%TeamIngameAttributes.TEAM_COLORS.length);
    }

    public void onHogcountClicked(TeamInGame team) {
        int newHogCount = team.ingameAttribs.hogCount+1;
        if(newHogCount>Team.HEDGEHOGS_PER_TEAM) {
            newHogCount = 1;
        }
        stateManager.changeTeamHogCount(team.team.name, newHogCount);
    }

    public void onTeamClicked(TeamInGame team) {
        stateManager.requestRemoveTeam(team.team.name);
    }

    private final RoomStateManager.Listener roomStateChangeListener = new RoomStateManager.ListenerAdapter() {
        @Override
        public void onChiefStatusChanged(boolean isChief) {
            adapter.setColorHogcountEnabled(isChief);
        };

        @Override
        public void onTeamsChanged(Map<String, TeamInGame> teams) {
            adapter.updateTeamlist(teams.values());
            addTeamButton.setEnabled(teams.size() < Team.maxNumberOfTeams);
        };
    };
}
