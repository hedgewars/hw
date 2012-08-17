package org.hedgewars.hedgeroid.Datastructures;

import java.util.Comparator;

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
		return "Weaponset [name=" + name + ", loadout=" + loadout
				+ ", crateProb=" + crateProb + ", crateAmmo=" + crateAmmo
				+ ", delay=" + delay + "]";
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result
				+ ((crateAmmo == null) ? 0 : crateAmmo.hashCode());
		result = prime * result
				+ ((crateProb == null) ? 0 : crateProb.hashCode());
		result = prime * result + ((delay == null) ? 0 : delay.hashCode());
		result = prime * result + ((loadout == null) ? 0 : loadout.hashCode());
		result = prime * result + ((name == null) ? 0 : name.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		Weaponset other = (Weaponset) obj;
		if (crateAmmo == null) {
			if (other.crateAmmo != null)
				return false;
		} else if (!crateAmmo.equals(other.crateAmmo))
			return false;
		if (crateProb == null) {
			if (other.crateProb != null)
				return false;
		} else if (!crateProb.equals(other.crateProb))
			return false;
		if (delay == null) {
			if (other.delay != null)
				return false;
		} else if (!delay.equals(other.delay))
			return false;
		if (loadout == null) {
			if (other.loadout != null)
				return false;
		} else if (!loadout.equals(other.loadout))
			return false;
		if (name == null) {
			if (other.name != null)
				return false;
		} else if (!name.equals(other.name))
			return false;
		return true;
	}

	public static Comparator<Weaponset> NAME_ORDER = new Comparator<Weaponset>() {
		public int compare(Weaponset lhs, Weaponset rhs) {
			return String.CASE_INSENSITIVE_ORDER.compare(lhs.name, rhs.name);
		}
	};
}
