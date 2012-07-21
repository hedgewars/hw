package org.hedgewars.hedgeroid.netplay;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.netplay.RoomList.Observer;

import android.content.Context;
import android.content.res.Resources;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;

public class RoomListAdapter extends BaseAdapter implements Observer {
	private List<Room> rooms = new ArrayList<Room>();
	private Context context;
	
	public RoomListAdapter(Context context) {
		this.context = context;
	}
	
	public int getCount() {
		return rooms.size();
	}

	public Object getItem(int position) {
		return rooms.get(position);
	}

	public long getItemId(int position) {
		return rooms.get(position).id;
	}

	public boolean hasStableIds() {
		return true;
	}

	public void setList(Collection<Room> rooms) {
		this.rooms = new ArrayList<Room>(rooms);
		Collections.reverse(this.rooms); // We want to show the newest rooms first
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
		
		Room room = rooms.get(position);
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

	public void itemAdded(Map<String, Room> map, String key, Room value) {
		setList(map.values());
	}

	public void itemRemoved(Map<String, Room> map, String key, Room oldValue) {
		setList(map.values());
	}

	public void itemReplaced(Map<String, Room> map, String key, Room oldValue,
			Room newValue) {
		setList(map.values());
	}
}