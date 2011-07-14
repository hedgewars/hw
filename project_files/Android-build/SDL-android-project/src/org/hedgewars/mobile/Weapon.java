package org.hedgewars.mobile;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import org.xmlpull.v1.XmlPullParserFactory;

import android.content.Context;

public class Weapon {

	public static final String DIRECTORY_WEAPON = "weapons";
	
	private String name;
	private String QT;
	private String prob;
	private String delay;
	private String crate;
	
	public Weapon(String _name, String _QT, String _prob, String _delay, String _crate){
		name = _name;
		QT = _QT;
		prob = _prob;
		delay = _delay;
		crate = _crate;
	}
	
	public String toString(){
		return name;
	}
	
	public static final int STATE_START = 0;
	public static final int STATE_ROOT = 1;
	public static final int STATE_NAME = 2;
	public static final int STATE_QT = 3;
	public static final int STATE_PROBABILITY = 4;
	public static final int STATE_DELAY = 5;
	public static final int STATE_CRATE = 6;
	
	public static Weapon[] getWeapons(Context c) throws IllegalArgumentException{
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
			Weapon[] ret = new Weapon[weapons.size()];
			weapons.toArray(ret);
			return ret;
			
		} catch (XmlPullParserException e) {
			e.printStackTrace();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return new Weapon[]{};//TODO handle correctly
	}
	
	private static void throwException(String file, int eventType){
		throw new IllegalArgumentException(String.format("Xml file: %s malformed with eventType: %d.", file, eventType));
	}

}
