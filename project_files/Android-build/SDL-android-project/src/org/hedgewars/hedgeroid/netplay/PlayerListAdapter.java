package org.hedgewars.hedgeroid.netplay;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import org.hedgewars.hedgeroid.R;

import android.content.Context;
import android.database.DataSetObserver;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;

public class PlayerListAdapter extends BaseAdapter {
	private List<Player> players = new ArrayList<Player>();
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
		return players.get(position);
	}

	public long getItemId(int position) {
		return players.get(position).id;
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
		players = new ArrayList<Player>();
		if(playerList != null) {
			playerList.unregisterObserver(observer);
		}
		playerList = null;
		notifyDataSetInvalidated();
	}
	
	private void reloadFromList(PlayerList list) {
		players = new ArrayList<Player>(list.getMap().values());
		Collections.sort(players, Player.NAME_COMPARATOR);
		notifyDataSetChanged();
	}
	
	public View getView(int position, View convertView, ViewGroup parent) {
		View v = convertView;
		if (v == null) {
			LayoutInflater vi = LayoutInflater.from(context);
			v = vi.inflate(android.R.layout.simple_list_item_1, null);
			TextView tv = (TextView)v.findViewById(android.R.id.text1);
			tv.setCompoundDrawablePadding(5);
			tv.setCompoundDrawablesWithIntrinsicBounds(R.drawable.human, 0, 0, 0);
		}

		String player = players.get(position).name;
		TextView username = (TextView) v.findViewById(android.R.id.text1);
		username.setText(player);
		return v;
	}
}