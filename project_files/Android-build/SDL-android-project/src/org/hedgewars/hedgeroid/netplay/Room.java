package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.R;

import android.content.res.Resources;

public class Room {
	public static final String MAP_REGULAR = "+rnd+";
	public static final String MAP_MAZE = "+maze+";
	public static final String MAP_DRAWN = "+drawn+";
	
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

	public static String formatMapName(Resources res, String map) {
		if(map.charAt(0)=='+') {
			if(map.equals(MAP_REGULAR)) {
				return res.getString(R.string.map_regular);
			} else if(map.equals(MAP_MAZE)) {
				return res.getString(R.string.map_maze);
			} else if(map.equals(MAP_DRAWN)) {
				return res.getString(R.string.map_drawn);
			}
		}
		return map;
	}
}
