package org.hedgewars.hedgeroid.netplay;

import java.util.Map;
import java.util.TreeMap;

import org.hedgewars.hedgeroid.Datastructures.Room;
import org.hedgewars.hedgeroid.Datastructures.RoomWithId;
import org.hedgewars.hedgeroid.util.ObservableTreeMap;

public class Roomlist extends ObservableTreeMap<String, RoomWithId> {
	private long nextId = 1;
	
	public void updateList(Room[] newRooms) {
		Map<String, RoomWithId> newMap = new TreeMap<String, RoomWithId>();
		for(Room room : newRooms) {
			RoomWithId oldEntry = get(room.name);
			if(oldEntry == null) {
				newMap.put(room.name, new RoomWithId(room, nextId++));
			} else {
				newMap.put(room.name, new RoomWithId(room, oldEntry.id));
			}
		}
		replaceContent(newMap);
	}
	
	public void addRoomWithNewId(Room room) {
		put(room.name, new RoomWithId(room, nextId++));
	}
	
	public void updateRoom(String name, Room room) {
		RoomWithId oldEntry = get(name);
		if(oldEntry == null) {
			addRoomWithNewId(room);
		} else {
			remove(name);
			put(room.name, new RoomWithId(room, oldEntry.id));
		}
	}
}
