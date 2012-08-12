package org.hedgewars.hedgeroid.netplay;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;

import android.database.DataSetObserver;
import android.os.Bundle;
import android.support.v4.app.ListFragment;
import android.util.Pair;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.AdapterView;
import android.widget.Button;

public class TeamlistFragment extends ListFragment implements OnItemClickListener {
	private Netplay netplay;
	private TeamlistAdapter adapter;
	private Button addTeamButton;
	private DataSetObserver teamlistObserver;
	
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
		View v = inflater.inflate(R.layout.fragment_teamlist, container, false);
		addTeamButton = (Button)v.findViewById(R.id.addTeamButton);
		addTeamButton.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				new TeamAddDialog(getCurrentTeamNames()).show(getFragmentManager(), "team_add_dialog");
			}
		});
		
		teamlistObserver = new DataSetObserver() {
			@Override
			public void onChanged() {
				addTeamButton.setEnabled(netplay.roomTeamlist.getMap().size() < Team.maxNumberOfTeams);
			}
		};
		netplay.roomTeamlist.registerObserver(teamlistObserver);
		teamlistObserver.onChanged();
		
		return v;
	}
	
	@Override
	public void onDestroy() {
		super.onDestroy();
		adapter.invalidate();
		netplay.roomTeamlist.unregisterObserver(teamlistObserver);
	}

	@Override
	public void onActivityCreated(Bundle savedInstanceState) {
		super.onActivityCreated(savedInstanceState);
		getListView().setOnItemClickListener(this);
	}
	
	private Collection<String> getCurrentTeamNames() {
		List<String> names = new ArrayList<String>();
		for(Pair<TeamInGame, Long> teamWithId : netplay.roomTeamlist.getMap().values()) {
			names.add(teamWithId.first.team.name);
		}
		return names;
	}
	
	public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
		netplay.sendRemoveTeam(adapter.getItem(position).team.name);
	}
}
