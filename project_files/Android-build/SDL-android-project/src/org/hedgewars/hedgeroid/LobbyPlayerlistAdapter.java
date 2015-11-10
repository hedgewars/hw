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
import org.hedgewars.hedgeroid.Datastructures.Player;
import org.hedgewars.hedgeroid.util.ObservableTreeMapAdapter;

import android.graphics.Color;
import android.graphics.Typeface;
import android.text.Spannable;
import android.text.SpannableString;
import android.text.Spanned;
import android.text.style.ForegroundColorSpan;
import android.text.style.StyleSpan;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

/**
 * Simple adapter for displaying the list of players in the lobby.
 */
public class LobbyPlayerlistAdapter extends ObservableTreeMapAdapter<String, Player> {
    @Override
    protected Comparator<Player> getEntryOrder() {
        return Player.ADMIN_NAME_ORDER;
    }

    public View getView(int position, View convertView, ViewGroup parent) {
        View v = convertView;
        if (v == null) {
            LayoutInflater vi = LayoutInflater.from(parent.getContext());
            v = vi.inflate(R.layout.listview_player, null);
        }

        Player player = getItem(position);
        TextView username = (TextView) v.findViewById(android.R.id.text1);
        Spannable spannable = new SpannableString(player.name);
        if(player.registered) {
            spannable.setSpan(new StyleSpan(Typeface.BOLD), 0, spannable.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        }
        if(player.admin) {
            spannable.setSpan(new ForegroundColorSpan(Color.YELLOW), 0, spannable.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        }
        username.setText(spannable);
        return v;
    }
}