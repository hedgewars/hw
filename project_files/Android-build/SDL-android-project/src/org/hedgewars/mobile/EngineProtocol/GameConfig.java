package org.hedgewars.mobile.EngineProtocol;

import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.UUID;

import android.os.Parcel;
import android.os.Parcelable;
import android.util.Log;

public class GameConfig implements Parcelable{
	
	public GameMode mode = GameMode.MODE_LOCAL;
	public Map map = null;
	public String theme = null;
	public Scheme scheme = null;
	public Weapon weapon = null;
	
	public String mission = null;
	public String seed = null;
	
	public ArrayList<Team> teams = new ArrayList<Team>(8);
	
	public GameConfig(){
		
	}
	
	public GameConfig(Parcel in){
		readFromParcel(in);	
	}
	

	
	public void sendToEngine(EngineProtocolNetwork epn) throws IOException{
		Log.d("HW_Frontend", "Sending Gameconfig...");
		int teamCount = 8;
		epn.sendToEngine("TL"); //Write game mode
		if(mission != null) epn.sendToEngine(mission);
		
		//seed info
		epn.sendToEngine(String.format("eseed {%s}", UUID.randomUUID().toString()));
		
		map.sendToEngine(epn);
		//dimensions of the map
		//templatefilter_command
		//mapgen_command
		//mazesize_command
		
		//epn.sendToEngine(String.format("etheme %s", theme));
		
		//scheme.sendToEngine(epn);
		
		//weapon.sendToEngine(os, teamCount);
		
		for(Team t : teams){
			//t.sendToEngine(os, teamCount, 50, 0);
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
		dest.writeString(mission);
		dest.writeString(seed);
		dest.writeParcelableArray((Team[])teams.toArray(new Team[1]), 0);
	}
	
	private void readFromParcel(Parcel src){
		mode = GameMode.valueOf(src.readString());
		map = src.readParcelable(Map.class.getClassLoader());
		theme = src.readString();
		scheme = src.readParcelable(Scheme.class.getClassLoader());
		weapon = src.readParcelable(Weapon.class.getClassLoader());
		mission = src.readString();
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
