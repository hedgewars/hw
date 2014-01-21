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

package org.hedgewars.hedgeroid.frontlib;

import java.util.Collections;

import android.util.Log;

import com.sun.jna.Library;
import com.sun.jna.Native;

public class Flib {
    static {
        System.loadLibrary("SDL");
        System.loadLibrary("SDL_net");
        System.setProperty("jna.encoding", "UTF8"); // Ugly global setting, but it seems JNA doesn't allow setting this per-library...
    }
    public static final Frontlib INSTANCE = (Frontlib)Native.loadLibrary("frontlib", Frontlib.class, Collections.singletonMap(Library.OPTION_TYPE_MAPPER, AndroidTypeMapper.INSTANCE));

    static {
        // We'll just do it here and never quit it again...
        if(Flib.INSTANCE.flib_init() != 0) {
            throw new RuntimeException("Unable to initialize frontlib");
        }
    }

    // Hook frontlib logging into Android logging
    private static final Frontlib.LogCallback logCb = new Frontlib.LogCallback() {
        public void callback(int level, String message) {
            if(level >= Frontlib.FLIB_LOGLEVEL_ERROR) {
                Log.e("Frontlib", message);
            } else if(level == Frontlib.FLIB_LOGLEVEL_WARNING){
                Log.w("Frontlib", message);
            } else if(level == Frontlib.FLIB_LOGLEVEL_INFO){
                Log.i("Frontlib", message);
            } else if(level <= Frontlib.FLIB_LOGLEVEL_DEBUG){
                Log.d("Frontlib", message);
            }
        }
    };
    static {
        INSTANCE.flib_log_setLevel(Frontlib.FLIB_LOGLEVEL_INFO);
        INSTANCE.flib_log_setCallback(logCb);
    }
}
