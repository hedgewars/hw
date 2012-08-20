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

import java.util.Arrays;
import java.util.UUID;

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
	
	public MapRecipe withMapgen(int mapgen) {
		return new MapRecipe(mapgen, templateFilter, mazeSize, name, seed, theme, drawData);
	}
	
	public MapRecipe withTemplateFilter(int templateFilter) {
		return new MapRecipe(mapgen, templateFilter, mazeSize, name, seed, theme, drawData);
	}
	
	public MapRecipe withMazeSize(int mazeSize) {
		return new MapRecipe(mapgen, templateFilter, mazeSize, name, seed, theme, drawData);
	}
	
	public MapRecipe withName(String name) {
		return new MapRecipe(mapgen, templateFilter, mazeSize, name, seed, theme, drawData);
	}
	
	public MapRecipe withSeed(String seed) {
		return new MapRecipe(mapgen, templateFilter, mazeSize, name, seed, theme, drawData);
	}
	
	public MapRecipe withTheme(String theme) {
		return new MapRecipe(mapgen, templateFilter, mazeSize, name, seed, theme, drawData);
	}
	
	public MapRecipe withDrawData(byte[] drawData) {
		return new MapRecipe(mapgen, templateFilter, mazeSize, name, seed, theme, drawData);
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

	/**
	 * Returns the mapname corresponding to the map generator (e.g. "+rnd+" for regular maps)
	 * If the mapgen does not have a unique name (MAPGEN_NAMED) or is not known, the def
	 * value is returned.
	 */
	public static String mapnameForGenerator(int mapgen, String def) {
		switch(mapgen) {
		case Frontlib.MAPGEN_REGULAR: return MAPNAME_REGULAR;
		case Frontlib.MAPGEN_MAZE: return MAPNAME_MAZE;
		case Frontlib.MAPGEN_DRAWN: return MAPNAME_DRAWN;
		default: return def;
		}
	}
	
	/**
	 * In a sense this is the inverse of mapnameForGenerator. Returns the mapgen that uses
	 * mapName as special identifier, or MAPGEN_NAMED if there is none.
	 */
	public static int generatorForMapname(String mapName) {
		if(MapRecipe.MAPNAME_REGULAR.equals(mapName)) {
			return Frontlib.MAPGEN_REGULAR;
		} else if(MapRecipe.MAPNAME_MAZE.equals(mapName)) {
			return Frontlib.MAPGEN_MAZE;
		} else if(MapRecipe.MAPNAME_DRAWN.equals(mapName)) {
			return Frontlib.MAPGEN_DRAWN;
		} else {
			return Frontlib.MAPGEN_NAMED;
		}
	}
	
	@Override
	public String toString() {
		return "MapRecipe [mapgen=" + mapgen + ", templateFilter="
				+ templateFilter + ", mazeSize=" + mazeSize + ", name=" + name
				+ ", seed=" + seed + ", theme=" + theme + ", drawData="
				+ Arrays.toString(drawData) + "]";
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + Arrays.hashCode(drawData);
		result = prime * result + mapgen;
		result = prime * result + mazeSize;
		result = prime * result + ((name == null) ? 0 : name.hashCode());
		result = prime * result + ((seed == null) ? 0 : seed.hashCode());
		result = prime * result + templateFilter;
		result = prime * result + ((theme == null) ? 0 : theme.hashCode());
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
		MapRecipe other = (MapRecipe) obj;
		if (!Arrays.equals(drawData, other.drawData))
			return false;
		if (mapgen != other.mapgen)
			return false;
		if (mazeSize != other.mazeSize)
			return false;
		if (name == null) {
			if (other.name != null)
				return false;
		} else if (!name.equals(other.name))
			return false;
		if (seed == null) {
			if (other.seed != null)
				return false;
		} else if (!seed.equals(other.seed))
			return false;
		if (templateFilter != other.templateFilter)
			return false;
		if (theme == null) {
			if (other.theme != null)
				return false;
		} else if (!theme.equals(other.theme))
			return false;
		return true;
	}

	public static String makeRandomSeed() {
		return "{"+UUID.randomUUID().toString()+"}";
	}
}
