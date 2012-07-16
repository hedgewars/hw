package org.hedgewars.hedgeroid.netplay;

import java.util.Comparator;

public class Player {
	public static final ByNameComparator nameComparator = new ByNameComparator(); 

	public final String name;
	public final long playerId;
	public final boolean friend;
	public final boolean ignored;
	
	public Player(String name, long playerId, boolean friend, boolean ignored) {
		super();
		this.name = name;
		this.playerId = playerId;
		this.friend = friend;
		this.ignored = ignored;
	}
	
	private static class ByNameComparator implements Comparator<Player> {
		public int compare(Player lhs, Player rhs) {
			return lhs.name.compareToIgnoreCase(rhs.name);
		}
	}
}