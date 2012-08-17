package org.hedgewars.hedgeroid;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Datastructures.MapRecipe;
import org.hedgewars.hedgeroid.Datastructures.Scheme;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.Datastructures.TeamIngameAttributes;
import org.hedgewars.hedgeroid.Datastructures.Weaponset;
import org.hedgewars.hedgeroid.netplay.Netplay;

import android.database.DataSetObserver;
import android.os.Bundle;
import android.support.v4.app.ListFragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.Button;

/**
 *  TODO use an interface for querying and manipulating the team list, to allow re-using this fragment
 *  in local play
 */
public class TeamlistFragment extends ListFragment implements TeamlistAdapter.Listener, RoomStateManager.Observer {
	private Netplay netplay;
	private TeamlistAdapter adapter;
	private Button addTeamButton;
	private DataSetObserver teamlistObserver;
	private RoomStateManager stateManager;
	
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		try {
			stateManager = ((RoomStateManager.Provider)getActivity()).getRoomStateManager();
		} catch(ClassCastException e) {
			throw new RuntimeException("Hosting activity must implement RoomStateManager.Provider.", e);
		}
		netplay = Netplay.getAppInstance(getActivity().getApplicationContext());
		adapter = new TeamlistAdapter();
		adapter.setSource(netplay.roomTeamlist);
		adapter.setColorHogcountEnabled(stateManager.getChiefStatus());
		adapter.setListener(this);
		setListAdapter(adapter);
		stateManager.registerObserver(this);
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
		adapter.setListener(null);
		netplay.roomTeamlist.unregisterObserver(teamlistObserver);
		stateManager.unregisterObserver(this);
	}

	@Override
	public void onActivityCreated(Bundle savedInstanceState) {
		super.onActivityCreated(savedInstanceState);
	}
	
	private Collection<String> getCurrentTeamNames() {
		List<String> names = new ArrayList<String>();
		for(TeamInGame team : netplay.roomTeamlist.getMap().values()) {
			names.add(team.team.name);
		}
		return names;
	}
	
	public void onColorClicked(TeamInGame team) {
		netplay.sendTeamColorIndex(team.team.name, (team.ingameAttribs.colorIndex+1)%TeamIngameAttributes.TEAM_COLORS.length);
	}
	
	public void onHogcountClicked(TeamInGame team) {
		int newHogCount = team.ingameAttribs.hogCount+1;
		if(newHogCount>Team.HEDGEHOGS_PER_TEAM) {
			newHogCount = 1;
		}
		netplay.sendTeamHogCount(team.team.name, newHogCount);
	}
	
	public void onTeamClicked(TeamInGame team) {
		netplay.sendRemoveTeam(team.team.name);
	}
	
	public void onChiefStatusChanged(boolean isChief) {
		adapter.setColorHogcountEnabled(isChief);
	}
	
	public void onGameStyleChanged(String gameStyle) { }
	public void onMapChanged(MapRecipe recipe) { }
	public void onSchemeChanged(Scheme scheme) { }
	public void onWeaponsetChanged(Weaponset weaponset) { }
}
