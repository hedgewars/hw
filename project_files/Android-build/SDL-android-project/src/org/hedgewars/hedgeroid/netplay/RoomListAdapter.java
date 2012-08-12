package org.hedgewars.hedgeroid.netplay;

import java.util.Comparator;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Datastructures.RoomlistRoom;

import android.content.Context;
import android.content.res.Resources;
import android.util.Pair;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

public class RoomlistAdapter extends ObservableTreeMapAdapter<String, Pair<RoomlistRoom, Long>> {
	private Context context;
	
	public RoomlistAdapter(Context context) {
		this.context = context;
	}
	
	@Override
	protected Comparator<Pair<RoomlistRoom, Long>> getEntryOrder() {
		return RoomAgeComparator.INSTANCE;
	}
	
	public RoomlistRoom getItem(int position) {
		return getEntries().get(position).first;
	}

	public long getItemId(int position) {
		return getEntries().get(position).second;
	}

	public boolean hasStableIds() {
		return true;
	}
	
	private static CharSequence formatExtra(Resources res, RoomlistRoom room) {
		String ownermsg = res.getString(R.string.roomlist_owner, room.owner);
		String mapmsg = res.getString(R.string.roomlist_map, room.formatMapName(res));
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
		
		RoomlistRoom room = getItem(position);
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
			mapView.setText(room.formatMapName(context.getResources()));
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
	
	private static final class RoomAgeComparator implements Comparator<Pair<RoomlistRoom, Long>> {
		public static final RoomAgeComparator INSTANCE = new RoomAgeComparator();
		public int compare(Pair<RoomlistRoom, Long> lhs, Pair<RoomlistRoom, Long> rhs) {
			return rhs.second.compareTo(lhs.second);
		}
	}
}