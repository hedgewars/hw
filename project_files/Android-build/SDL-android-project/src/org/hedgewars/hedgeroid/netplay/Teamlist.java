package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.Datastructures.TeamInGame;

import android.util.Pair;

public class Teamlist extends ObservableTreeMap<String, Pair<TeamInGame, Long>> {
	private long nextId = 1;
	
	public void addTeamWithNewId(TeamInGame team) {
		put(team.team.name, Pair.create(team, nextId++));
	}
}
