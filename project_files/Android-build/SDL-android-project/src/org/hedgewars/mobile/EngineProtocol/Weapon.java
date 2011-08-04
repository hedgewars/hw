package org.hedgewars.mobile.EngineProtocol;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Arrays;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import org.xmlpull.v1.XmlPullParserFactory;

import android.content.Context;
import android.os.Parcel;
import android.os.Parcelable;

public class Weapon implements Parcelable{

	public static final String DIRECTORY_WEAPON = "weapons";
	
	private String name;
	private String QT;
	private String prob;
	private String delay;
	private String crate;
	private static int maxWeapons;
	
	static{
		//maxWeapons = PascalExports.HWgetNumberOfWeapons();
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
	
	public void sendToEngine(OutputStream os, int teamsCount) throws IOException{
		os.write(QT.getBytes());//command prefix is already in string 
		os.write(prob.getBytes());
		os.write(delay.getBytes());
		os.write(crate.getBytes());
		
		byte[] ammstore = "eammstore".getBytes();
		for(int i = 0; i < teamsCount; i++){
			os.write(ammstore);
		}
		os.flush();
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
		Arrays.sort(files);
		
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
}
