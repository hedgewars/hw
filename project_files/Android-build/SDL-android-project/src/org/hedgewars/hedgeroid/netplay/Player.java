package org.hedgewars.hedgeroid.netplay;

import java.util.Comparator;

public class Player {
	public static final ByNameComparator nameComparator = new ByNameComparator(); 

	public final String name;
	public final long playerId;
	
	public Player(String name, long playerId) {
		this.name = name;
		this.playerId = playerId;
	}
	
	private static class ByNameComparator implements Comparator<Player> {
		public int compare(Player lhs, Player rhs) {
			return lhs.name.compareToIgnoreCase(rhs.name);
		}
	}
}