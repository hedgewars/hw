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

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.frontlib.Frontlib;

import android.content.res.Resources;

public final class MapRecipe {
	public static final String MAPNAME_REGULAR = "+rnd+";
	public static final String MAPNAME_MAZE = "+maze+";
	public static final String MAPNAME_DRAWN = "+drawn+";

	public final int mapgen;			// Frontlib.MAPGEN_xxx
	public final int templateFilter;	// Frontlib.TEMPLATEFILTER_xxx, only used when mapgen==MAPGEN_REGULAR
	public final int mazeSize;			// Frontlib.MAZE_SIZE_xxx, only used when mapgen==MAPGEN_MAZE
	public final String name, seed, theme;
	
	private final byte[] drawData;		// For drawn maps, can be null.

	public MapRecipe(int mapgen, int templateFilter, int mazeSize, String name, String seed, String theme, byte[] drawData) {
		this.mapgen = mapgen;
		this.templateFilter = templateFilter;
		this.mazeSize = mazeSize;
		this.name = name;
		this.seed = seed;
		this.theme = theme;
		this.drawData = drawData==null ? null : drawData.clone();
	}
	
	public static MapRecipe makeMap(String name, String seed, String theme) {
		return new MapRecipe(Frontlib.MAPGEN_NAMED, 0, 0, name, seed, theme, null);
	}
	
	public static MapRecipe makeRandomMap(int templateFilter, String seed, String theme) {
		return new MapRecipe(Frontlib.MAPGEN_REGULAR, templateFilter, 0, MAPNAME_REGULAR, seed, theme, null);
	}
	
	public static MapRecipe makeRandomMaze(int mazeSize, String seed, String theme) {
		return new MapRecipe(Frontlib.MAPGEN_MAZE, 0, mazeSize, MAPNAME_MAZE, seed, theme, null);
	}
	
	public static MapRecipe makeDrawnMap(String seed, String theme, byte[] drawData) {
		return new MapRecipe(Frontlib.MAPGEN_DRAWN, 0, 0, MAPNAME_DRAWN, seed, theme, drawData);
	}
	
	public byte[] getDrawData() {
		return drawData==null ? null : drawData.clone();
	}
	
	public static String formatMapName(Resources res, String map) {
		if(map.charAt(0)=='+') {
			if(map.equals(MAPNAME_REGULAR)) {
				return res.getString(R.string.map_regular);
			} else if(map.equals(MAPNAME_MAZE)) {
				return res.getString(R.string.map_maze);
			} else if(map.equals(MAPNAME_DRAWN)) {
				return res.getString(R.string.map_drawn);
			}
		}
		return map;
	}
}
