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

package org.hedgewars.hedgeroid.util;

import org.hedgewars.hedgeroid.R;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.TabHost;
import android.widget.TextView;

public final class UiUtils {
    private UiUtils() {
        throw new AssertionError("This class is not meant to be instantiated");
    }

    public static View createVerticalTabIndicator(TabHost tabHost, int label, int icon) {
        LayoutInflater inflater = (LayoutInflater) tabHost.getContext()
                .getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        View view = inflater.inflate(R.layout.tab_indicator_vertical,
                tabHost.getTabWidget(), false);

        final TextView tv = (TextView) view.findViewById(R.id.title);
        tv.setText(label);

        if (icon != 0) {
            ImageView iconView = (ImageView) view.findViewById(R.id.icon);
            iconView.setImageResource(icon);
        }

        return view;
    }
}
