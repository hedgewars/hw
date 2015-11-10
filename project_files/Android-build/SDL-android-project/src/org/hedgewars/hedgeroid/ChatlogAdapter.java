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

import org.hedgewars.hedgeroid.netplay.MessageLog;

import android.content.Context;
import android.text.method.LinkMovementMethod;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AbsListView.LayoutParams;
import android.widget.BaseAdapter;
import android.widget.TextView;

/**
 * Optimization: ListView is smart enough to try re-using the same view for an item
 * with the same ID, but it still calls getView for those items when the list changes.
 * Since lines with a given ID never change in our chatlog, we can avoid the effort
 * of TextView.setText in many cases by checking if the view is already set up for the
 * line with the right ID - but to do that, the view needs to remember the ID it's
 * holding the text for. That's what the LoglineView does.
 */
class LoglineView extends TextView {
    long chatlogId = -1;

    public LoglineView(Context context) {
        super(context);
    }
}

/**
 * For performance reasons, the chatlog is implemented as ListView instead of a
 * single TextView (although I later learned that TextView might also have
 * facilities for efficient appending with limited backlog... oh well, this
 * works). Every chat line is a line in the ListView, and this adapter prepares
 * the textviews from a messagelog in an efficient way.
 */
public class ChatlogAdapter extends BaseAdapter implements MessageLog.Listener {
    long idOffset = 0;
    private List<CharSequence> log = new ArrayList<CharSequence>();
    private Context context;

    public ChatlogAdapter(Context context) {
        this.context = context;
    }

    public int getCount() {
        return log.size();
    }

    public Object getItem(int position) {
        return log.get(position);
    }

    public long getItemId(int position) {
        return position+idOffset;
    }

    public boolean hasStableIds() {
        return true;
    }

    public void clear() {
        idOffset += log.size();
        log.clear();
        notifyDataSetChanged();
    }

    public void lineAdded(CharSequence text) {
        log.add(text);
        notifyDataSetChanged();
    }

    public void lineRemoved() {
        log.remove(0);
        idOffset += 1;
        notifyDataSetChanged();
    }

    public void setLog(Collection<CharSequence> log) {
        idOffset += log.size();
        this.log = new ArrayList<CharSequence>(log);
        notifyDataSetChanged();
    }

    public View getView(int position, View convertView, ViewGroup parent) {
        LoglineView v = (LoglineView)convertView;
        if (v == null) {
            v = new LoglineView(context);
            v.setLayoutParams(new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.WRAP_CONTENT));
            v.setMovementMethod(LinkMovementMethod.getInstance());
        }
        long id = getItemId(position);
        if(id != v.chatlogId) {
            v.setText(log.get(position));
            v.chatlogId = id;
        }
        return v;
    }
}