package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.netplay.NetplayService.NetplayBinder;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.os.IBinder;
import android.support.v4.app.ListFragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

public class RoomlistFragment extends ListFragment {
	private static final int AUTO_REFRESH_INTERVAL_MS = 10000;
	
	private Netconn netconn;
	private RoomListAdapter adapter;
	private CountDownTimer autoRefreshTimer = new CountDownTimer(Long.MAX_VALUE, AUTO_REFRESH_INTERVAL_MS) {
		@Override
		public void onTick(long millisUntilFinished) {
			if(netconn != null && netconn.isConnected()) {
				netconn.sendRoomlistRequest();
			}
		}
		
		@Override
		public void onFinish() { }
	};

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		getActivity().bindService(new Intent(getActivity(), NetplayService.class), serviceConnection,
	            Context.BIND_AUTO_CREATE);
		adapter = new RoomListAdapter(getActivity());
		setListAdapter(adapter);
	}

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		return inflater.inflate(R.layout.lobby_rooms_fragment, container, false);
	}
	
	@Override
	public void onPause() {
		super.onPause();
		autoRefreshTimer.cancel();
	}
	
	@Override
	public void onResume() {
		super.onResume();
		if(netconn != null) {
			netconn.sendRoomlistRequest();
			autoRefreshTimer.start();
		}
	}
	
    private ServiceConnection serviceConnection = new ServiceConnection() {
        public void onServiceConnected(ComponentName className, IBinder binder) {
        	netconn = ((NetplayBinder) binder).getNetconn();
        	adapter.setList(netconn.roomList.getValues());
        	netconn.roomList.observe(adapter);
        }

        public void onServiceDisconnected(ComponentName className) {
        	// TODO navigate away
        	netconn.roomList.unobserve(adapter);
        	netconn = null;
        }
    };
}
