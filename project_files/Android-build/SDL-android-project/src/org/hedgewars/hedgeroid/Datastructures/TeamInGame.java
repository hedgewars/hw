package org.hedgewars.hedgeroid.Datastructures;

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
