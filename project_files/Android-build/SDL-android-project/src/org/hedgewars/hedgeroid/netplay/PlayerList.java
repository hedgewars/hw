package org.hedgewars.hedgeroid.netplay;

import java.util.Collections;
import java.util.Map;
import java.util.TreeMap;

import android.database.DataSetObservable;

public class PlayerList extends DataSetObservable {
	private long nextId = 1;
	private Map<String, Player> players = new TreeMap<String, Player>();
	
	public void addPlayerWithNewId(String name) {
		Player p = new Player(name, nextId++);
		players.put(name, p);
		notifyChanged();
	}
	
	public void removePlayer(String name) {
		if(players.remove(name) != null) {
			notifyChanged();
		}
	}

	public Map<String, Player> getMap() {
		return Collections.unmodifiableMap(players);
	}
}
