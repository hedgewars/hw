package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.netplay.NetplayService.NetplayBinder;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.support.v4.app.ListFragment;
import android.view.ContextMenu;
import android.view.LayoutInflater;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.view.ContextMenu.ContextMenuInfo;
import android.widget.Toast;
import android.widget.AdapterView.AdapterContextMenuInfo;

public class PlayerlistFragment extends ListFragment {
	private Netconn netconn;
	private PlayerListAdapter playerListAdapter;
	
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		getActivity().bindService(new Intent(getActivity(), NetplayService.class), serviceConnection,
	            Context.BIND_AUTO_CREATE);
		playerListAdapter = new PlayerListAdapter(getActivity());
		setListAdapter(playerListAdapter);
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
		MenuInflater inflater = getActivity().getMenuInflater();
		inflater.inflate(R.menu.lobby_playerlist_context, menu);
	}
	
	@Override
	public boolean onContextItemSelected(MenuItem item) {
		AdapterContextMenuInfo info = (AdapterContextMenuInfo)item.getMenuInfo();
		switch(item.getItemId()) {
		case R.id.player_info:
			Player p = playerListAdapter.getItem(info.position);
			if(netconn != null) {
				netconn.sendPlayerInfoQuery(p.name);
			}
			return true;
		case R.id.player_follow:
			Toast.makeText(getActivity(), R.string.not_implemented_yet, Toast.LENGTH_SHORT).show();
			return true;
		default:
			return super.onContextItemSelected(item);
		}
	}
	
	@Override
	public void onDestroy() {
		super.onDestroy();
		getActivity().unbindService(serviceConnection);
	}
	
	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		return inflater.inflate(R.layout.lobby_players_fragment, container, false);
	}
	
    private ServiceConnection serviceConnection = new ServiceConnection() {
        public void onServiceConnected(ComponentName className, IBinder binder) {
        	netconn = ((NetplayBinder) binder).getNetconn();
        	playerListAdapter.setList(netconn.playerList);
        }

        public void onServiceDisconnected(ComponentName className) {
        	// TODO navigate away
        	playerListAdapter.invalidate();
        	netconn = null;
        }
    };
}
