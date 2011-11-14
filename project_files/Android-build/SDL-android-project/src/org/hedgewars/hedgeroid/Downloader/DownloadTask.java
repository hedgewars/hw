/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011 Richard Deurwaarder <xeli@xelification.com>
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

package org.hedgewars.hedgeroid.Downloader;

import java.io.IOException;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;

import android.os.Parcel;
import android.os.Parcelable;

public class DownloadTask implements Parcelable{

	private String url_without_suffix;
	private String pathToStore;
	private String representation;
	private int attempts;
	private int versionNumber;
	
	
	public DownloadTask(Parcel in){
		readFromParcel(in);
	}
	
	public DownloadTask(String _url_without_suffix, String path, int version, String _representation){
		url_without_suffix = _url_without_suffix;
		pathToStore = path;
		representation = _representation;
		versionNumber = version;
		attempts = 0;
	}
	
	public int getAttempts(){
		return attempts;
	}
	
	public String getURL(){
		return url_without_suffix;
	}
	
	public String getPathToStore(){
		return pathToStore;
	}
	
	public void incrementAttempts(){
		attempts++;
	}
	
	public String toString(){
		return representation;
	}
	
	public int describeContents() {
		return 0;
	}

	public void writeToParcel(Parcel dest, int flags) {
		dest.writeString(url_without_suffix);
		dest.writeString(pathToStore);
		dest.writeString(representation);
		dest.writeInt(versionNumber);
		dest.writeInt(attempts);
	}
	
	private void readFromParcel(Parcel src){
		url_without_suffix = src.readString();
		pathToStore = src.readString();
		representation = src.readString();
		versionNumber = src.readInt();
		attempts = src.readInt();
	}
	
	public static final Parcelable.Creator<DownloadTask> CREATOR = new Parcelable.Creator<DownloadTask>() {
		public DownloadTask createFromParcel(Parcel source) {
			return new DownloadTask(source);
		}
		public DownloadTask[] newArray(int size) {
			return new DownloadTask[size];
		}
	};
	
	/*
	 * We enter with a XmlPullParser.Start_tag with name "task"
	 */
	public static DownloadTask getTaskFromXML(XmlPullParser xmlPuller) throws XmlPullParserException, IOException{
		String url = null;
		String path = null;
		String representation = null;
		int version = -1;
		
		int eventType = xmlPuller.getEventType();//get the next token, should be a start tag
		while(eventType != XmlPullParser.END_DOCUMENT){
			switch(eventType){
			case XmlPullParser.START_TAG:
				String name = xmlPuller.getName().toLowerCase();
				if(name.equals("url")){
					if(xmlPuller.getEventType() == XmlPullParser.TEXT){
						url = xmlPuller.getText();
					}
				}else if(name.equals("version")){
					if(xmlPuller.getEventType() == XmlPullParser.TEXT){
						version = Integer.parseInt(xmlPuller.getText());
					}
				}else if(name.equals("path")){
					if(xmlPuller.getEventType() == XmlPullParser.TEXT){
						path = xmlPuller.getText();
					}
				}else if(name.equals("representation")){
					if(xmlPuller.getEventType() == XmlPullParser.TEXT){
						representation = xmlPuller.getText();
					}
				}
				
				xmlPuller.getEventType();//endtag
				break;
			case XmlPullParser.END_TAG:
				if(xmlPuller.getName().toLowerCase().equals("task") && url != null && path != null && version != -1 && representation != null){
					return new DownloadTask(url, path, version, representation);
				}else{
					throw new XmlPullParserException(null);
				}
			default:
				throw new XmlPullParserException(null);
			}
			eventType = getEventType(xmlPuller);
		}
		
		throw new XmlPullParserException(null);
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
}
