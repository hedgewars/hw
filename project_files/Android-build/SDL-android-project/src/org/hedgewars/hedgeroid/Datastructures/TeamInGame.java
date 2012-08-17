package org.hedgewars.hedgeroid.Datastructures;

import java.util.Collection;
import java.util.Comparator;

/**
 * A team with per-game configuration. This is similar to the frontlib "team" structure,
 * except that it does not include weaponset and initial health, which are handled on a
 * per-game basis in the UI, but per-hog in the frontlib.
 */
public final class TeamInGame {
	public final Team team;
	public final TeamIngameAttributes ingameAttribs;
	
	public TeamInGame(Team team, TeamIngameAttributes ingameAttribs) {
		this.team = team;
		this.ingameAttribs = ingameAttribs;
	}
	
	public TeamInGame withAttribs(TeamIngameAttributes attribs) {
		return new TeamInGame(team, attribs);
	}
	
	public static int getUnusedOrRandomColorIndex(Collection<TeamInGame> teams) {
		int[] illegalColors = new int[teams.size()];
		int i=0;
		for(TeamInGame team : teams) {
			illegalColors[i] = team.ingameAttribs.colorIndex;
			i++;
		}
		return TeamIngameAttributes.randomColorIndex(illegalColors);
	}
	
	public static Comparator<TeamInGame> NAME_ORDER = new Comparator<TeamInGame>() {
		public int compare(TeamInGame lhs, TeamInGame rhs) {
			return Team.NAME_ORDER.compare(lhs.team, rhs.team);
		}
	};
}
