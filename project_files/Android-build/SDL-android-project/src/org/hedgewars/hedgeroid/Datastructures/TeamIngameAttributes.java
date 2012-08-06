package org.hedgewars.hedgeroid.Datastructures;

import java.util.ArrayList;
import java.util.Random;

public final class TeamIngameAttributes {
	public static final int[] TEAM_COLORS = {
		0xd12b42, /* red    */ 
		0x4980c1, /* blue   */ 
		0x6ab530, /* green  */ 
		0xbc64c4, /* purple */ 
		0xe76d14, /* orange */ 
		0x3fb6e6, /* cyan   */ 
		0xe3e90c, /* yellow */ 
		0x61d4ac, /* mint   */ 
		0xf1c3e1, /* pink   */ 
		/* add new colors here */
	};
	
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
