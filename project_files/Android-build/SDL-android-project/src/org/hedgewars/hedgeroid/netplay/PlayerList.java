package org.hedgewars.hedgeroid.netplay;

import java.util.Collections;
import java.util.Map;
import java.util.TreeMap;

import android.database.DataSetObservable;
import android.util.Pair;

public class Playerlist extends DataSetObservable {
	private long nextId = 1;
	private Map<String, Pair<Player, Long>> players = new TreeMap<String, Pair<Player, Long>>();
	
	public void addPlayerWithNewId(String name) {
		players.put(name, Pair.create(new Player(name), nextId++));
		notifyChanged();
	}
	
	public void removePlayer(String name) {
		if(players.remove(name) != null) {
			notifyChanged();
		}
	}

	public void clear() {
		if(!players.isEmpty()) {
			players.clear();
			notifyChanged();
		}
	}

	public Map<String, Pair<Player, Long>> getMap() {
		return Collections.unmodifiableMap(players);
	}
}
