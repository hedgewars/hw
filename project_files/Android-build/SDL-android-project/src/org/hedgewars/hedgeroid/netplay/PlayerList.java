package org.hedgewars.hedgeroid.netplay;

public class PlayerList extends ObservableLinkedHashMap<String, Player> {
	private long nextId = 1;
	
	public void addPlayerWithNewId(String name) {
		Player p = new Player(name, nextId++);
		put(name, p);
	}
	
	public interface Observer extends ObservableLinkedHashMap.Observer<String, Player> {}
}
