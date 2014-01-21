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

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import org.xmlpull.v1.XmlPullParserFactory;

import android.graphics.Color;
import android.os.Bundle;
import android.support.v4.app.ListFragment;
import android.util.Log;
import android.view.View;
import android.widget.AbsListView;
import android.widget.AbsListView.OnScrollListener;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ArrayAdapter;

public class DownloadListFragment extends ListFragment implements OnItemClickListener, OnScrollListener, Runnable{

    private View targetView = null;
    private ArrayList<OnItemMovementListener> listeners = new ArrayList<OnItemMovementListener>();

    public void onActivityCreated(Bundle savedInstanceState){
        super.onActivityCreated(savedInstanceState);

        ArrayList<DownloadPackage> tasks = new ArrayList<DownloadPackage>();

        ArrayAdapter<DownloadPackage> adapter = new ArrayAdapter<DownloadPackage>(getActivity().getApplicationContext(), android.R.layout.simple_list_item_1, tasks);
        setListAdapter(adapter);
        getListView().setOnItemClickListener(this);
        getListView().setOnScrollListener(this);

        if(getActivity() instanceof OnItemMovementListener){
            listeners.add((OnItemMovementListener)getActivity());
        }

        getListView().setCacheColorHint(Color.TRANSPARENT);//To prevent a blackish background while scrolling


        Thread t = new Thread(this, "DownloadListParser");
        t.start();
    }

    public void run(){
        XmlPullParserFactory xmlPullFactory;
        try {
            xmlPullFactory = XmlPullParserFactory.newInstance();
            XmlPullParser xmlPuller = xmlPullFactory.newPullParser();

            URL url = new URL("http://www.xelification.com/tmp/downloads.xml");
            HttpURLConnection conn = (HttpURLConnection)url.openConnection();

            BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream()), 1024);
            xmlPuller.setInput(br);

            final ArrayAdapter<DownloadPackage> adapter = (ArrayAdapter<DownloadPackage>) getListAdapter();

            int eventType = xmlPuller.getEventType();
            while(eventType != XmlPullParser.END_DOCUMENT){

                if(eventType == XmlPullParser.START_TAG){
                    if(xmlPuller.getName().toLowerCase().equals("task")){
                        final DownloadPackage task = DownloadPackage.getTaskFromXML(getActivity(), xmlPuller);

                        getActivity().runOnUiThread(new Runnable(){
                            public void run() {
                                adapter.add(task);
                            }
                        });
                    }
                }
                eventType = getEventType(xmlPuller);
            }


        } catch (XmlPullParserException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
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

    public void onItemClick(AdapterView<?> arg0, View arg1, int position, long arg3) {
        DownloadPackage task = (DownloadPackage)arg0.getAdapter().getItem(position);
        /*
        FragmentTransaction ft = getFragmentManager().beginTransaction();
        Fragment prev = getFragmentManager().findFragmentByTag("dialog");

        //remove any old dialogs
        if(prev != null) ft.remove(prev);
        ft.addToBackStack(null);

        //create a new dialog based on this task

        DialogFragment newFragment = DownloadDialogFragment.newInstance(task);

        //show it
        newFragment.show(ft, "dialog");
         */
        targetView = arg1;

        //determine state
        int min = arg0.getTop();
        int max = arg0.getBottom();
        int top = targetView.getTop();

        previousXCoord = top;
        for(OnItemMovementListener listener : listeners){
            listener.onNewItemSelected(task, top, min, max, targetView.getHeight()*2);
        }
    }

    private int previousXCoord = 0;

    /*
     * (non-Javadoc)
     * @see android.widget.AbsListView.OnScrollListener#onScroll(android.widget.AbsListView, int, int, int)
     *
     * Android renews the Items used in the view, so when a user scroll down the list,
     * as soon as the item has dissapeard from the list it gets reused at the bottom.
     *
     * For this reason we cannot just keep sending the targetView.getTop() but we must
     *  remember if the view is supposed to be at the top or bottom of the list. We
     *  remember this with int state,
     *     - 0 means we've got accurate reading from getTop()
     *     - -1 means it's somewhere at the top of the list
     *     - 1 means it's at the bottom somewhere
     */
    public void onScroll(AbsListView view, int firstVisibleItem, int visibleItemCount, int totalItemCount) {
        if(targetView != null){
            int top = targetView.getTop() + (targetView.getHeight()/2);
            int min = view.getTop();
            int max = view.getBottom();

            if(Math.abs(previousXCoord - top) > targetView.getHeight()*2 ){
                top = previousXCoord;
            }

            for(OnItemMovementListener listener : listeners){
                listener.onViewMoved(top, min, max);
            }

            previousXCoord = top;
        }
    }

    public void onScrollStateChanged(AbsListView view, int scrollState) {
        switch(scrollState){
        case OnScrollListener.SCROLL_STATE_FLING: Log.d("tag", "fling"); break;
        case OnScrollListener.SCROLL_STATE_IDLE:Log.d("tag", "idle"); break;
        case OnScrollListener.SCROLL_STATE_TOUCH_SCROLL:Log.d("tag", "scroll"); break;

        }

    }
}

interface OnItemMovementListener{
    /**
     * When I new item has been selected this method will be called
     * @param task The task which goes with this item
     * @param x The middle of this item
     * @param minX The top of the parent of this item
     * @param maxX The bottom of the parent of this item
     */
    void onNewItemSelected(DownloadPackage task, int x, int minX, int maxX, int size);

    /**
     * When the item has been moved this method is called
     * @param x The middle of this item
     * @param minX The top of the parent of this item
     * @param maxX The bottom of the parent of this item
     */
    void onViewMoved(int x, int minX, int maxX);
}

