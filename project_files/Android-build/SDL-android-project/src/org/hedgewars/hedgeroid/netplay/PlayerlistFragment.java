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
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

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
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		return inflater.inflate(R.layout.lobby_players_fragment, container, false);
	}
	
    private ServiceConnection serviceConnection = new ServiceConnection() {
        public void onServiceConnected(ComponentName className, IBinder binder) {
        	netconn = ((NetplayBinder) binder).getNetconn();
        	playerListAdapter.setPlayerList(netconn.playerList.getValues());
        	netconn.playerList.observe(playerListAdapter);
        }

        public void onServiceDisconnected(ComponentName className) {
        	// TODO navigate away
        	netconn.playerList.unobserve(playerListAdapter);
        	netconn = null;
        }
    };
}
