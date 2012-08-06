package org.hedgewars.hedgeroid.netplay;

import java.util.Map;
import java.util.TreeMap;

import org.hedgewars.hedgeroid.Datastructures.RoomlistRoom;

import android.util.Pair;

public class Roomlist extends ObservableTreeMap<String, Pair<RoomlistRoom, Long>> {
	private long nextId = 1;
	
	public void updateList(RoomlistRoom[] newRooms) {
		Map<String, Pair<RoomlistRoom, Long>> newMap = new TreeMap<String, Pair<RoomlistRoom, Long>>();
		for(RoomlistRoom room : newRooms) {
			Pair<RoomlistRoom, Long> oldEntry = get(room.name);
			if(oldEntry == null) {
				newMap.put(room.name, Pair.create(room, nextId++));
			} else {
				newMap.put(room.name, Pair.create(room, oldEntry.second));
			}
		}
		replaceContent(newMap);
	}
	
	public void addRoomWithNewId(RoomlistRoom room) {
		put(room.name, Pair.create(room, nextId++));
	}
	
	public void updateRoom(String name, RoomlistRoom room) {
		Pair<RoomlistRoom, Long> oldEntry = get(name);
		if(oldEntry == null) {
			addRoomWithNewId(room);
		} else {
			remove(name);
			put(room.name, Pair.create(room, oldEntry.second));
		}
	}
}
