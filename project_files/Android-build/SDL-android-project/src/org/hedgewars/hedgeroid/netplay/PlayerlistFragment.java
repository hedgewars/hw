package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.R;

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
import android.widget.Toast;

public class PlayerlistFragment extends ListFragment {
	private Netplay netconn;
	private PlayerListAdapter playerListAdapter;
	
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		netconn = Netplay.getAppInstance(getActivity().getApplicationContext());
		playerListAdapter = new PlayerListAdapter(getActivity());
		playerListAdapter.setList(Netplay.getAppInstance(getActivity().getApplicationContext()).playerList);
		setListAdapter(playerListAdapter);
	}

	@Override
	public void onDestroy() {
		super.onDestroy();
		playerListAdapter.invalidate();
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
		MenuInflater inflater = getActivity().getMenuInflater();
		inflater.inflate(R.menu.lobby_playerlist_context, menu);
		menu.setHeaderIcon(R.drawable.human);
		menu.setHeaderTitle(playerListAdapter.getItem(info.position).name);
	}
	
	@Override
	public boolean onContextItemSelected(MenuItem item) {
		AdapterContextMenuInfo info = (AdapterContextMenuInfo)item.getMenuInfo();
		switch(item.getItemId()) {
		case R.id.player_info:
			Player p = playerListAdapter.getItem(info.position);
			netconn.sendPlayerInfoQuery(p.name);
			return true;
		case R.id.player_follow:
			Toast.makeText(getActivity(), R.string.not_implemented_yet, Toast.LENGTH_SHORT).show();
			return true;
		default:
			return super.onContextItemSelected(item);
		}
	}
	
	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		return inflater.inflate(R.layout.lobby_players_fragment, container, false);
	}
}
