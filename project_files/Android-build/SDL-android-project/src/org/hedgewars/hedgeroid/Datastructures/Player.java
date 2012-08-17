package org.hedgewars.hedgeroid.Datastructures;

import java.util.Comparator;

/**
 * Basic information about a player on a server.
 */
public final class Player {
	public final String name;
	public final boolean registered, admin;
	
	public Player(String name, boolean registered, boolean admin) {
		this.name = name;
		this.registered = registered;
		this.admin = admin;
	}

	@Override
	public String toString() {
		return "Player [name=" + name + ", registered=" + registered
				+ ", admin=" + admin + "]";
	}

	public static Comparator<Player> NAME_ORDER = new Comparator<Player>() {
		public int compare(Player lhs, Player rhs) {
			return lhs.name.compareToIgnoreCase(rhs.name);
		}
	};
}
