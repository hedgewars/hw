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

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import android.database.DataSetObserver;
import android.widget.BaseAdapter;

public abstract class ObservableTreeMapAdapter<K,V> extends BaseAdapter {
    private boolean sourceChanged = true;
    private List<V> entries = new ArrayList<V>();
    private ObservableTreeMap<K, V> source;

    private DataSetObserver observer = new DataSetObserver() {
        @Override
        public void onChanged() {
            sourceChanged = true;
            notifyDataSetChanged();
        }

        @Override
        public void onInvalidated() {
            invalidate();
        }
    };

    abstract protected Comparator<V> getEntryOrder();

    protected List<V> getEntries() {
        if(sourceChanged) {
            entries.clear();
            entries.addAll(source.getMap().values());
            Collections.sort(entries, getEntryOrder());
            sourceChanged = false;
        }
        return entries;
    }

    public int getCount() {
        return getEntries().size();
    }

    public V getItem(int position) {
        return getEntries().get(position);
    }

    public long getItemId(int position) {
        return position;
    }

    @Override
    public boolean hasStableIds() {
        return false;
    }

    public void setSource(ObservableTreeMap<K,V> source) {
        if(this.source != null) {
            this.source.unregisterObserver(observer);
        }
        this.source = source;
        this.source.registerObserver(observer);
        sourceChanged = true;
        notifyDataSetChanged();
    }

    public void invalidate() {
        if(source != null) {
            source.unregisterObserver(observer);
        }
        source = null;
        notifyDataSetInvalidated();
    }
}