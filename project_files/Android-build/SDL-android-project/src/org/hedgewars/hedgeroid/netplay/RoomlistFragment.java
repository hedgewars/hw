package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.R;

import android.os.Bundle;
import android.os.CountDownTimer;
import android.support.v4.app.ListFragment;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.Toast;

public class RoomlistFragment extends ListFragment implements OnItemClickListener {
	private static final int AUTO_REFRESH_INTERVAL_MS = 15000;
	
	private Netplay netconn;
	private RoomListAdapter adapter;
	private CountDownTimer autoRefreshTimer = new CountDownTimer(Long.MAX_VALUE, AUTO_REFRESH_INTERVAL_MS) {
		@Override
		public void onTick(long millisUntilFinished) {
			netconn.sendRoomlistRequest();
		}
		
		@Override
		public void onFinish() { }
	};

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		netconn = Netplay.getAppInstance(getActivity().getApplicationContext());
		adapter = new RoomListAdapter(getActivity());
		adapter.setList(netconn.roomList);
		setListAdapter(adapter);
		setHasOptionsMenu(true);
	}

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		return inflater.inflate(R.layout.lobby_rooms_fragment, container, false);
	}
	
	@Override
	public void onActivityCreated(Bundle savedInstanceState) {
		super.onActivityCreated(savedInstanceState);
		getListView().setOnItemClickListener(this);
	}
	
	@Override
	public void onResume() {
		super.onResume();
		autoRefreshTimer.start();
	}
	
	@Override
	public void onPause() {
		super.onPause();
		autoRefreshTimer.cancel();
	}
	
	@Override
	public void onDestroy() {
		super.onDestroy();
		adapter.invalidate();
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
			netconn.sendRoomlistRequest();
			return true;
		default:
			return super.onOptionsItemSelected(item);
		}
	}
	
	public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
		Toast.makeText(getActivity(), R.string.not_implemented_yet, Toast.LENGTH_SHORT).show();
	}
}
