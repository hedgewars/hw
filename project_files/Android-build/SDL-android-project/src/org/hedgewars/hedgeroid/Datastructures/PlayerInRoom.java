package org.hedgewars.hedgeroid.Datastructures;

public final class PlayerInRoom {
	public final Player player;
	public final boolean ready;
	
	public PlayerInRoom(Player player, boolean ready) {
		this.player = player;
		this.ready = ready;
	}

	@Override
	public String toString() {
		return "PlayerInRoom [player=" + player + ", ready=" + ready + "]";
	}
}