package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.Datastructures.Player;
import org.hedgewars.hedgeroid.netplay.RoomPlayerlist.PlayerInRoom;

import android.util.Log;

public class RoomPlayerlist extends ObservableTreeMap<String, PlayerInRoom> {
	private long nextId = 1;
	
	public void addPlayerWithNewId(String name) {
		put(name, new PlayerInRoom(new Player(name), nextId++, false));
	}
	
	public void setReady(String name, boolean ready) {
		PlayerInRoom oldEntry = get(name);
		if(oldEntry==null) {
			Log.e("RoomPlayerlist", "Setting readystate for unknown player "+name);
		} else {
			put(name, new PlayerInRoom(oldEntry.player, oldEntry.id, ready));
		}
	}
	
	// Immutable
	public static class PlayerInRoom {
		public final Player player;
		public final long id;
		public final boolean ready;
		
		public PlayerInRoom(Player player, long id, boolean ready) {
			this.player = player;
			this.id = id;
			this.ready = ready;
		}
	}
}
