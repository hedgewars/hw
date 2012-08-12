/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011-2012 Richard Deurwaarder <xeli@xelification.com>
 * Copyright (c) 2012 Simeon Maxein <smaxein@googlemail.com>
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

import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Map;

public final class Scheme {
	public final MetaScheme metascheme;
	public final String name;
	public final Map<String, Integer> settings;
	public final Map<String, Boolean> mods;
		
	public Scheme(MetaScheme metascheme, String name, Map<String, Integer> settings, Map<String, Boolean> mods) {
		this.metascheme = metascheme;
		this.name = name;
		this.settings = Collections.unmodifiableMap(new HashMap<String, Integer>(settings));
		this.mods = Collections.unmodifiableMap(new HashMap<String, Boolean>(mods));
	}
	
	public int getHealth() {
		Integer health = settings.get("health");
		return health==null ? 100 : health.intValue();
	}

	/*@Override
	public String toString() {
		return "Scheme [metascheme=" + metascheme + ", name=" + name
				+ ", settings=" + settings + ", mods=" + mods + "]";
	}*/
	
	@Override
	public String toString() {
		return name; // TODO change back once StartGameActivity does not need this anymore
	}
	
	public static final Comparator<Scheme> caseInsensitiveNameComparator = new Comparator<Scheme>() {
		public int compare(Scheme lhs, Scheme rhs) {
			return lhs.name.compareToIgnoreCase(rhs.name);
		}
	};
}