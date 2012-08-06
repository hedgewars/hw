package org.hedgewars.hedgeroid.Datastructures;

import java.io.File;

public final class TeamFile {
	public final Team team;
	public final File file;
	
	public TeamFile(Team team, File file) {
		this.team = team;
		this.file = file;
	}

	@Override
	public String toString() {
		return "TeamFile [team=" + team + ", file=" + file + "]";
	}
}
