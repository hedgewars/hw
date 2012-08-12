package org.hedgewars.hedgeroid.netplay;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Datastructures.FrontendDataUtils;
import org.hedgewars.hedgeroid.Datastructures.Team;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.DialogInterface;
import android.content.DialogInterface.OnClickListener;
import android.os.Bundle;
import android.support.v4.app.DialogFragment;

public class TeamAddDialog extends DialogFragment {
	private static final String STATE_TEAMS_ALREADY_IN_GAME = "teamAlreadyInGame";
	private ArrayList<String> teamsAlreadyInGame;
	private List<Team> availableTeams;
	private Listener listener;
	
	public static interface Listener {
		void onTeamAddDialogSubmitted(Team newTeam);
	}
	
	public TeamAddDialog() {
		// Only for reflection-based instantiation by the framework
	}
	
	TeamAddDialog(Collection<String> teamsAlreadyInGame) {
		this.teamsAlreadyInGame = new ArrayList<String>(teamsAlreadyInGame);
	}
	
	@Override
	public void onAttach(Activity activity) {
		super.onAttach(activity);
		try {
			listener = (Listener) activity;
		} catch(ClassCastException e) {
			throw new ClassCastException("Activity " + activity + " must implement TeamAddDialog.Listener to use TeamAddDialog.");
		}
	}
	
	@Override
	public void onDetach() {
		super.onDetach();
		listener = null;
	}
	
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		if(savedInstanceState != null) {
			teamsAlreadyInGame = savedInstanceState.getStringArrayList(STATE_TEAMS_ALREADY_IN_GAME);
		}
		availableTeams = new ArrayList<Team>();
		List<Team> teams = FrontendDataUtils.getTeams(getActivity());
		for(Team team : teams) {
			if(!teamsAlreadyInGame.contains(team.name)) {
				availableTeams.add(team);
			}
		}
		Collections.sort(availableTeams, Team.NAME_ORDER);
	}
	
	@Override
	public Dialog onCreateDialog(Bundle savedInstanceState) {
		AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());
		builder.setTitle(R.string.dialog_addteam_title);
		builder.setIcon(R.drawable.human);
		String[] teamNames = new String[availableTeams.size()];
		for(int i=0; i<availableTeams.size(); i++) {
			teamNames[i] = availableTeams.get(i).name;
		}
		builder.setItems(teamNames, new OnClickListener() {
			public void onClick(DialogInterface dialog, int which) {
				listener.onTeamAddDialogSubmitted(availableTeams.get(which));
			}
		});
		return builder.create();
	}
	
	@Override
	public void onSaveInstanceState(Bundle outState) {
		super.onSaveInstanceState(outState);
		outState.putStringArrayList(STATE_TEAMS_ALREADY_IN_GAME, teamsAlreadyInGame);
	}
}
