package org.hedgewars.hedgeroid;

import java.util.Comparator;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Datastructures.Player;
import org.hedgewars.hedgeroid.util.ObservableTreeMapAdapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

public class LobbyPlayerlistAdapter extends ObservableTreeMapAdapter<String, Player> {
	@Override
	protected Comparator<Player> getEntryOrder() {
		return Player.NAME_ORDER;
	}

	public View getView(int position, View convertView, ViewGroup parent) {
		View v = convertView;
		if (v == null) {
			LayoutInflater vi = LayoutInflater.from(parent.getContext());
			v = vi.inflate(R.layout.listview_player, null);
		}

		String player = getItem(position).name;
		TextView username = (TextView) v.findViewById(android.R.id.text1);
		username.setText(player);
		return v;
	}
}