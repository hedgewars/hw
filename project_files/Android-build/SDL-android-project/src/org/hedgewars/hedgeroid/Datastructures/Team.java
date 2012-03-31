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

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;

import org.hedgewars.hedgeroid.EngineProtocol.EngineProtocolNetwork;
import org.hedgewars.hedgeroid.EngineProtocol.PascalExports;
import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import org.xmlpull.v1.XmlPullParserFactory;
import org.xmlpull.v1.XmlSerializer;

import android.content.Context;
import android.os.Parcel;
import android.os.Parcelable;
import android.util.Xml;

public class Team implements Parcelable{

	public static final String DIRECTORY_TEAMS = "teams";
	private static final Integer[] TEAM_COLORS = {
		0xd12b42, /* red    */ 
		0x4980c1, /* blue   */ 
		0x6ab530, /* green  */ 
		0xbc64c4, /* purple */ 
		0xe76d14, /* orange */ 
		0x3fb6e6, /* cyan   */ 
		0xe3e90c, /* yellow */ 
		0x61d4ac, /* mint   */ 
		0xf1c3e1, /* pink   */ 
		/* add new colors here */
	};

//	private static final Integer[] TEAM_COLORS = {
//		0xff0000, /* red    */ 
//		0x00ff00, /* blue   */ 
//		0x0000ff, /* green  */ 
//	};

	private static final int STATE_START = 0;
	private static final int STATE_ROOT = 1;
	private static final int STATE_HOG_ROOT = 2;

	public String name, grave, flag, voice, fort, hash;
	public String file = null;

	public static int maxNumberOfHogs = 0;
	public static int maxNumberOfTeams = 0;

	static{
		maxNumberOfHogs = PascalExports.HWgetMaxNumberOfHogs();
		maxNumberOfTeams = PascalExports.HWgetMaxNumberOfTeams();
	}
	public String[] hats = new String[maxNumberOfHogs];
	public String[] hogNames = new String[maxNumberOfHogs];
	public int[] levels = new int[maxNumberOfHogs];

	public int hogCount = 4;
	public int color = TEAM_COLORS[0];

	public Team(){
	}

	public Team(Parcel in){
		readFromParcel(in);
	}

	@Override
	public boolean equals(Object o){
		if(super.equals(o)) return true;
		else if(o instanceof Team){
			Team t = (Team)o;
			boolean ret = name.equals(t.name);
			ret &= grave.equals(t.grave);
			ret &= flag.equals(t.flag);
			ret &= voice.equals(t.voice);
			ret &= fort.equals(t.fort);
			ret &= hash.equals(t.hash);
			return ret;
		}else{
			return false;
		}
	}
	
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((name == null) ? 0 : name.hashCode());
		result = prime * result + ((grave == null) ? 0 : grave.hashCode());
		result = prime * result + ((flag == null) ? 0 : flag.hashCode());
		result = prime * result + ((voice == null) ? 0 : voice.hashCode());
		result = prime * result + ((fort == null) ? 0 : fort.hashCode());
		result = prime * result + ((hash == null) ? 0 : hash.hashCode());
		return result;
	}

	public void setRandomColor(int[] illegalcolors){
		Integer[] colorsToPickFrom = TEAM_COLORS;
		if(illegalcolors != null){
			ArrayList<Integer> colors = new ArrayList<Integer>();
			for(int color : TEAM_COLORS){
				boolean validColor = true;
				for(int illegal : illegalcolors){
					if(color == illegal) validColor = false;
				}
				if(validColor) colors.add(color);
			}
			if(colors.size() != 0) colorsToPickFrom = colors.toArray(new Integer[1]);
		}
		int index = (int)Math.round(Math.random()*(colorsToPickFrom.length-1));
		color = colorsToPickFrom[index];
	}


	public void sendToEngine(EngineProtocolNetwork epn, int hogCount, int health) throws IOException{
		epn.sendToEngine(String.format("eaddteam %s %d %s", hash, color, name));
		epn.sendToEngine(String.format("egrave %s", grave));
		epn.sendToEngine(String.format("efort %s", fort));
		epn.sendToEngine(String.format("evoicepack %s", voice));
		epn.sendToEngine(String.format("eflag %s", flag));

		for(int i = 0; i < hogCount; i++){
			epn.sendToEngine(String.format("eaddhh %d %d %s", levels[i], health, hogNames[i]));
			epn.sendToEngine(String.format("ehat %s", hats[i]));
		}
	}

	public void setFileName(Context c){
		if(file == null){
		  	file = validFileName(c, name);
		}
	}
	private String validFileName(Context c, String fileName){
		String absolutePath = String.format("%s/%s", c.getFilesDir(), fileName);
		File f = new File(absolutePath);
		if(f.exists()){
			String newFileName = fileName + (int)(Math.random()*10);
			return validFileName(c, newFileName);
		}else{
			return fileName;
		}
	}
	
	/*
	 * XML METHODS
	 */

	/**
	 * Read the xml file path and convert it to a Team object
	 * @param path absolute path to the xml file
	 * @return
	 */
	public static Team getTeamFromXml(String path){
		try {
			XmlPullParserFactory xmlPullFactory = XmlPullParserFactory.newInstance();
			XmlPullParser xmlPuller = xmlPullFactory.newPullParser();

			BufferedReader br = new BufferedReader(new FileReader(path), 1024);
			xmlPuller.setInput(br);
			Team team = new Team();
			int hogCounter = 0;

			int eventType = xmlPuller.getEventType();
			int state = STATE_START;
			while(eventType != XmlPullParser.END_DOCUMENT){
				switch(state){
				case STATE_START:
					if(eventType == XmlPullParser.START_TAG && xmlPuller.getName().equals("team")) state = STATE_ROOT;
					else if(eventType != XmlPullParser.START_DOCUMENT) throwException(path, eventType);
					break;
				case STATE_ROOT:
					if(eventType == XmlPullParser.START_TAG){
						if(xmlPuller.getName().toLowerCase().equals("name")){
							team.name = getXmlText(xmlPuller, "name");
						}else if(xmlPuller.getName().toLowerCase().equals("flag")){
							team.flag= getXmlText(xmlPuller, "flag");
						}else if(xmlPuller.getName().toLowerCase().equals("voice")){
							team.voice = getXmlText(xmlPuller, "voice");
						}else if(xmlPuller.getName().toLowerCase().equals("grave")){
							team.grave = getXmlText(xmlPuller, "grave");
						}else if(xmlPuller.getName().toLowerCase().equals("fort")){
							team.fort = getXmlText(xmlPuller, "fort");
						}else if(xmlPuller.getName().toLowerCase().equals("hash")){
							team.hash = getXmlText(xmlPuller, "hash");
						}else if(xmlPuller.getName().toLowerCase().equals("hog")){
							state = STATE_HOG_ROOT;
						}else throwException(xmlPuller.getName(), eventType);
					}else if(eventType == XmlPullParser.END_TAG) state = STATE_START;
					else throwException(xmlPuller.getText(), eventType);
					break;
				case STATE_HOG_ROOT:
					if(eventType == XmlPullParser.START_TAG){
						if(xmlPuller.getName().toLowerCase().equals("name")){
							team.hogNames[hogCounter] = getXmlText(xmlPuller, "name");
						}else if(xmlPuller.getName().toLowerCase().equals("hat")){
							team.hats[hogCounter] = getXmlText(xmlPuller, "hat");
						}else if(xmlPuller.getName().toLowerCase().equals("level")){
							team.levels[hogCounter] = Integer.parseInt(getXmlText(xmlPuller, "level"));
						}else throwException(xmlPuller.getText(), eventType);
					}else if(eventType == XmlPullParser.END_TAG){
						hogCounter++;
						state = STATE_ROOT;
					}else throwException(xmlPuller.getText(), eventType);
					break;
				}
				eventType = getEventType(xmlPuller);
			}//end while(eventtype != END_DOCUMENT
			return team;
		} catch (NumberFormatException e){
			e.printStackTrace();
		} catch (XmlPullParserException e) {
			e.printStackTrace();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return null;
	}

	private static String getXmlText(XmlPullParser xmlPuller, String parentTag)throws XmlPullParserException, IOException{
		if(getEventType(xmlPuller) == XmlPullParser.TEXT){
			String txt = xmlPuller.getText();
			if(getEventType(xmlPuller) == XmlPullParser.END_TAG && xmlPuller.getName().toLowerCase().equals(parentTag)){
				return txt;
			}
		}
		throw new XmlPullParserException("malformed xml file on string read from tag: " + parentTag);
	}

	/**
	 * Skips whitespaces..
	 */
	private static int getEventType(XmlPullParser xmlPuller)throws XmlPullParserException, IOException{
		int eventType = xmlPuller.next();
		while(eventType == XmlPullParser.TEXT && xmlPuller.isWhitespace()){
			eventType = xmlPuller.next();
		}
		return eventType;
	}

	private static void throwException(String file, int eventType){
		throw new IllegalArgumentException(String.format("Xml file: %s malformed with error: %d.", file, eventType));
	}

	public void writeToXml(OutputStream os){
		XmlSerializer serializer = Xml.newSerializer();
		try{
			serializer.setOutput(os, "UTF-8");	
			serializer.startDocument("UTF-8", true);
			serializer.setFeature("http://xmlpull.org/v1/doc/features.html#indent-output", true);

			serializer.startTag(null, "team");
			serializer.startTag(null, "name");
			serializer.text(name);
			serializer.endTag(null, "name");
			serializer.startTag(null, "flag");
			serializer.text(flag);
			serializer.endTag(null, "flag");
			serializer.startTag(null, "fort");
			serializer.text(fort);
			serializer.endTag(null, "fort");
			serializer.startTag(null, "grave");
			serializer.text(grave);
			serializer.endTag(null, "grave");
			serializer.startTag(null, "voice");
			serializer.text(voice);
			serializer.endTag(null, "voice");
			serializer.startTag(null, "hash");
			serializer.text(hash);
			serializer.endTag(null, "hash");

			for(int i = 0; i < maxNumberOfHogs; i++){
				serializer.startTag(null, "hog");
				serializer.startTag(null, "name");
				serializer.text(hogNames[i]);
				serializer.endTag(null, "name");
				serializer.startTag(null, "hat");
				serializer.text(hats[i]);
				serializer.endTag(null, "hat");
				serializer.startTag(null, "level");
				serializer.text(String.valueOf(levels[i]));
				serializer.endTag(null, "level");

				serializer.endTag(null, "hog");
			}
			serializer.endTag(null, "team");
			serializer.endDocument();
			serializer.flush();

		} catch (IOException e) {
			e.printStackTrace();
		}finally{
			try {
				os.close();
			} catch (IOException e) {}
		}
	}
	/*
	 * END XML METHODS
	 */



	/*
	 * PARCABLE METHODS
	 */

	public int describeContents() {
		return 0;
	}

	public void writeToParcel(Parcel dest, int flags) {
		dest.writeString(name);
		dest.writeString(grave);
		dest.writeString(flag);
		dest.writeString(voice);
		dest.writeString(fort);
		dest.writeString(hash);
		dest.writeStringArray(hats);
		dest.writeStringArray(hogNames);
		dest.writeIntArray(levels);
		dest.writeInt(color);
		dest.writeInt(hogCount);
		dest.writeString(file);
	}


	public void readFromParcel(Parcel src){
		name = src.readString();
		grave = src.readString();
		flag = src.readString();
		voice = src.readString();
		fort = src.readString();
		hash = src.readString();
		src.readStringArray(hats);
		src.readStringArray(hogNames);
		src.readIntArray(levels);
		color = src.readInt();
		hogCount = src.readInt();
		file = src.readString();
	}

	public static final Parcelable.Creator<Team> CREATOR = new Parcelable.Creator<Team>() {
		public Team createFromParcel(Parcel source) {
			return new Team(source);
		}
		public Team[] newArray(int size) {
			return new Team[size];
		}

	};

	/*
	 * END PARCABLE METHODS
	 */

}
