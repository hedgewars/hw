package org.hedgewars.hedgeroid.netplay;

import java.util.Comparator;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Datastructures.Player;

import android.content.Context;
import android.util.Pair;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

public class LobbyPlayerlistAdapter extends ObservableTreeMapAdapter<String, Pair<Player, Long>> {
	private Context context;
	
	public LobbyPlayerlistAdapter(Context context) {
		this.context = context;
	}
	
	@Override
	protected Comparator<Pair<Player, Long>> getEntryOrder() {
		return AlphabeticalOrderComparator.INSTANCE;
	}

	public Player getItem(int position) {
		return getEntries().get(position).first;
	}

	public long getItemId(int position) {
		return getEntries().get(position).second;
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

		String player = getItem(position).name;
		TextView username = (TextView) v.findViewById(android.R.id.text1);
		username.setText(player);
		return v;
	}
	
	private static final class AlphabeticalOrderComparator implements Comparator<Pair<Player, Long>> {
		public static final AlphabeticalOrderComparator INSTANCE = new AlphabeticalOrderComparator();
		public int compare(Pair<Player, Long> lhs, Pair<Player, Long> rhs) {
			return lhs.first.name.compareToIgnoreCase(rhs.first.name);
		};
	}
}