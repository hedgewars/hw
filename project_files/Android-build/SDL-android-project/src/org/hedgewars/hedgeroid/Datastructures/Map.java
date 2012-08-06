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

import java.io.File;

import android.content.Context;
import android.graphics.drawable.Drawable;

public class Map implements Comparable<Map> {

	private static final String MISSION_PREFIX = "Mission: ";

	private String name;
	private String path;
	private String previewPath;
	private MapType type;

	public Map(File mapDir, MapType _type, Context c){
		type = _type;

		name = mapDir.getName();
		path = mapDir.getAbsolutePath();
		previewPath = path + "/preview.png";
		
		/*switch(type){
		case TYPE_DEFAULT:
			
			break;
		case TYPE_GENERATED:
			//TODO
			break;
		case TYPE_MISSION:
			name = MISSION_PREFIX + mapDir.getName();
			path = mapDir.getAbsolutePath();
			break;
		}*/

		
	}

	public String toString(){
		switch(type){
		default:
		case TYPE_DEFAULT:
			return name;
		case TYPE_GENERATED:
			return "bla";
		case TYPE_MISSION:
			return MISSION_PREFIX + name;
		}
	}
	
	public MapType getType(){
		return type;
	}

	public Drawable getDrawable(){
		switch(type){
		case TYPE_MISSION:
		case TYPE_DEFAULT:
			return Drawable.createFromPath(previewPath);
		case TYPE_GENERATED:

		default:
			return null;
		}
	}

	public int compareTo(Map another) {
		switch(type){
		case TYPE_GENERATED:
			switch(another.getType()){
			case TYPE_GENERATED:
				return name.compareTo(another.name);
			case TYPE_MISSION:
				return -1;
			case TYPE_DEFAULT:
				return -1;
			}
		case TYPE_MISSION:
			switch(another.getType()){
			case TYPE_GENERATED:
				return 1;
			case TYPE_MISSION:
				return name.compareTo(another.name);
			case TYPE_DEFAULT:
				return -1;
			}
		case TYPE_DEFAULT:
			switch(another.getType()){
			case TYPE_GENERATED:
				return 1;
			case TYPE_MISSION:
				return 1;
			case TYPE_DEFAULT:
				return name.compareTo(another.name);
			}
		}
		return 0;//default case this should never happen
	}

	public enum MapType{
		TYPE_DEFAULT, TYPE_MISSION, TYPE_GENERATED
	}
}
