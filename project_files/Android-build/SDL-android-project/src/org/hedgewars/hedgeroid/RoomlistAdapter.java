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

import java.util.Comparator;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Datastructures.Room;
import org.hedgewars.hedgeroid.Datastructures.RoomWithId;
import org.hedgewars.hedgeroid.util.ObservableTreeMapAdapter;

import android.content.Context;
import android.content.res.Resources;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

/**
 * Displays the list of all rooms in the lobby
 */
public class RoomlistAdapter extends ObservableTreeMapAdapter<String, RoomWithId> {
    private Context context;

    public RoomlistAdapter(Context context) {
        this.context = context;
    }

    @Override
    protected Comparator<RoomWithId> getEntryOrder() {
        return RoomWithId.NEWEST_FIRST_ORDER;
    }

    @Override
    public long getItemId(int position) {
        return getItem(position).id;
    }

    @Override
    public boolean hasStableIds() {
        return true;
    }

    private static CharSequence formatExtra(Resources res, Room room) {
        String ownermsg = res.getString(R.string.roomlist_owner, room.owner);
        String mapmsg = res.getString(R.string.roomlist_map, room.formatMapName(res));
        String scheme = room.scheme.equals(room.weapons) ? room.scheme : room.scheme + " / " + room.weapons;
        String schememsg = res.getString(R.string.roomlist_scheme, scheme);
        return ownermsg + ". " + mapmsg + ", " + schememsg;
    }

    public View getView(int position, View convertView, ViewGroup parent) {
        View v = convertView;
        if (v == null) {
            LayoutInflater vi = LayoutInflater.from(context);
            v = vi.inflate(R.layout.listview_room, null);
        }

        Room room = getItem(position).room;
        int iconRes = room.inProgress ? R.drawable.roomlist_ingame : R.drawable.roomlist_preparing;

        if(v.findViewById(android.R.id.text1) == null) {
            // Tabular room list
            TextView roomnameView = (TextView)v.findViewById(R.id.roomname);
            TextView playerCountView = (TextView)v.findViewById(R.id.playercount);
            TextView teamCountView = (TextView)v.findViewById(R.id.teamcount);
            TextView ownerView = (TextView)v.findViewById(R.id.owner);
            TextView mapView = (TextView)v.findViewById(R.id.map);
            TextView schemeView = (TextView)v.findViewById(R.id.scheme);
            TextView weaponView = (TextView)v.findViewById(R.id.weapons);

            roomnameView.setCompoundDrawablesWithIntrinsicBounds(iconRes, 0, 0, 0);
            roomnameView.setText(room.name);
            if(playerCountView != null) {
                playerCountView.setText(String.valueOf(room.playerCount));
            }
            if(teamCountView != null) {
                teamCountView.setText(String.valueOf(room.teamCount));
            }
            ownerView.setText(room.owner);
            mapView.setText(room.formatMapName(context.getResources()));
            schemeView.setText(room.scheme);
            weaponView.setText(room.weapons);
        } else {
            // Small room list
            TextView v1 = (TextView)v.findViewById(android.R.id.text1);
            TextView v2 = (TextView)v.findViewById(android.R.id.text2);

            v1.setCompoundDrawablesWithIntrinsicBounds(iconRes, 0, 0, 0);
            v1.setText(room.name);
            v2.setText(formatExtra(context.getResources(), room));
        }

        return v;
    }
}