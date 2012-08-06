package org.hedgewars.hedgeroid.Datastructures;

public final class Player {
	public final String name;
	
	public Player(String name) {
		this.name = name;
	}

	@Override
	public String toString() {
		return "Player [name=" + name + "]";
	}
}
