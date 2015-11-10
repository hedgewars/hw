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

import android.os.Handler;
import android.os.Looper;
import android.os.Message;

/**
 * This class allows you to define a runnable that is called when there has been
 * no activity for a set amount of time, where activity is determined by calls
 * to the activity() method of the handler. It is used to update the map preview
 * when there have been no updates to the relevant map information for a time,
 * to prevent triggering several updates at once when different parts of the
 * information change.
 */
public final class CalmDownHandler extends Handler {
    int runningMessagesCounter = 0;
    final Runnable inactivityRunnable;
    final long inactivityMs;
    boolean stopped;

    public CalmDownHandler(Looper looper, Runnable runnable, long inactivityMs) {
        super(looper);
        this.inactivityRunnable = runnable;
        this.inactivityMs = inactivityMs;
    }

    public void activity() {
        runningMessagesCounter++;
        sendMessageDelayed(obtainMessage(), inactivityMs);
    }

    @Override
    public void handleMessage(Message msg) {
        runningMessagesCounter--;
        if(runningMessagesCounter==0 && !stopped) {
            inactivityRunnable.run();
        }
    }

    public void stop() {
        stopped = true;
    }
}