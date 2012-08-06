package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.netplay.RoomPlayerlist.PlayerInRoom;

import android.os.Bundle;
import android.support.v4.app.ListFragment;
import android.view.ContextMenu;
import android.view.ContextMenu.ContextMenuInfo;
import android.view.LayoutInflater;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView.AdapterContextMenuInfo;

public class RoomPlayerlistFragment extends ListFragment {
	private Netplay netplay;
	private RoomPlayerlistAdapter adapter;
	
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		netplay = Netplay.getAppInstance(getActivity().getApplicationContext());
		adapter = new RoomPlayerlistAdapter(getActivity());
		adapter.setSource(netplay.roomPlayerlist);
		setListAdapter(adapter);
	}

	@Override
	public void onDestroy() {
		super.onDestroy();
		adapter.invalidate();
	}
	
	@Override
	public void onActivityCreated(Bundle savedInstanceState) {
		super.onActivityCreated(savedInstanceState);
		registerForContextMenu(getListView());
	}

	@Override
	public void onCreateContextMenu(ContextMenu menu, View v,
			ContextMenuInfo menuInfo) {
		super.onCreateContextMenu(menu, v, menuInfo);
		AdapterContextMenuInfo info = (AdapterContextMenuInfo)menuInfo;
		String playerName = adapter.getItem(info.position).player.name;
		
		MenuInflater inflater = getActivity().getMenuInflater();
		inflater.inflate(R.menu.room_playerlist_context, menu);
		if(netplay.isChief() && !playerName.equals(netplay.getPlayerName())) {
			inflater.inflate(R.menu.room_playerlist_chief_context, menu);
		}
		menu.setHeaderIcon(R.drawable.human);
		menu.setHeaderTitle(playerName);
	}
	
	@Override
	public boolean onContextItemSelected(MenuItem item) {
		AdapterContextMenuInfo info = (AdapterContextMenuInfo)item.getMenuInfo();
		PlayerInRoom player = adapter.getItem(info.position);
		switch(item.getItemId()) {
		case R.id.player_info:
			netplay.sendPlayerInfoQuery(player.player.name);
			return true;
		case R.id.player_kick:
			netplay.sendKick(player.player.name);
			return true;
		default:
			return super.onContextItemSelected(item);
		}
	}
	
	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		return inflater.inflate(R.layout.fragment_playerlist, container, false);
	}
}
