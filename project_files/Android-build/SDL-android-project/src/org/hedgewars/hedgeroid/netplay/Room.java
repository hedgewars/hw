package org.hedgewars.hedgeroid.netplay;

import java.util.Comparator;

import org.hedgewars.hedgeroid.R;

import android.content.res.Resources;

public class Room {
	public static final String MAP_REGULAR = "+rnd+";
	public static final String MAP_MAZE = "+maze+";
	public static final String MAP_DRAWN = "+drawn+";
	public static final Comparator<Room> ID_COMPARATOR = new ByIdComparator();
	
	public final String name, map, scheme, weapons, owner;
	public final int playerCount, teamCount;
	public final boolean inProgress;
	public final long id;	// for ListView
	
	public Room(String name, String map, String scheme, String weapons,
			String owner, int playerCount, int teamCount, boolean inProgress, long id) {
		this.name = name;
		this.map = map;
		this.scheme = scheme;
		this.weapons = weapons;
		this.owner = owner;
		this.playerCount = playerCount;
		this.teamCount = teamCount;
		this.inProgress = inProgress;
		this.id = id;
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
	
	private static final class ByIdComparator implements Comparator<Room> {
		public int compare(Room lhs, Room rhs) {
			return lhs.id<rhs.id ? -1 : lhs.id>rhs.id ? 1 : 0;
		}
	}
}
