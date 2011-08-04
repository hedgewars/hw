package org.hedgewars.mobile.EngineProtocol;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.OutputStream;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import org.xmlpull.v1.XmlPullParserFactory;
import org.xmlpull.v1.XmlSerializer;

import android.os.Parcel;
import android.os.Parcelable;
import android.util.Xml;

public class Team implements Parcelable{

	public static final String DIRECTORY_TEAMS = "teams";

	public String name, grave, flag, voice, fort, hash;

	public static int maxNumberOfHogs = 0;
	public static int maxNumberOfTeams = 0;

	static{
		maxNumberOfHogs = PascalExports.HWgetMaxNumberOfHogs();
		maxNumberOfTeams = PascalExports.HWgetMaxNumberOfTeams();
	}
	public String[] hats = new String[maxNumberOfHogs];
	public String[] hogNames = new String[maxNumberOfHogs];
	public int[] levels = new int[maxNumberOfHogs];
	
	public Team(){
	}
	
	public Team(Parcel in){
		readFromParcel(in);
	}

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
	
	
	public void sendToEngine(OutputStream os, int hogCount, int health, int color) throws IOException{
		os.write(String.format("eaddteam %s %d %s", hash, color, name).getBytes());
		os.write(String.format("egrave %s", grave).getBytes());
		os.write(String.format("efort %s", fort).getBytes());
		os.write(String.format("evoicepack %s", voice).getBytes());
		os.write(String.format("eflag %s", flag).getBytes());
		
		for(int i = 0; i < hogCount; i++){
			os.write(String.format("eaddhh %d %d %s", levels[i], health, hogNames[i]).getBytes());
			os.write(String.format("ehat %s", hats[i]).getBytes());
		}
		os.flush();
	}
	
	public static final int STATE_START = 0;
	public static final int STATE_ROOT = 1;
	public static final int STATE_HOG_ROOT = 2;
	public static final int STATE_HOG_HAT = 3;
	public static final int STATE_HOG_NAME = 4;
	public static final int STATE_HOG_LEVEL = 5;

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
	}

	public static final Parcelable.Creator<Team> CREATOR = new Parcelable.Creator<Team>() {
		public Team createFromParcel(Parcel source) {
			return new Team(source);
		}
		public Team[] newArray(int size) {
			return new Team[size];
		}
		
	};
	
}
