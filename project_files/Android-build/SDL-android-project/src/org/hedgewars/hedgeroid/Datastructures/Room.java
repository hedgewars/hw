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

package org.hedgewars.hedgeroid.Datastructures;

import android.content.res.Resources;

/**
 * A room as presented in the roomlist in a server lobby.
 */
public final class Room {
	public final String name, map, scheme, weapons, owner;
	public final int playerCount, teamCount;
	public final boolean inProgress;
	
	public Room(String name, String map, String scheme, String weapons,
			String owner, int playerCount, int teamCount, boolean inProgress) {
		this.name = name;
		this.map = map;
		this.scheme = scheme;
		this.weapons = weapons;
		this.owner = owner;
		this.playerCount = playerCount;
		this.teamCount = teamCount;
		this.inProgress = inProgress;
	}
	
	public String formatMapName(Resources res) {
		return MapRecipe.formatMapName(res, map);
	}

	@Override
	public String toString() {
		return "RoomlistRoom [name=" + name + ", map=" + map + ", scheme="
				+ scheme + ", weapons=" + weapons + ", owner=" + owner
				+ ", playerCount=" + playerCount + ", teamCount=" + teamCount
				+ ", inProgress=" + inProgress + "]";
	}
}
