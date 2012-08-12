package org.hedgewars.hedgeroid.Datastructures;

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
}
