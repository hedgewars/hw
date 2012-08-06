package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.Datastructures.Player;

import android.util.Pair;

public class LobbyPlayerlist extends ObservableTreeMap<String, Pair<Player, Long>> {
	private long nextId = 1;
	
	public void addPlayerWithNewId(String name) {
		put(name, Pair.create(new Player(name), nextId++));
	}
}
