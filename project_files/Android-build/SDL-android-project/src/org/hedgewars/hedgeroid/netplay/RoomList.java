package org.hedgewars.hedgeroid.netplay;

import java.util.Collections;
import java.util.Map;
import java.util.TreeMap;

import org.hedgewars.hedgeroid.netplay.JnaFrontlib.RoomPtr;

import android.database.DataSetObservable;
import android.util.Log;

public class RoomList extends DataSetObservable {
	private long nextId = 1;
	private Map<String, Room> rooms = new TreeMap<String, Room>();
	
	public void updateList(RoomPtr[] roomPtrs) {
		Map<String, Room> newMap = new TreeMap<String, Room>();
		for(RoomPtr roomPtr : roomPtrs) {
			JnaFrontlib.Room room = roomPtr.deref();
			Room oldEntry = rooms.get(room.name);
			if(oldEntry == null) {
				newMap.put(room.name, buildRoom(room, nextId++));
			} else {
				newMap.put(room.name, buildRoom(room, oldEntry.id));
			}
		}
		rooms = newMap;
		notifyChanged();
	}
	
	public void addRoomWithNewId(RoomPtr roomPtr) {
		putRoom(roomPtr.deref(), nextId++);
		notifyChanged();
	}
	
	public void updateRoom(String name, RoomPtr roomPtr) {
		JnaFrontlib.Room room = roomPtr.deref();
		Room oldEntry = rooms.get(name);
		if(oldEntry == null) {
			Log.e("RoomList", "Received update for unknown room: "+name);
			putRoom(room, nextId++);
		} else {
			if(!name.equals(room.name)) {
				rooms.remove(name);
			}
			putRoom(room, oldEntry.id);
		}
		notifyChanged();
	}
	
	public void removeRoom(String name) {
		if(rooms.remove(name) != null) {
			notifyChanged();
		}
	}
	
	public Map<String, Room> getMap() {
		return Collections.unmodifiableMap(rooms);
	}
	
	private void putRoom(JnaFrontlib.Room r, long id) {
		rooms.put(r.name, buildRoom(r, id));
	}
	
	private Room buildRoom(JnaFrontlib.Room r, long id) {
		return new Room(r.name, r.map, r.scheme, r.weapons, r.owner, r.playerCount, r.teamCount, r.inProgress, id);
	}
}
