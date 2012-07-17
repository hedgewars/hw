package org.hedgewars.hedgeroid.netplay;

import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;

public class PlayerList {
	private List<Player> list = new LinkedList<Player>();
	private List<Observer> observers = new LinkedList<Observer>();
	private long nextId = 1;
	
	public List<Player> getList() {
		return Collections.unmodifiableList(list);
	}
	
	public void observePlayerList(Observer plo) {
		observers.add(plo);
	}
	
	public void unobservePlayerList(Observer plo) {
		observers.remove(plo);
	}
	
	void addPlayer(String name) {
		Player p = new Player(name, nextId++);
		list.add(p);
		List<Player> unmodifiableList = Collections.unmodifiableList(list);
		for(Observer o : observers) {
			o.itemAdded(unmodifiableList, p);
		}
	}
	
	void removePlayer(String name) {
		for(Iterator<Player> iter = list.iterator(); iter.hasNext();) {
			Player p = iter.next();
			if(name.equals(p.name)) {
				iter.remove();
				List<Player> unmodifiableList = Collections.unmodifiableList(list);
				for(Observer o : observers) {
					o.itemDeleted(unmodifiableList, p);
				}
			}
		}
	}

	public static interface Observer {
		void itemAdded(List<Player> newList, Player added);
		void itemDeleted(List<Player> newList, Player deleted);
	}
}
