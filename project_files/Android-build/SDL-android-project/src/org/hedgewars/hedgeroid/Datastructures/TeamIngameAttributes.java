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
	
	public static int randomColorIndex(int[] illegalColors){
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
