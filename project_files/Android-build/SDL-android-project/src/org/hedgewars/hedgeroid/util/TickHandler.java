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
 * This class handles regularly calling a specified runnable
 * on the looper provided in the constructor. The first call
 * occurs without delay (though still via the looper), all
 * following calls are delayed by (approximately) the interval.
 * The interval can be changed at any time, which will cause
 * an immediate execution of the runnable again.
 */
public class TickHandler extends Handler {
    private final Runnable callback;
    private int messageId;
    private long interval;
    private boolean running;

    public TickHandler(Looper looper, long interval, Runnable callback) {
        super(looper);
        this.callback = callback;
        this.interval = interval;
    }

    public synchronized void stop() {
        messageId++;
        running = false;
    }

    public synchronized void start() {
        messageId++;
        sendMessage(obtainMessage(messageId));
        running = true;
    }

    public synchronized void setInterval(long interval) {
        this.interval = interval;
        if(running) {
            start();
        }
    }

    @Override
    public synchronized void handleMessage(Message msg) {
        if(msg.what == messageId) {
            callback.run();
        }
        if(msg.what == messageId) {
            sendMessageDelayed(obtainMessage(messageId), interval);
        }
    }
}