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

public class PlayerlistAdapter extends BaseAdapter {
	private List<Pair<Player, Long>> players = new ArrayList<Pair<Player, Long>>();
	private Context context;
	private Playerlist playerlist;
	
	private DataSetObserver observer = new DataSetObserver() {
		@Override
		public void onChanged() {
			reloadFromList(playerlist);
		}
		
		@Override
		public void onInvalidated() {
			invalidate();
		}
	};
	
	public PlayerlistAdapter(Context context) {
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
	
	public void setList(Playerlist playerlist) {
		if(this.playerlist != null) {
			this.playerlist.unregisterObserver(observer);
		}
		this.playerlist = playerlist;
		this.playerlist.registerObserver(observer);
		reloadFromList(playerlist);
	}
	
	public void invalidate() {
		if(playerlist != null) {
			playerlist.unregisterObserver(observer);
		}
		playerlist = null;
		notifyDataSetInvalidated();
	}
	
	private void reloadFromList(Playerlist list) {
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