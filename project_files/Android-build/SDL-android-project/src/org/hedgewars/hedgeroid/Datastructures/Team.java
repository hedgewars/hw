/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011-2012 Richard Deurwaarder <xeli@xelification.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

package org.hedgewars.hedgeroid.Datastructures;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import org.hedgewars.hedgeroid.EngineProtocol.PascalExports;
import org.hedgewars.hedgeroid.frontlib.Flib;
import org.hedgewars.hedgeroid.frontlib.Frontlib.TeamPtr;
import org.hedgewars.hedgeroid.util.FileUtils;

import android.content.Context;

public final class Team {
	public static final String DIRECTORY_TEAMS = "teams";

	public static final int HEDGEHOGS_PER_TEAM = Flib.INSTANCE.flib_get_hedgehogs_per_team();
	public static final int maxNumberOfTeams = PascalExports.HWgetMaxNumberOfTeams();

	public final String name, grave, flag, voice, fort;
	public final List<Hog> hogs;

	public Team(String name, String grave, String flag, String voice, String fort, List<Hog> hogs) {
		if(hogs.size() != HEDGEHOGS_PER_TEAM) {
			throw new IllegalArgumentException("A team must consist of "+HEDGEHOGS_PER_TEAM+" hogs.");
		}
		this.name = name;
		this.grave = grave;
		this.flag = flag;
		this.voice = voice;
		this.fort = fort;
		this.hogs = Collections.unmodifiableList(new ArrayList<Hog>(hogs));
	}

	public void save(File f) throws IOException {
		TeamPtr teamPtr = TeamPtr.createJavaOwned(this);
		if(Flib.INSTANCE.flib_team_to_ini(f.getAbsolutePath(), teamPtr) != 0) {
			throw new IOException("Error saving team "+name);
		}
	}

	public static Team load(File f) {
		TeamPtr teamPtr = Flib.INSTANCE.flib_team_from_ini(f.getAbsolutePath());
		if(teamPtr != null) {
			Team team = teamPtr.deref().team;
			Flib.INSTANCE.flib_team_destroy(teamPtr);
			return team;
		} else {
			return null;
		}
	}
	
	public static File getTeamfileByName(Context c, String teamName) {
		return new File(new File(c.getFilesDir(), DIRECTORY_TEAMS), FileUtils.replaceBadChars(teamName)+".hwt");
	}
	
	@Override
	public String toString() {
		return "Team [name=" + name + ", grave=" + grave + ", flag=" + flag
				+ ", voice=" + voice + ", fort=" + fort + ", hogs=" + hogs
				+ "]";
	}
	
	public static Comparator<Team> NAME_ORDER = new Comparator<Team>() {
		public int compare(Team lhs, Team rhs) {
			return lhs.name.compareToIgnoreCase(rhs.name);
		}
	};
}
