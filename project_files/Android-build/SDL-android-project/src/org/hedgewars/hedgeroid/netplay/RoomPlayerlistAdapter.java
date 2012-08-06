package org.hedgewars.hedgeroid.netplay;

import java.util.Comparator;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.netplay.RoomPlayerlist.PlayerInRoom;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

public class RoomPlayerlistAdapter extends ObservableTreeMapAdapter<String, PlayerInRoom> {
	private Context context;
	
	public RoomPlayerlistAdapter(Context context) {
		this.context = context;
	}
	
	@Override
	protected Comparator<PlayerInRoom> getEntryOrder() {
		return AlphabeticalOrderComparator.INSTANCE;
	}

	public PlayerInRoom getItem(int position) {
		return getEntries().get(position);
	}

	public long getItemId(int position) {
		return getEntries().get(position).id;
	}

	public boolean hasStableIds() {
		return true;
	}
	
	public View getView(int position, View convertView, ViewGroup parent) {
		View v = convertView;
		if (v == null) {
			LayoutInflater vi = LayoutInflater.from(context);
			v = vi.inflate(R.layout.listview_player, null);
		}

		PlayerInRoom player = getItem(position);
		TextView username = (TextView) v.findViewById(android.R.id.text1);
		username.setText(player.player.name);
		int readyDrawable = player.ready ? R.drawable.lightbulb_on : R.drawable.lightbulb_off;
		username.setCompoundDrawablesWithIntrinsicBounds(readyDrawable, 0, 0, 0);
		return v;
	}
	
	private static final class AlphabeticalOrderComparator implements Comparator<PlayerInRoom> {
		public static final AlphabeticalOrderComparator INSTANCE = new AlphabeticalOrderComparator();
		public int compare(PlayerInRoom lhs, PlayerInRoom rhs) {
			return lhs.player.name.compareToIgnoreCase(rhs.player.name);
		};
	}
}