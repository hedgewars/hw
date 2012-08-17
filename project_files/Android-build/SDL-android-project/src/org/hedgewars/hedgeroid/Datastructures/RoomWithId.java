package org.hedgewars.hedgeroid.Datastructures;

import java.util.Comparator;

public final class RoomWithId {
	public final Room room;
	public final long id;
	
	public RoomWithId(Room room, long id) {
		this.room = room;
		this.id = id;
	}

	@Override
	public String toString() {
		return "RoomWithId [room=" + room + ", id=" + id + "]";
	}
	
	public static final Comparator<RoomWithId> NEWEST_FIRST_ORDER = new Comparator<RoomWithId>() {
		public int compare(RoomWithId lhs, RoomWithId rhs) {
			return rhs.id<lhs.id ? -1 : rhs.id>lhs.id ? 1 : 0;
		}
	};
}