package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.netplay.JnaFrontlib.RoomPtr;

import android.util.Log;

public class RoomList extends ObservableLinkedHashMap<String, Room> {
	private long nextId = 1;
	
	public void addRoomWithNewId(RoomPtr roomPtr) {
		JnaFrontlib.Room r = roomPtr.deref();
		Log.d("RoomList", "Adding room "+r.name);
		long id = nextId++;
		put(r.name, new Room(r.name, r.map, r.scheme, r.weapons, r.owner, r.playerCount, r.teamCount, r.inProgress, id));
	}
	
	public void updateRoom(String name, RoomPtr roomPtr) {
		Room oldEntry = getMap().get(name);
		if(oldEntry == null) {
			Log.e("RoomList", "Received update for unknown room: "+name);
		} else {
			JnaFrontlib.Room r = roomPtr.deref();
			/*
			 *  TODO Room renames are handled as re-insertions which push the room
			 *  up to the top of the list again. Should maybe be revisited (sorting by ID is an option)
			 */
			if(!r.name.equals(oldEntry.name)) {
				remove(oldEntry.name);
			}
			put(r.name, new Room(r.name, r.map, r.scheme, r.weapons, r.owner, r.playerCount, r.teamCount, r.inProgress, oldEntry.id));
		}
	}

	public static interface Observer extends ObservableLinkedHashMap.Observer<String, Room> { }
}
