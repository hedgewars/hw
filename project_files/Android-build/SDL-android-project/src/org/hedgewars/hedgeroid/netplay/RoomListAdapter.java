package org.hedgewars.hedgeroid.netplay;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import org.hedgewars.hedgeroid.R;

import android.content.Context;
import android.content.res.Resources;
import android.database.DataSetObserver;
import android.util.Pair;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;

public class RoomlistAdapter extends BaseAdapter {
	private List<Pair<Room, Long>> rooms = new ArrayList<Pair<Room, Long>>();
	private Context context;
	private Roomlist roomlist;
	
	private DataSetObserver observer = new DataSetObserver() {
		@Override
		public void onChanged() {
			reloadFromList(roomlist);
		}
		
		@Override
		public void onInvalidated() {
			invalidate();
		}
	};
	
	public RoomlistAdapter(Context context) {
		this.context = context;
	}
	
	public int getCount() {
		return rooms.size();
	}

	public Room getItem(int position) {
		return rooms.get(position).first;
	}

	public long getItemId(int position) {
		return rooms.get(position).second;
	}

	public boolean hasStableIds() {
		return true;
	}

	public void setList(Roomlist roomlist) {
		if(this.roomlist != null) {
			this.roomlist.unregisterObserver(observer);
		}
		this.roomlist = roomlist;
		this.roomlist.registerObserver(observer);
		reloadFromList(roomlist);
	}
	
	public void invalidate() {
		if(roomlist != null) {
			roomlist.unregisterObserver(observer);
		}
		roomlist = null;
		notifyDataSetInvalidated();
	}
	
	private void reloadFromList(Roomlist list) {
		rooms = new ArrayList<Pair<Room, Long>>(roomlist.getMap().values());
		Collections.sort(rooms, RoomAgeComparator.INSTANCE);
		notifyDataSetChanged();
	}
	
	private static CharSequence formatExtra(Resources res, Room room) {
		String ownermsg = res.getString(R.string.roomlist_owner, room.owner);
		String mapmsg = res.getString(R.string.roomlist_map, Room.formatMapName(res, room.map));
		String scheme = room.scheme.equals(room.weapons) ? room.scheme : room.scheme + " / " + room.weapons;
		String schememsg = res.getString(R.string.roomlist_scheme, scheme);
		return ownermsg + ". " + mapmsg + ", " + schememsg;
	}
	
	public View getView(int position, View convertView, ViewGroup parent) {
		View v = convertView;
		if (v == null) {
			LayoutInflater vi = LayoutInflater.from(context);
			v = vi.inflate(R.layout.listview_room, null);
		}
		
		Room room = rooms.get(position).first;
		int iconRes = room.inProgress ? R.drawable.roomlist_ingame : R.drawable.roomlist_preparing;
		
		if(v.findViewById(android.R.id.text1) == null) {
			// Tabular room list
			TextView roomnameView = (TextView)v.findViewById(R.id.roomname);
			TextView playerCountView = (TextView)v.findViewById(R.id.playercount);
			TextView teamCountView = (TextView)v.findViewById(R.id.teamcount);
			TextView ownerView = (TextView)v.findViewById(R.id.owner);
			TextView mapView = (TextView)v.findViewById(R.id.map);
			TextView schemeView = (TextView)v.findViewById(R.id.scheme);
			TextView weaponView = (TextView)v.findViewById(R.id.weapons);
			
			roomnameView.setCompoundDrawablesWithIntrinsicBounds(iconRes, 0, 0, 0);
			roomnameView.setText(room.name);
			if(playerCountView != null) {
				playerCountView.setText(String.valueOf(room.playerCount));
			}
			if(teamCountView != null) {
				teamCountView.setText(String.valueOf(room.teamCount));
			}
			ownerView.setText(room.owner);
			mapView.setText(Room.formatMapName(context.getResources(), room.map));
			schemeView.setText(room.scheme);
			weaponView.setText(room.weapons);
		} else {
			// Small room list
			TextView v1 = (TextView)v.findViewById(android.R.id.text1);
			TextView v2 = (TextView)v.findViewById(android.R.id.text2);
			
			v1.setCompoundDrawablesWithIntrinsicBounds(iconRes, 0, 0, 0);
			v1.setText(room.name);
			v2.setText(formatExtra(context.getResources(), room));
		}
		
		return v;
	}
	
	private static final class RoomAgeComparator implements Comparator<Pair<Room, Long>> {
		public static final RoomAgeComparator INSTANCE = new RoomAgeComparator();
		public int compare(Pair<Room, Long> lhs, Pair<Room, Long> rhs) {
			return rhs.second.compareTo(lhs.second);
		}
	}
}