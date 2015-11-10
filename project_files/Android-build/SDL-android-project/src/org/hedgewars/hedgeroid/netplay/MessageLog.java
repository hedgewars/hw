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

package org.hedgewars.hedgeroid.netplay;

import java.util.Collection;
import java.util.Collections;
import java.util.Date;
import java.util.LinkedList;
import java.util.List;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.frontlib.Frontlib;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Typeface;
import android.text.Html;
import android.text.Spannable;
import android.text.SpannableString;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.TextUtils;
import android.text.format.DateFormat;
import android.text.style.ForegroundColorSpan;
import android.text.style.RelativeSizeSpan;
import android.text.style.StyleSpan;
import android.util.Log;

public class MessageLog {
    private static final int BACKLOG_LINES = 200;

    private static final int INFO_COLOR = Color.GRAY;
    private static final int PLAYERINFO_COLOR = Color.GREEN;
    private static final int CHAT_COLOR = Color.GREEN;
    private static final int MECHAT_COLOR = Color.CYAN;
    private static final int WARN_COLOR = Color.RED;
    private static final int ERROR_COLOR = Color.RED;

    private final Context context;
    private List<Listener> observers = new LinkedList<Listener>();
    private List<CharSequence> log = new LinkedList<CharSequence>();

    public MessageLog(Context context) {
        this.context = context;
    }

    private Spanned makeLogTime() {
        String time = DateFormat.getTimeFormat(context).format(new Date());
        return withColor("[" + time + "] ", INFO_COLOR);
    }

    private static Spanned span(CharSequence s, Object o) {
        Spannable spannable = new SpannableString(s);
        spannable.setSpan(o, 0, s.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        return spannable;
    }

    private static Spanned withColor(CharSequence s, int color) {
        return span(s, new ForegroundColorSpan(color));
    }

    private static Spanned bold(CharSequence s) {
        return span(s, new StyleSpan(Typeface.BOLD));
    }

    private void append(CharSequence msg) {
        SpannableStringBuilder ssb = new SpannableStringBuilder();
        ssb.append(makeLogTime()).append(msg);
        appendRaw(ssb);
    }

    private void appendRaw(CharSequence msg) {
        if(log.size() > BACKLOG_LINES) {
            log.remove(0);
            for(Listener o : observers) {
                o.lineRemoved();
            }
        }
        log.add(msg);
        for(Listener o : observers) {
            o.lineAdded(msg);
        }
    }

    void appendPlayerJoin(String playername) {
        append(withColor("***" + context.getResources().getString(R.string.log_player_join, playername), INFO_COLOR));
    }

    void appendPlayerLeave(String playername, String partMsg) {
        String msg = "***";
        if(partMsg != null) {
            msg += context.getResources().getString(R.string.log_player_leave_with_msg, playername, partMsg);
        } else {
            msg += context.getResources().getString(R.string.log_player_leave, playername);
        }
        append(withColor(msg, INFO_COLOR));
    }

    void appendChat(String playerName, String msg) {
        if(msg.startsWith("/me ")) {
            append(withColor("*"+playerName+" "+msg.substring(4), MECHAT_COLOR));
        } else {
            Spanned name = bold(playerName+": ");
            Spanned fullMessage = withColor(TextUtils.concat(name, msg), CHAT_COLOR);
            append(fullMessage);
        }
    }

    void appendMessage(int type, String msg) {
        switch(type) {
        case Frontlib.NETCONN_MSG_TYPE_ERROR:
            append(withColor("***"+msg, ERROR_COLOR));
            break;
        case Frontlib.NETCONN_MSG_TYPE_WARNING:
            append(withColor("***"+msg, WARN_COLOR));
            break;
        case Frontlib.NETCONN_MSG_TYPE_PLAYERINFO:
            append(withColor(msg.replace("\n", " "), PLAYERINFO_COLOR));
            break;
        case Frontlib.NETCONN_MSG_TYPE_SERVERMESSAGE:
            appendRaw(span(TextUtils.concat("\n", Html.fromHtml(msg), "\n"), new RelativeSizeSpan(1.5f)));
            break;
        default:
            Log.e("MessageLog", "Unknown messagetype "+type);
        }
    }

    void clear() {
        for(Listener o : observers) {
            o.clear();
        }
        log.clear();
    }

    public void addListener(Listener o) {
        observers.add(o);
    }

    public void removeListener(Listener o) {
        observers.remove(o);
    }

    public static interface Listener {
        void lineAdded(CharSequence text);
        void lineRemoved();
        void clear();
    }

    public Collection<CharSequence> getLog() {
        return Collections.unmodifiableList(log);
    }
}
