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
