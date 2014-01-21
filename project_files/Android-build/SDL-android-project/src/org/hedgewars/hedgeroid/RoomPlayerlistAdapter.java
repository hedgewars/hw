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
import org.hedgewars.hedgeroid.Datastructures.PlayerInRoom;
import org.hedgewars.hedgeroid.util.ObservableTreeMapAdapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

public class RoomPlayerlistAdapter extends ObservableTreeMapAdapter<String, PlayerInRoom> {
    @Override
    protected Comparator<PlayerInRoom> getEntryOrder() {
        return AlphabeticalOrderComparator.INSTANCE;
    }

    public View getView(int position, View convertView, ViewGroup parent) {
        View v = convertView;
        if (v == null) {
            LayoutInflater vi = LayoutInflater.from(parent.getContext());
            v = vi.inflate(R.layout.listview_player, null);
        }

        PlayerInRoom player = getItem(position);
        TextView username = (TextView) v.findViewById(android.R.id.text1);
        username.setText(player.player.name);
        int readyDrawable = player.ready ? R.drawable.lightbulb_on : R.drawable.lightbulb_off;
        username.setCompoundDrawablesWithIntrinsicBounds(readyDrawable, 0, 0, 0);
        return v;
    }

    private static final class AlphabeticalOrderComparator implements Comparator<PlayerInRoom> {
        public static final AlphabeticalOrderComparator INSTANCE = new AlphabeticalOrderComparator();
        public int compare(PlayerInRoom lhs, PlayerInRoom rhs) {
            return lhs.player.name.compareToIgnoreCase(rhs.player.name);
        };
    }
}