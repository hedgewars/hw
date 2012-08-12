package org.hedgewars.hedgeroid.Datastructures;

import org.hedgewars.hedgeroid.frontlib.Flib;

public final class Weaponset {
	public static final int WEAPONS_COUNT = Flib.INSTANCE.flib_get_weapons_count();
	
	public final String name, loadout, crateProb, crateAmmo, delay;
	
	public Weaponset(String name, String loadout, String crateProb, String crateAmmo, String delay) {
		this.name = name;
		this.loadout = loadout;
		this.crateProb = crateProb;
		this.crateAmmo = crateAmmo;
		this.delay = delay;
	}

	@Override
	public String toString() {
		return name; // TODO use the generated one once StartGameActivity doesn't need this anymore
	}
}
