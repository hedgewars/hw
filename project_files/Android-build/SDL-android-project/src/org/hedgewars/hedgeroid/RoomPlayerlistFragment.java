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
import org.hedgewars.hedgeroid.Datastructures.Player;
import org.hedgewars.hedgeroid.Datastructures.PlayerInRoom;
import org.hedgewars.hedgeroid.netplay.Netplay;

import android.os.Bundle;
import android.support.v4.app.ListFragment;
import android.view.ContextMenu;
import android.view.ContextMenu.ContextMenuInfo;
import android.view.LayoutInflater;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.AdapterContextMenuInfo;
import android.widget.AdapterView.OnItemClickListener;

public class RoomPlayerlistFragment extends ListFragment implements OnItemClickListener {
    private Netplay netplay;
    private RoomPlayerlistAdapter adapter;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        netplay = Netplay.getAppInstance(getActivity().getApplicationContext());
        adapter = new RoomPlayerlistAdapter();
        adapter.setSource(netplay.roomPlayerlist);
        setListAdapter(adapter);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        adapter.invalidate();
    }

    @Override
    public void onActivityCreated(Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        registerForContextMenu(getListView());
        getListView().setOnItemClickListener(this);
    }

    @Override
    public void onCreateContextMenu(ContextMenu menu, View v,
            ContextMenuInfo menuInfo) {
        super.onCreateContextMenu(menu, v, menuInfo);
        AdapterContextMenuInfo info = (AdapterContextMenuInfo)menuInfo;
        String playerName = adapter.getItem(info.position).player.name;

        MenuInflater inflater = getActivity().getMenuInflater();
        inflater.inflate(R.menu.room_playerlist_context, menu);
        if(netplay.isChief() && !playerName.equals(netplay.getPlayerName())) {
            inflater.inflate(R.menu.room_playerlist_chief_context, menu);
        }
        menu.setHeaderIcon(R.drawable.human);
        menu.setHeaderTitle(playerName);
    }

    @Override
    public boolean onContextItemSelected(MenuItem item) {
        AdapterContextMenuInfo info = (AdapterContextMenuInfo)item.getMenuInfo();
        PlayerInRoom player = adapter.getItem(info.position);
        switch(item.getItemId()) {
        case R.id.player_info:
            netplay.sendPlayerInfoQuery(player.player.name);
            return true;
        case R.id.player_kick:
            netplay.sendKick(player.player.name);
            return true;
        default:
            return super.onContextItemSelected(item);
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
            Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_playerlist, container, false);
    }

    public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
        Player player = adapter.getItem(position).player;
        if(player.name.equals(netplay.getPlayerName())) {
            netplay.sendToggleReady();
        }
    }
}
