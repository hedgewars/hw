package org.hedgewars.hedgeroid.netplay;

import java.util.Comparator;

public class Player {
	public static final ByNameComparator NAME_COMPARATOR = new ByNameComparator(); 

	public final String name;
	public final long id; // for ListView
	
	public Player(String name, long id) {
		this.name = name;
		this.id = id;
	}
	
	private static final class ByNameComparator implements Comparator<Player> {
		public int compare(Player lhs, Player rhs) {
			return lhs.name.compareToIgnoreCase(rhs.name);
		}
	}
}