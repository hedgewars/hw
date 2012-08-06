package org.hedgewars.hedgeroid.Datastructures;

public final class Hog {
	public final String name, hat;
	public final int level;
	
	public Hog(String name, String hat, int level) {
		this.name = name;
		this.hat = hat;
		this.level = level;
	}

	@Override
	public String toString() {
		return "Hog [name=" + name + ", hat=" + hat + ", level=" + level + "]";
	}
}
