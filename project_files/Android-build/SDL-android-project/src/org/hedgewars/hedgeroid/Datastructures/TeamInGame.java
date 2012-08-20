/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (C) 2012 Simeon Maxein <smaxein@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

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
