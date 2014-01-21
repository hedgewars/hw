/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011-2012 Richard Deurwaarder <xeli@xelification.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

package org.hedgewars.hedgeroid.Downloader;

import java.io.IOException;

import org.hedgewars.hedgeroid.util.FileUtils;
import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Parcel;
import android.os.Parcelable;
import android.preference.PreferenceManager;

public class DownloadPackage implements Parcelable{
    private String url_without_suffix;
    private String pathToStore;
    private String representation;
    private String description;
    private int versionNumber;
    private final Status status;
    private int uniqueId;


    public DownloadPackage(Parcel src){
        url_without_suffix = src.readString();
        pathToStore = src.readString();
        representation = src.readString();
        versionNumber = src.readInt();
        status = Status.values()[src.readInt()];
        description = src.readString();
        uniqueId = src.readInt();
    }

    public DownloadPackage(Context c, String _url_without_suffix, String path, int version, String _representation, String _description, int _uniqueId){
        url_without_suffix = _url_without_suffix;
        pathToStore = path;
        representation = _representation;
        versionNumber = version;
        description = _description;
        uniqueId = _uniqueId;


        //determine if the user has already downloaded this version
        SharedPreferences sharedPref = PreferenceManager.getDefaultSharedPreferences(c);
        int currentVersion = sharedPref.getInt(representation, -1);
        if(currentVersion == versionNumber) status = Status.CURRENTVERSION;
        else if (currentVersion < versionNumber) status = Status.NEWERVERSION;
        else status = Status.OLDERVERSION;
    }

    public Status getStatus(){
        return status;
    }

    public String getURL(){
        return url_without_suffix;
    }

    public String getPathToStore(){
        return pathToStore;
    }

    public String toString(){
        return representation;
    }

    public int describeContents() {
        return 0;
    }
    public int getId(){
        return uniqueId;
    }

    public void writeToParcel(Parcel dest, int flags) {
        dest.writeString(url_without_suffix);
        dest.writeString(pathToStore);
        dest.writeString(representation);
        dest.writeInt(versionNumber);
        dest.writeInt(status.ordinal());
        dest.writeString(description);
    }

    public static final Parcelable.Creator<DownloadPackage> CREATOR = new Parcelable.Creator<DownloadPackage>() {
        public DownloadPackage createFromParcel(Parcel source) {
            return new DownloadPackage(source);
        }
        public DownloadPackage[] newArray(int size) {
            return new DownloadPackage[size];
        }
    };

    /*
     * We enter with a XmlPullParser.Start_tag with name "task"
     */
    public static DownloadPackage getTaskFromXML(Context c, XmlPullParser xmlPuller) throws XmlPullParserException, IOException{
        String url = null;
        String path = null;
        String representation = null;
        String description = null;
        int uniqueId = -1;
        int version = -1;

        int eventType = DownloadPackage.getEventType(xmlPuller);//get the next token, should be a start tag
        while(eventType != XmlPullParser.END_DOCUMENT){
            switch(eventType){
            case XmlPullParser.START_TAG:
                String name = xmlPuller.getName().toLowerCase();
                if(DownloadPackage.getEventType(xmlPuller) == XmlPullParser.TEXT){
                    String text = xmlPuller.getText().trim();
                    if(name.equals("url")){
                        url = text;
                    }else if(name.equals("version")){
                        try{
                        version = Integer.parseInt(text);
                        }catch (NumberFormatException e){
                            e.printStackTrace();
                            version = -1;
                        }
                    }else if(name.equals("path")){
                        path = FileUtils.getDataPathFile(c, text).getAbsolutePath();
                    }else if(name.equals("representation")){
                        representation = text;
                    }else if(name.equals("description")){
                        description = text;
                    }else if(name.equals("uniqueid")){
                        try{
                            uniqueId = Integer.parseInt(text);
                            }catch (NumberFormatException e){
                                e.printStackTrace();
                                version = -1;
                            }
                    }
                }
                DownloadPackage.getEventType(xmlPuller);//endtag
                break;
            case XmlPullParser.END_TAG:
                if(xmlPuller.getName().toLowerCase().equals("task") && url != null && path != null && version != -1 && representation != null){
                    return new DownloadPackage(c, url, path, version, representation, description, uniqueId);
                }else{
                    throw new XmlPullParserException("XML download parsing: missing tags");
                }
            case XmlPullParser.TEXT:
                throw new XmlPullParserException("Wrong tag recieved got TEXT : " + xmlPuller.getText());
            default:
                throw new XmlPullParserException("Wrong tag recieved got: " + eventType);
            }
            eventType = DownloadPackage.getEventType(xmlPuller);
        }
        throw new XmlPullParserException("Xml: unexpected endofdocument tag");
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

enum Status{
    CURRENTVERSION, NEWERVERSION, OLDERVERSION;
}
