package org.hedgewars.mobile;

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Arrays;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import org.xmlpull.v1.XmlPullParserFactory;

import android.content.Context;
import android.content.res.TypedArray;

public class Scheme {

	public static final String DIRECTORY_SCHEME = "schemes";

	
	private String name;
	private ArrayList<Integer> basic;
	private ArrayList<Boolean> gamemod;

	public Scheme(String _name, ArrayList<Integer> _basic, ArrayList<Boolean> _gamemod){
		name = _name;
		basic = _basic;
		gamemod = _gamemod;
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
	
	public static Scheme[] getSchemes(Context c) throws IllegalArgumentException{
		String dir = c.getFilesDir().getAbsolutePath() + '/' + DIRECTORY_SCHEME + '/';
		String[] files = new File(dir).list();
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
				ArrayList<Boolean> gamemod = new ArrayList<Boolean>();
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
						if(eventType == XmlPullParser.TEXT) gamemod.add(false);
						else if(eventType == XmlPullParser.END_TAG) state = STATE_GAMEMOD;
						else throwException(file, eventType);
						break;
					case STATE_GAMEMOD_TRUE:
						if(eventType == XmlPullParser.TEXT) gamemod.add(true);
						else if(eventType == XmlPullParser.END_TAG) state = STATE_GAMEMOD;
						else throwException(file, eventType);
						break;
					}
					eventType = xmlPuller.next();
					while(eventType == XmlPullParser.TEXT && xmlPuller.isWhitespace()){//Skip whitespaces
						eventType = xmlPuller.next();
					}
				}//end while(eventtype != END_DOCUMENT
				schemes.add(new Scheme(name, basic, gamemod));
			}//end for(string file : files
			Scheme[] ret = new Scheme[schemes.size()];
			schemes.toArray(ret);
			return ret;
		} catch (XmlPullParserException e) {
			e.printStackTrace();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return new Scheme[]{};//TODO handle correctly
	}
	
	private static void throwException(String file, int eventType){
		throw new IllegalArgumentException(String.format("Xml file: %s malformed with eventType: %d.", file, eventType));
	}

	
}
