package org.hedgewars.hedgeroid.netplay;

import java.util.Collections;
import java.util.Map;
import java.util.TreeMap;

import android.database.DataSetObservable;
import android.util.Log;
import android.util.Pair;

public class RoomList extends DataSetObservable {
	private long nextId = 1;
	private Map<String, Pair<Room, Long>> rooms = new TreeMap<String, Pair<Room, Long>>();
	
	public void updateList(Room[] newRooms) {
		Map<String, Pair<Room, Long>> newMap = new TreeMap<String, Pair<Room, Long>>();
		for(Room room : newRooms) {
			Pair<Room, Long> oldEntry = rooms.get(room.name);
			if(oldEntry == null) {
				newMap.put(room.name, Pair.create(room, nextId++));
			} else {
				newMap.put(room.name, Pair.create(room, oldEntry.second));
			}
		}
		rooms = newMap;
		notifyChanged();
	}
	
	public void addRoomWithNewId(Room room) {
		rooms.put(room.name, Pair.create(room, nextId++));
		notifyChanged();
	}
	
	public void updateRoom(String name, Room room) {
		Pair<Room, Long> oldEntry = rooms.get(name);
		if(oldEntry == null) {
			Log.e("RoomList", "Received update for unknown room: "+name);
			rooms.put(room.name, Pair.create(room, nextId++));
		} else {
			if(!name.equals(room.name)) {
				rooms.remove(name);
			}
			rooms.put(room.name, Pair.create(room, oldEntry.second));
		}
		notifyChanged();
	}
	
	public void removeRoom(String name) {
		if(rooms.remove(name) != null) {
			notifyChanged();
		}
	}
	
	public void clear() {
		if(!rooms.isEmpty()) {
			rooms.clear();
			notifyChanged();
		}
	}
	
	public Map<String, Pair<Room, Long>> getMap() {
		return Collections.unmodifiableMap(rooms);
	}
}
