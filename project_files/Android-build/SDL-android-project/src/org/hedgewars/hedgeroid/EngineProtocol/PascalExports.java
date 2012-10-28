/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011-2012 Richard Deurwaarder <xeli@xelification.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

package org.hedgewars.hedgeroid.EngineProtocol;

public class PascalExports {

	static{
		System.loadLibrary("SDL");
		System.loadLibrary("SDL_image");
		System.loadLibrary("mikmod");
		System.loadLibrary("SDL_net");
		System.loadLibrary("SDL_mixer");
		System.loadLibrary("SDL_ttf");
		System.loadLibrary("lua5.1");
		System.loadLibrary("hwengine");
	}
	
	public static native int HWversionInfoNetProto();
	public static native String HWversionInfoVersion();
	public static native int HWgetNumberOfWeapons();
	public static native int HWgetMaxNumberOfTeams();
	public static native int HWgetMaxNumberOfHogs();
        public static native int HWterminate(boolean b);	
}
