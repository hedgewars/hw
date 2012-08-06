package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.R;

import android.os.Bundle;
import android.support.v4.app.ListFragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

public class TeamlistFragment extends ListFragment {
	private Netplay netplay;
	private TeamlistAdapter adapter;

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		netplay = Netplay.getAppInstance(getActivity().getApplicationContext());
		adapter = new TeamlistAdapter(getActivity());
		adapter.setSource(netplay.roomTeamlist);
		setListAdapter(adapter);
	}

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		return inflater.inflate(R.layout.fragment_teamlist, container, false);
	}
	
	@Override
	public void onDestroy() {
		super.onDestroy();
		adapter.invalidate();
	}
}
