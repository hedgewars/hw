package org.hedgewars.hedgeroid.netplay;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import org.hedgewars.hedgeroid.R;

import android.content.Context;
import android.database.DataSetObserver;
import android.util.Pair;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;

public class PlayerListAdapter extends BaseAdapter {
	private List<Pair<Player, Long>> players = new ArrayList<Pair<Player, Long>>();
	private Context context;
	private PlayerList playerList;
	
	private DataSetObserver observer = new DataSetObserver() {
		@Override
		public void onChanged() {
			reloadFromList(playerList);
		}
		
		@Override
		public void onInvalidated() {
			invalidate();
		}
	};
	
	public PlayerListAdapter(Context context) {
		this.context = context;
	}
	
	public int getCount() {
		return players.size();
	}

	public Player getItem(int position) {
		return players.get(position).first;
	}

	public long getItemId(int position) {
		return players.get(position).second;
	}

	public boolean hasStableIds() {
		return true;
	}
	
	public void setList(PlayerList playerList) {
		if(this.playerList != null) {
			this.playerList.unregisterObserver(observer);
		}
		this.playerList = playerList;
		this.playerList.registerObserver(observer);
		reloadFromList(playerList);
	}
	
	public void invalidate() {
		if(playerList != null) {
			playerList.unregisterObserver(observer);
		}
		playerList = null;
		notifyDataSetInvalidated();
	}
	
	private void reloadFromList(PlayerList list) {
		players = new ArrayList<Pair<Player, Long>>(list.getMap().values());
		Collections.sort(players, AlphabeticalOrderComparator.INSTANCE);
		notifyDataSetChanged();
	}
	
	public View getView(int position, View convertView, ViewGroup parent) {
		View v = convertView;
		if (v == null) {
			LayoutInflater vi = LayoutInflater.from(context);
			v = vi.inflate(R.layout.listview_player, null);
		}

		String player = players.get(position).first.name;
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