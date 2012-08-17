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

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;


/**
 * Game configuration from the point of view of the UI. This differs slightly from the
 * frontlib view, because the engine allows setting a separate initial health and weapon set
 * for each hog, while the Android UI currently only supports both attributes on a per-game
 * basis (initial health is contained in the scheme).
 * 
 * This difference means that creating a GameConfig object from a frontlib object can, in
 * theory, lose information. This does not cause problems at the moment because for now
 * weaponset and initial health are always per-game, but that might change in the future.
 */
public final class GameConfig {
	public static final String DEFAULT_STYLE = "Normal";
	public static final String DEFAULT_SCHEME = "Default";
	public static final String DEFAULT_WEAPONSET = "Default";
	public static final String DEFAULT_THEME = "Bamboo";
	
	public final String style;
	public final Scheme scheme;
	public final MapRecipe map;
	public final List<TeamInGame> teams;
	public final Weaponset weaponset;
	
	public GameConfig(String style, Scheme scheme, MapRecipe map, List<TeamInGame> teams, Weaponset weaponset) {
		this.style = style;
		this.scheme = scheme;
		this.map = map;
		this.teams = Collections.unmodifiableList(new ArrayList<TeamInGame>(teams));
		this.weaponset = weaponset;
	}

	@Override
	public String toString() {
		return "GameConfig [style=" + style + ", scheme=" + scheme + ", map="
				+ map + ", teams=" + teams + ", weaponset=" + weaponset + "]";
	}
}
