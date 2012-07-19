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
import android.text.Layout.Alignment;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.style.AlignmentSpan;
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
	
	private static Spanned formatExtra(Resources res, Room room) {
		String ownermsg = res.getString(R.string.roomlist_owner, room.owner);
		String mapmsg = res.getString(R.string.roomlist_map, Room.formatMapName(res, room.map));
		String schememsg = res.getString(R.string.roomlist_scheme, room.scheme);
		String weaponsmsg = res.getString(R.string.roomlist_weapons,  room.weapons);
		SpannableStringBuilder ssb = new SpannableStringBuilder();
		ssb.append(ownermsg).append(" ").append(mapmsg).append("\n").append(schememsg).append(" ").append(weaponsmsg);
		
		int weaponOffset = ownermsg.length()+1+mapmsg.length()+1+schememsg.length()+1;
		ssb.setSpan(new AlignmentSpan.Standard(Alignment.ALIGN_OPPOSITE), ownermsg.length(), ownermsg.length()+mapmsg.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
		ssb.setSpan(new AlignmentSpan.Standard(Alignment.ALIGN_OPPOSITE), weaponOffset, weaponOffset+weaponsmsg.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
		return ssb;
	}
	
	public View getView(int position, View convertView, ViewGroup parent) {
		View v = convertView;
		TextView tv1;
		if (v == null) {
			LayoutInflater vi = LayoutInflater.from(context);
			v = vi.inflate(android.R.layout.simple_list_item_2, null);
			tv1 = (TextView)v.findViewById(android.R.id.text1);
			tv1.setCompoundDrawablePadding(5);
		} else {
			tv1 = (TextView)v.findViewById(android.R.id.text1);
		}
		
		Room room = rooms.get(position);
		int iconRes = room.inProgress ? R.drawable.roomlist_ingame : R.drawable.roomlist_preparing;
		TextView tv2 = (TextView)v.findViewById(android.R.id.text2);
		tv1.setCompoundDrawablesWithIntrinsicBounds(iconRes, 0, 0, 0);
		tv1.setText(room.name);
		tv2.setText(formatExtra(context.getResources(), room));
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