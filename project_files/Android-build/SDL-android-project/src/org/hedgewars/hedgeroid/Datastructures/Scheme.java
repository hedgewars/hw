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

import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Map;
import java.util.TreeMap;

public final class Scheme {
	public final String name;
	public final Map<String, Integer> settings;
	public final Map<String, Boolean> mods;
		
	public Scheme(String name, Map<String, Integer> settings, Map<String, Boolean> mods) {
		this.name = name;
		this.settings = Collections.unmodifiableMap(new HashMap<String, Integer>(settings));
		this.mods = Collections.unmodifiableMap(new HashMap<String, Boolean>(mods));
	}
	
	public int getHealth() {
		Integer health = settings.get("health");
		return health==null ? 100 : health.intValue();
	}

	public static Scheme createDefaultScheme(MetaScheme meta) {
		String name = GameConfig.DEFAULT_SCHEME;
		Map<String, Integer> settings = new TreeMap<String, Integer>();
		Map<String, Boolean> mods = new TreeMap<String, Boolean>();
		for(MetaScheme.Setting setting : meta.settings) {
			settings.put(setting.name, setting.def);
		}
		for(MetaScheme.Mod mod : meta.mods) {
			mods.put(mod.name, Boolean.FALSE);
		}
		return new Scheme(name, settings, mods);
	}
	
	@Override
	public String toString() {
		return "Scheme [name=" + name + ", settings=" + settings + ", mods="
				+ mods + "]";
	}
	
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((name == null) ? 0 : name.hashCode());
		result = prime * result + ((mods == null) ? 0 : mods.hashCode());
		result = prime * result
				+ ((settings == null) ? 0 : settings.hashCode());
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
		Scheme other = (Scheme) obj;
		if (name == null) {
			if (other.name != null)
				return false;
		} else if (!name.equals(other.name))
			return false;
		if (mods == null) {
			if (other.mods != null)
				return false;
		} else if (!mods.equals(other.mods))
			return false;
		if (settings == null) {
			if (other.settings != null)
				return false;
		} else if (!settings.equals(other.settings))
			return false;
		return true;
	}

	public static final Comparator<Scheme> NAME_ORDER = new Comparator<Scheme>() {
		public int compare(Scheme lhs, Scheme rhs) {
			return String.CASE_INSENSITIVE_ORDER.compare(lhs.name, rhs.name);
		}
	};
}