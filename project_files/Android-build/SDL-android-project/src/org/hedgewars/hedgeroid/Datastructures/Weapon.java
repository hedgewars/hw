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
import java.util.ArrayList;

import org.hedgewars.hedgeroid.EngineProtocol.EngineProtocolNetwork;
import org.hedgewars.hedgeroid.EngineProtocol.PascalExports;
import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import org.xmlpull.v1.XmlPullParserFactory;

import android.content.Context;
import android.os.Parcel;
import android.os.Parcelable;

public class Weapon implements Parcelable, Comparable<Weapon>{

	public static final String DIRECTORY_WEAPON = "weapons";
	
	private String name;
	private String QT;
	private String prob;
	private String delay;
	private String crate;
	private static int maxWeapons;
	
	static{
		maxWeapons = PascalExports.HWgetNumberOfWeapons();
	}
	
	public Weapon(String _name, String _QT, String _prob, String _delay, String _crate){
		name = _name;
		
		//Incase there's a newer ammoStore which is bigger we append with zeros
		StringBuffer sb = new StringBuffer();
		while(_QT.length() + sb.length() < maxWeapons){
			sb.append('0');
		}
		
		QT = String.format("e%s %s%s", "ammloadt", _QT, sb);
		prob = String.format("e%s %s%s", "ammprob", _prob, sb);
		delay = String.format("e%s %s%s", "ammdelay", _delay, sb);
		crate = String.format("e%s %s%s", "ammreinf", _crate, sb);
	}
	
	public Weapon(Parcel in){
		readFromParcel(in);
	}
	
	public String toString(){
		return name;
	}
	
	public void sendToEngine(EngineProtocolNetwork epn, int teamsCount) throws IOException{
		epn.sendToEngine(QT);//command prefix is already in string 
		epn.sendToEngine(prob);
		epn.sendToEngine(delay);
		epn.sendToEngine(crate);
		
		for(int i = 0; i < teamsCount; i++){
			epn.sendToEngine("eammstore");
		}
	}
	
	public static final int STATE_START = 0;
	public static final int STATE_ROOT = 1;
	public static final int STATE_NAME = 2;
	public static final int STATE_QT = 3;
	public static final int STATE_PROBABILITY = 4;
	public static final int STATE_DELAY = 5;
	public static final int STATE_CRATE = 6;
	
	public static ArrayList<Weapon> getWeapons(Context c) throws IllegalArgumentException{
		String dir = c.getFilesDir().getAbsolutePath() + '/' + DIRECTORY_WEAPON + '/';
		String[] files = new File(dir).list();
		if(files == null) files = new String[]{};
		
		ArrayList<Weapon> weapons = new ArrayList<Weapon>();

		try {
			XmlPullParserFactory xmlPullFactory = XmlPullParserFactory.newInstance();
			XmlPullParser xmlPuller = xmlPullFactory.newPullParser();
			
			for(String file : files){
				BufferedReader br = new BufferedReader(new FileReader(dir + file), 1024);
				xmlPuller.setInput(br);
				String name = null;
				String qt = null;
				String prob = null;
				String delay = null;
				String crate = null;
				
				int eventType = xmlPuller.getEventType();
				int state = STATE_START;
				while(eventType != XmlPullParser.END_DOCUMENT){
					switch(state){
					case STATE_START:
						if(eventType == XmlPullParser.START_TAG && xmlPuller.getName().equals("weapon")) state = STATE_ROOT;
						else if(eventType != XmlPullParser.START_DOCUMENT) throwException(file, eventType);
						break;
					case STATE_ROOT:
						if(eventType == XmlPullParser.START_TAG){
							if(xmlPuller.getName().toLowerCase().equals("qt")) state = STATE_QT;
							else if(xmlPuller.getName().toLowerCase().equals("name")) state = STATE_NAME;
							else if(xmlPuller.getName().toLowerCase().equals("probability")) state = STATE_PROBABILITY;
							else if(xmlPuller.getName().toLowerCase().equals("delay")) state = STATE_DELAY;
							else if(xmlPuller.getName().toLowerCase().equals("crate")) state = STATE_CRATE;
							else throwException(file, eventType);
						}else if(eventType == XmlPullParser.END_TAG) state = STATE_START;
						else throwException(xmlPuller.getText(), eventType);
						break;
					case STATE_NAME:
						if(eventType == XmlPullParser.TEXT) name = xmlPuller.getText().trim();
						else if(eventType == XmlPullParser.END_TAG) state = STATE_ROOT;
						else throwException(file, eventType);
						break;
					case STATE_QT:
						if(eventType == XmlPullParser.TEXT) qt = xmlPuller.getText().trim();
						else if(eventType == XmlPullParser.END_TAG) state = STATE_ROOT;
						else throwException(file, eventType);
						break;
					case STATE_PROBABILITY:
						if(eventType == XmlPullParser.TEXT) prob = xmlPuller.getText().trim();
						else if(eventType == XmlPullParser.END_TAG) state = STATE_ROOT;
						else throwException(file, eventType);
						break;
					case STATE_DELAY:
						if(eventType == XmlPullParser.TEXT) delay = xmlPuller.getText().trim();
						else if(eventType == XmlPullParser.END_TAG) state = STATE_ROOT;
						else throwException(file, eventType);
						break;
					case STATE_CRATE:
						if(eventType == XmlPullParser.TEXT) crate = xmlPuller.getText().trim();
						else if(eventType == XmlPullParser.END_TAG) state = STATE_ROOT;
						else throwException(file, eventType);
						break;
					}
					eventType = xmlPuller.next();
					while(eventType == XmlPullParser.TEXT && xmlPuller.isWhitespace()){//Skip whitespaces
						eventType = xmlPuller.next();
					}
				}//end while(eventtype != END_DOCUMENT
				weapons.add(new Weapon(name, qt, prob, delay, crate));
			}//end for(string file : files
			return weapons;
			
		} catch (XmlPullParserException e) {
			e.printStackTrace();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return new ArrayList<Weapon>();//TODO handle correctly
	}
	
	private static void throwException(String file, int eventType){
		throw new IllegalArgumentException(String.format("Xml file: %s malformed with eventType: %d.", file, eventType));
	}

	public int describeContents() {
		return 0;
	}

	public void writeToParcel(Parcel dest, int flags) {
		dest.writeString(name);
		dest.writeString(QT);
		dest.writeString(prob);
		dest.writeString(delay);
		dest.writeString(crate);
	}
	
	private void readFromParcel(Parcel src){
		name = src.readString();
		QT = src.readString();
		prob = src.readString();
		delay = src.readString();
		crate = src.readString();
	}
	
	public static final Parcelable.Creator<Weapon> CREATOR = new Parcelable.Creator<Weapon>() {
		public Weapon createFromParcel(Parcel source) {
			return new Weapon(source);
		}
		public Weapon[] newArray(int size) {
			return new Weapon[size];
		}
		
	};

	public int compareTo(Weapon another) {
		return name.compareTo(another.name);
	}
	
	
}
