package org.hedgewars.hedgeroid;

import java.util.Comparator;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Datastructures.PlayerInRoom;
import org.hedgewars.hedgeroid.util.ObservableTreeMapAdapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

public class RoomPlayerlistAdapter extends ObservableTreeMapAdapter<String, PlayerInRoom> {
	@Override
	protected Comparator<PlayerInRoom> getEntryOrder() {
		return AlphabeticalOrderComparator.INSTANCE;
	}

	public View getView(int position, View convertView, ViewGroup parent) {
		View v = convertView;
		if (v == null) {
			LayoutInflater vi = LayoutInflater.from(parent.getContext());
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