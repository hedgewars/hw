/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011-2012 Richard Deurwaarder <xeli@xelification.com>
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

package org.hedgewars.hedgeroid.EngineProtocol;

public class PascalExports {
    public static Object engineMutex = new Object();

    static{
        System.loadLibrary("SDL");
        System.loadLibrary("SDL_image");
        System.loadLibrary("mikmod");
        System.loadLibrary("SDL_net");
        System.loadLibrary("SDL_mixer");
        System.loadLibrary("SDL_ttf");
        System.loadLibrary("lua5.1");
        System.loadLibrary("physfs");
        System.loadLibrary("physlayer");
        System.loadLibrary("hwengine");
    }

    public static native int HWgetMaxNumberOfTeams();
    private static native void HWGenLandPreview(int port);

    public static void synchronizedGenLandPreview(int port) {
        synchronized(engineMutex) {
            HWGenLandPreview(port);
        }
    }

}
