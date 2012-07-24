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
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.AdapterView;
import android.widget.Toast;

public class RoomlistFragment extends ListFragment implements OnItemClickListener {
	private static final int AUTO_REFRESH_INTERVAL_MS = 15000;
	
	private NetplayService service;
	private RoomListAdapter adapter;
	private CountDownTimer autoRefreshTimer = new CountDownTimer(Long.MAX_VALUE, AUTO_REFRESH_INTERVAL_MS) {
		@Override
		public void onTick(long millisUntilFinished) {
			if(service != null && service.isConnected()) {
				service.sendRoomlistRequest();
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
		setHasOptionsMenu(true);
	}

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		View v = inflater.inflate(R.layout.lobby_rooms_fragment, container, false);
		return v;
	}
	
	@Override
	public void onActivityCreated(Bundle savedInstanceState) {
		super.onActivityCreated(savedInstanceState);
		getListView().setOnItemClickListener(this);
	}
	
	@Override
	public void onResume() {
		super.onResume();
		if(service != null) {
			service.sendRoomlistRequest();
			autoRefreshTimer.start();
		}
	}
	
	@Override
	public void onPause() {
		super.onPause();
		autoRefreshTimer.cancel();
	}
	
	@Override
	public void onDestroy() {
		super.onDestroy();
		getActivity().unbindService(serviceConnection);
	}
	
	@Override
	public void onCreateOptionsMenu(Menu menu, MenuInflater inflater) {
		super.onCreateOptionsMenu(menu, inflater);
		inflater.inflate(R.menu.lobby_roomlist_options, menu);
	}
	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		switch(item.getItemId()) {
		case R.id.roomlist_refresh:
			if(service != null && service.isConnected()) {
				service.sendRoomlistRequest();
			}
			return true;
		default:
			return super.onOptionsItemSelected(item);
		}
	}
	
	public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
		Toast.makeText(getActivity(), R.string.not_implemented_yet, Toast.LENGTH_SHORT).show();
	}
	
    private ServiceConnection serviceConnection = new ServiceConnection() {
        public void onServiceConnected(ComponentName className, IBinder binder) {
        	service = ((NetplayBinder) binder).getService();
        	adapter.setList(service.roomList);
        	autoRefreshTimer.start();
        }

        public void onServiceDisconnected(ComponentName className) {
        	// TODO navigate away
        	adapter.invalidate();
        	service = null;
        }
    };
}
