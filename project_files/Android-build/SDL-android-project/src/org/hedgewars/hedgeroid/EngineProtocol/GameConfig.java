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

package org.hedgewars.hedgeroid.EngineProtocol;

import java.io.IOException;
import java.util.ArrayList;
import java.util.UUID;

import org.hedgewars.hedgeroid.Datastructures.GameMode;
import org.hedgewars.hedgeroid.Datastructures.Map;
import org.hedgewars.hedgeroid.Datastructures.Scheme;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.Weapon;

import android.os.Parcel;
import android.os.Parcelable;
import android.util.Log;

public class GameConfig implements Parcelable{
	
	public GameMode mode = GameMode.MODE_LOCAL;
	public Map map = null;
	public String theme = null;
	public Scheme scheme = null;
	public Weapon weapon = null;
	
	public String style = null;
	public String training = null;
	public String seed = null;
	
	public ArrayList<Team> teams = new ArrayList<Team>();
	
	public GameConfig(){
		
	}
	
	public GameConfig(Parcel in){
		readFromParcel(in);	
	}
	

	
	public void sendToEngine(EngineProtocolNetwork epn) throws IOException{
		Log.d("HW_Frontend", "Sending Gameconfig...");
		int teamCount = 4;
		epn.sendToEngine("TL"); //Write game mode
		if(training != null) epn.sendToEngine(String.format("escript Scripts/Training/%s.lua", training));
		else if(style != null) epn.sendToEngine(String.format("escript Scripts/Multiplayer/%s.lua", style));
		
		//seed info
		epn.sendToEngine(String.format("eseed {%s}", UUID.randomUUID().toString()));
		
		map.sendToEngine(epn);
		//dimensions of the map
		//templatefilter_command
		//mapgen_command
		//mazesize_command
		
		epn.sendToEngine(String.format("etheme %s", theme));
		
		scheme.sendToEngine(epn);
		
		weapon.sendToEngine(epn, teamCount);
		
		for(Team t : teams){
			if(t != null)t.sendToEngine(epn, teamCount, scheme.health);
		}
	}
	
	public int describeContents() {
		return 0;
	}

	public void writeToParcel(Parcel dest, int flags) {
		dest.writeString(mode.name());
		dest.writeParcelable(map, flags);
		dest.writeString(theme);
		dest.writeParcelable(scheme, flags);
		dest.writeParcelable(weapon, flags);
		dest.writeString(style);
		dest.writeString(training);
		dest.writeString(seed);
		dest.writeParcelableArray((Team[])teams.toArray(new Team[1]), 0);
	}
	
	private void readFromParcel(Parcel src){
		mode = GameMode.valueOf(src.readString());
		map = src.readParcelable(Map.class.getClassLoader());
		theme = src.readString();
		scheme = src.readParcelable(Scheme.class.getClassLoader());
		weapon = src.readParcelable(Weapon.class.getClassLoader());
		style = src.readString();
		training = src.readString();
		seed = src.readString();
		Parcelable[] parcelables = src.readParcelableArray(Team[].class.getClassLoader());
		for(Parcelable team : parcelables){
			teams.add((Team)team);
		}
		
	}
	
	public static final Parcelable.Creator<GameConfig> CREATOR = new Parcelable.Creator<GameConfig>() {
		public GameConfig createFromParcel(Parcel source) {
			return new GameConfig(source);
		}
		public GameConfig[] newArray(int size) {
			return new GameConfig[size];
		}
	};
	
}
