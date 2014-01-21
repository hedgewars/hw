/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (C) 2012 Simeon Maxein <smaxein@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

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
