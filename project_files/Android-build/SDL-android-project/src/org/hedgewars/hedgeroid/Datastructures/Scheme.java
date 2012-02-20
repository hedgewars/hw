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
import java.io.FilenameFilter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;

import org.hedgewars.hedgeroid.EngineProtocol.EngineProtocolNetwork;
import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import org.xmlpull.v1.XmlPullParserFactory;

import android.content.Context;
import android.os.Parcel;
import android.os.Parcelable;

public class Scheme implements Parcelable, Comparable<Scheme>{

	public static final String DIRECTORY_SCHEME = "schemes";

	private String name;
	//private ArrayList<Integer> basic;
	private Integer gamemod;
	private ArrayList<Integer> basic;;
	private static ArrayList<LinkedHashMap<String, ?>> basicflags = new ArrayList<LinkedHashMap<String, ?>>();//TODO why is it static?
	public int health;
	
	public Scheme(String _name, ArrayList<Integer> _basic, int _gamemod){
		name = _name;
		gamemod = _gamemod;
		basic = _basic;
	}
	
	public Scheme(Parcel in){
		readFromParcel(in);
	}

	public void sendToEngine(EngineProtocolNetwork epn)throws IOException{ 
		epn.sendToEngine(String.format("e$gmflags %d", gamemod));

		for(int pos = 0; pos < basic.size(); pos++){
			LinkedHashMap<String, ?> basicflag = basicflags.get(pos);
			
			String command = (String)basicflag.get("command");
			Integer value = basic.get(pos);
			
			if(command.equals("inithealth")){//Health is a special case, it doesn't need to be send 				                             
				health = value;              //to the engine yet, we'll do that with the other HH info
				continue;
			}
			
			Boolean checkOverMax = (Boolean) basicflag.get("checkOverMax");
			Boolean times1000 = (Boolean) basicflag.get("times1000");
			Integer max = (Integer) basicflag.get("max");
			
			if(checkOverMax && value >= max) value = max;
			if(times1000) value *= 1000;
			
			epn.sendToEngine(String.format("%s %d", command, value));
		}
	}
	public String toString(){
		return name;
	}


	public static final int STATE_START = 0;
	public static final int STATE_ROOT = 1;
	public static final int STATE_NAME = 2;
	public static final int STATE_BASICFLAGS = 3;
	public static final int STATE_GAMEMOD = 4;
	public static final int STATE_BASICFLAG_INTEGER = 5;
	public static final int STATE_GAMEMOD_TRUE = 6;
	public static final int STATE_GAMEMOD_FALSE = 7;

	public static ArrayList<Scheme> getSchemes(Context c) throws IllegalArgumentException{
		String dir = c.getFilesDir().getAbsolutePath() + '/' + DIRECTORY_SCHEME + '/';
		String[] files = new File(dir).list(fnf);
		if(files == null) files = new String[]{};
		Arrays.sort(files);
		ArrayList<Scheme> schemes = new ArrayList<Scheme>();

		try {
			XmlPullParserFactory xmlPullFactory = XmlPullParserFactory.newInstance();
			XmlPullParser xmlPuller = xmlPullFactory.newPullParser();

			for(String file : files){
				BufferedReader br = new BufferedReader(new FileReader(dir + file), 1024);
				xmlPuller.setInput(br);
				String name = null;
				ArrayList<Integer> basic = new ArrayList<Integer>();
				Integer gamemod = 0;
				int health = 0;
				int mask = 0x000000004;

				int eventType = xmlPuller.getEventType();
				int state = STATE_START;
				while(eventType != XmlPullParser.END_DOCUMENT){
					switch(state){
					case STATE_START:
						if(eventType == XmlPullParser.START_TAG && xmlPuller.getName().equals("scheme")) state = STATE_ROOT;
						else if(eventType != XmlPullParser.START_DOCUMENT) throwException(file, eventType);
						break;
					case STATE_ROOT:
						if(eventType == XmlPullParser.START_TAG){
							if(xmlPuller.getName().equals("basicflags")) state = STATE_BASICFLAGS;
							else if(xmlPuller.getName().toLowerCase().equals("gamemod")) state = STATE_GAMEMOD;
							else if(xmlPuller.getName().toLowerCase().equals("name")) state = STATE_NAME;
							else throwException(file, eventType);
						}else if(eventType == XmlPullParser.END_TAG) state = STATE_START;
						else throwException(xmlPuller.getText(), eventType);
						break;
					case STATE_BASICFLAGS:
						if(eventType == XmlPullParser.START_TAG && xmlPuller.getName().toLowerCase().equals("integer")) state = STATE_BASICFLAG_INTEGER;
						else if(eventType == XmlPullParser.END_TAG)	state = STATE_ROOT;
						else throwException(file, eventType);
						break;
					case STATE_GAMEMOD:
						if(eventType == XmlPullParser.START_TAG){
							if(xmlPuller.getName().toLowerCase().equals("true")) state = STATE_GAMEMOD_TRUE;
							else if(xmlPuller.getName().toLowerCase().equals("false")) state = STATE_GAMEMOD_FALSE;
							else throwException(file, eventType);
						}else if(eventType == XmlPullParser.END_TAG) state = STATE_ROOT;
						else throwException(file, eventType);
						break;
					case STATE_NAME:
						if(eventType == XmlPullParser.TEXT) name = xmlPuller.getText().trim();
						else if(eventType == XmlPullParser.END_TAG) state = STATE_ROOT;
						else throwException(file, eventType);
						break;
					case STATE_BASICFLAG_INTEGER:
						if(eventType == XmlPullParser.TEXT) basic.add(Integer.parseInt(xmlPuller.getText().trim()));
						else if(eventType == XmlPullParser.END_TAG) state = STATE_BASICFLAGS;
						else throwException(file, eventType);
						break;
					case STATE_GAMEMOD_FALSE:
						if(eventType == XmlPullParser.TEXT) gamemod <<= 1;
						else if(eventType == XmlPullParser.END_TAG) state = STATE_GAMEMOD;
						else throwException(file, eventType);
						break;
					case STATE_GAMEMOD_TRUE:
						if(eventType == XmlPullParser.TEXT){
							gamemod |= mask;
							gamemod <<= 1;
						}else if(eventType == XmlPullParser.END_TAG) state = STATE_GAMEMOD;
						else throwException(file, eventType);
						break;
					}
					eventType = getEventType(xmlPuller);
				}//end while(eventtype != END_DOCUMENT
				schemes.add(new Scheme(name, basic, gamemod));
			}//end for(string file : files
			return schemes;
		} catch (XmlPullParserException e) {
			e.printStackTrace();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return new ArrayList<Scheme>();//TODO handle correctly
	}
	
	private static FilenameFilter fnf = new FilenameFilter(){
		public boolean accept(File dir, String filename) {
			return filename.toLowerCase().startsWith("scheme_");
		}
	};

	/**
	 * This method will parse the basic flags from a prespecified xml file.
	 * I use a raw xml file rather than one parsed by aatp at compile time
	 * to keep it generic with other frontends, ie in the future we could 
	 * use one provided by the Data folder.
	 */
	public static void parseBasicFlags(Context c){
		String filename = String.format("%s/%s/basicflags", c.getFilesDir().getAbsolutePath(), DIRECTORY_SCHEME);

		XmlPullParser xmlPuller = null;
		BufferedReader br = null;
		try {
			XmlPullParserFactory xmlPullFactory = XmlPullParserFactory.newInstance();
			xmlPuller = xmlPullFactory.newPullParser();
			br = new BufferedReader(new FileReader(filename), 1024);
			xmlPuller.setInput(br);

			int eventType = getEventType(xmlPuller);
			boolean continueParsing = true;
			do{
				switch(eventType){
				
				case XmlPullParser.START_TAG:
					if(xmlPuller.getName().toLowerCase().equals("flag")){
						basicflags.add(parseFlag(xmlPuller));
					}else if(xmlPuller.getName().toLowerCase().equals("basicflags")){
						eventType = getEventType(xmlPuller);
					}else{
						skipCurrentTag(xmlPuller);
						eventType = getEventType(xmlPuller);
					}
					break;
				case XmlPullParser.START_DOCUMENT://ignore all tags not being "flag"
				case XmlPullParser.END_TAG:
				case XmlPullParser.TEXT:
				default:
					continueParsing = true;
				case XmlPullParser.END_DOCUMENT:
					continueParsing = false;
				}
			}while(continueParsing);

		}catch(IOException e){
			e.printStackTrace();
		}catch (XmlPullParserException e) {
			e.printStackTrace();
		}finally{
			if(br != null)
				try {
					br.close();
				} catch (IOException e) {}
		}

	}

	/*
	 * * Parses a Tag structure from xml as example we use
	 *<flag>
	 *   <checkOverMax>
	 *       <boolean>false</boolean>
	 *   </checkOverMax>
	 *</flag>
	 *
	 * It returns a LinkedHashMap with key/value pairs
	 */
	private static LinkedHashMap<String, Object> parseFlag(XmlPullParser xmlPuller)throws XmlPullParserException, IOException{
		LinkedHashMap<String, Object> hash = new LinkedHashMap<String, Object>();

		int eventType = xmlPuller.getEventType();//Get the event type which triggered this method
		if(eventType == XmlPullParser.START_TAG && xmlPuller.getName().toLowerCase().equals("flag")){//valid start of flag tag
			String lcKey = null;
			String lcType = null;
			String value = null;

			eventType = getEventType(xmlPuller);//<checkOverMax>
			while(eventType == XmlPullParser.START_TAG){
				lcKey = xmlPuller.getName();//checkOverMax
				if(getEventType(xmlPuller) == XmlPullParser.START_TAG){//<boolean>
					lcType = xmlPuller.getName().toLowerCase();
					if(getEventType(xmlPuller) == XmlPullParser.TEXT){
						value = xmlPuller.getText();
						if(getEventType(xmlPuller) == XmlPullParser.END_TAG && //</boolean> 
								getEventType(xmlPuller) == XmlPullParser.END_TAG){//</checkOverMax>
							if(lcType.equals("boolean")) hash.put(lcKey, new Boolean(value));
							else if(lcType.equals("string"))hash.put(lcKey, value);							
							else if(lcType.equals("integer")){
								try{
									hash.put(lcKey, new Integer(value));
								}catch (NumberFormatException e){
									throw new XmlPullParserException("Wrong integer value in xml file");
								}
							}else{
								throwException("basicflags", eventType);
							}
						}//</boolean> / </checkOverMax>
					}//if TEXT
				}//if boolean
				eventType = getEventType(xmlPuller);//start new loop
			}
			eventType = getEventType(xmlPuller);//</flag>
		}

		return hash;
	}

	private static void skipCurrentTag(XmlPullParser xmlPuller) throws XmlPullParserException, IOException{
		int eventType = xmlPuller.getEventType();
		if(eventType != XmlPullParser.START_TAG)return;
		String tag = xmlPuller.getName().toLowerCase();

		while(true){
			eventType = getEventType(xmlPuller);//getNext()
			switch(eventType){
			case XmlPullParser.START_DOCUMENT://we're inside of a start tag so START_ or END_DOCUMENT is just wrong
			case XmlPullParser.END_DOCUMENT:
				throw new XmlPullParserException("invalid xml file");
			case XmlPullParser.START_TAG://if we get a new tag recursively handle it
				skipCurrentTag(xmlPuller);
				break;
			case XmlPullParser.TEXT:
				break;
			case XmlPullParser.END_TAG:
				if(!xmlPuller.getName().toLowerCase().equals(tag)){//if the end tag doesn't match the start tag
					throw new XmlPullParserException("invalid xml file");
				}else{
					return;//skip completed	
				}

			}
		}
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

	public int describeContents() {
		return 0;
	}

	public void writeToParcel(Parcel dest, int flags) {
		dest.writeString(name);
		dest.writeInt(gamemod);
		dest.writeList(basic);
	}
	
	public void readFromParcel(Parcel src){
		name = src.readString();
		gamemod = src.readInt();
		basic = src.readArrayList(ArrayList.class.getClassLoader());
	}

	public static final Parcelable.Creator<Scheme> CREATOR = new Parcelable.Creator<Scheme>() {
		public Scheme createFromParcel(Parcel source) {
			return new Scheme(source);
		}
		public Scheme[] newArray(int size) {
			return new Scheme[size];
		}
		
	};

	public int compareTo(Scheme another) {
		return name.compareTo(another.name);
	}
}
