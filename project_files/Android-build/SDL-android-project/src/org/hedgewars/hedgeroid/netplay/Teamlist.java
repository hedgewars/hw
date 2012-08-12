package org.hedgewars.hedgeroid.netplay;

import java.util.Collection;

import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.Datastructures.TeamIngameAttributes;

import android.util.Pair;

public class Teamlist extends ObservableTreeMap<String, Pair<TeamInGame, Long>> {
	private long nextId = 1;
	
	public void addTeamWithNewId(TeamInGame team) {
		put(team.team.name, Pair.create(team, nextId++));
	}
	
	public int getUnusedOrRandomColorIndex() {
		Collection<Pair<TeamInGame, Long>> teams = getMap().values();
		int[] illegalColors = new int[teams.size()];
		int i=0;
		for(Pair<TeamInGame, Long> item : teams) {
			illegalColors[i] = item.first.ingameAttribs.colorIndex;
			i++;
		}
		return TeamIngameAttributes.randomColorIndex(illegalColors);
	}
}
