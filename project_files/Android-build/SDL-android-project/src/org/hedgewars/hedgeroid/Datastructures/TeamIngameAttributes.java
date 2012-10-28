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

import java.util.ArrayList;
import java.util.Random;

import org.hedgewars.hedgeroid.frontlib.Flib;

public final class TeamIngameAttributes {
	public static final int DEFAULT_HOG_COUNT = 4;
	public static final int[] TEAM_COLORS;
	
	static {
		int[] teamColors = new int[Flib.INSTANCE.flib_get_teamcolor_count()];
		for(int i=0; i<teamColors.length; i++) {
			teamColors[i] = Flib.INSTANCE.flib_get_teamcolor(i);
		}
		TEAM_COLORS = teamColors;
	}
	
	public final String ownerName;
	public final int colorIndex, hogCount;
	public final boolean remoteDriven;
	
	public TeamIngameAttributes(String ownerName, int colorIndex, int hogCount, boolean remoteDriven) {
		this.ownerName = ownerName;
		this.colorIndex = colorIndex;
		this.hogCount = hogCount;
		this.remoteDriven = remoteDriven;
	}
	
	public static int randomColorIndex(int[] illegalColors) {
		Random rnd = new Random();
		ArrayList<Integer> legalcolors = new ArrayList<Integer>();
		for(int i=0; i<TEAM_COLORS.length; i++) {
			legalcolors.add(i);
		}
		for(int illegalColor : illegalColors) {
			legalcolors.remove(Integer.valueOf(illegalColor));
		}
		if(legalcolors.isEmpty()) {
			return rnd.nextInt(TEAM_COLORS.length);
		} else {
			return legalcolors.get(rnd.nextInt(legalcolors.size()));
		}
	}
	
	public TeamIngameAttributes withColorIndex(int colorIndex) {
		return new TeamIngameAttributes(ownerName, colorIndex, hogCount, remoteDriven);
	}
	
	public TeamIngameAttributes withHogCount(int hogCount) {
		return new TeamIngameAttributes(ownerName, colorIndex, hogCount, remoteDriven);
	}

	@Override
	public String toString() {
		return "TeamIngameAttributes [ownerName=" + ownerName + ", colorIndex="
				+ colorIndex + ", hogCount=" + hogCount + ", remoteDriven="
				+ remoteDriven + "]";
	}
}
