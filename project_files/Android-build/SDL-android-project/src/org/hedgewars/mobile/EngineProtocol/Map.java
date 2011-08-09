package org.hedgewars.mobile.EngineProtocol;

import java.io.File;
import java.io.IOException;

import android.content.Context;
import android.graphics.drawable.Drawable;
import android.os.Parcel;
import android.os.Parcelable;

public class Map implements Comparable<Map>, Parcelable{

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
	
	public Map(Parcel in){
		readFromParcel(in);
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
	
	public void sendToEngine(EngineProtocolNetwork epn) throws IOException{
		epn.sendToEngine(String.format("emap %s",name));
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

	@Override
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

	public int describeContents() {
		return 0;
	}
	
	public void writeToParcel(Parcel dest, int flags) {
		dest.writeString(name);
		dest.writeString(path);
		dest.writeString(previewPath);
		dest.writeString(type.name());
	}
	
	private void readFromParcel(Parcel src){
		name = src.readString();
		path = src.readString();
		previewPath = src.readString();
		type = MapType.valueOf(src.readString());
	}
	public static final Parcelable.Creator<Map> CREATOR = new Parcelable.Creator<Map>() {
		public Map createFromParcel(Parcel source) {
			return new Map(source);
		}
		public Map[] newArray(int size) {
			return new Map[size];
		}
		
	};
}
