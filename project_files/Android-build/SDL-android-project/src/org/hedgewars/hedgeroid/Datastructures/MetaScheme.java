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
import java.util.Collections;
import java.util.List;

import org.hedgewars.hedgeroid.frontlib.Flib;

public final class MetaScheme {
	public static final MetaScheme INSTANCE = Flib.INSTANCE.flib_get_metascheme().deref();
	
	public static final class Mod {
		public final String name;
		public final int bitmaskIndex;
		
		public Mod(String name, int bitmaskIndex) {
			this.name = name;
			this.bitmaskIndex = bitmaskIndex;
		}

		@Override
		public String toString() {
			return "MetaScheme$Mod [name=" + name + ", bitmaskIndex=" + bitmaskIndex + "]";
		}
	}
	
	public static final class Setting {
		public final String name, engineCommand;
		public final boolean maxMeansInfinity, times1000;
		public final int min, max, def;
		
		public Setting(String name, String engineCommand, boolean maxMeansInfinity, boolean times1000, int min, int max, int def) {
			this.name = name;
			this.engineCommand = engineCommand;
			this.maxMeansInfinity = maxMeansInfinity;
			this.times1000 = times1000;
			this.min = min;
			this.max = max;
			this.def = def;
		}

		@Override
		public String toString() {
			return "MetaScheme$Setting [name=" + name + ", engineCommand=" + engineCommand
					+ ", maxMeansInfinite=" + maxMeansInfinity + ", times1000="
					+ times1000 + ", min=" + min + ", max=" + max + ", def="
					+ def + "]";
		}
	}
	
	public final List<Mod> mods;
	public final List<Setting> settings;
	
	public MetaScheme(List<Mod> mods, List<Setting> settings) {
		this.mods = Collections.unmodifiableList(new ArrayList<Mod>(mods));
		this.settings = Collections.unmodifiableList(new ArrayList<Setting>(settings));
	}

	@Override
	public String toString() {
		return "MetaScheme [\nmods=" + mods + ", \nsettings=" + settings + "\n]";
	}
}
