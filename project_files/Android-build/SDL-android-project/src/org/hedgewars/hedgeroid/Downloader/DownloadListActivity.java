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

import org.hedgewars.hedgeroid.R;

import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentTransaction;
import android.view.Gravity;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;

public class DownloadListActivity extends FragmentActivity implements OnItemMovementListener{

    private FrameLayout layout = null;
    private LinearLayout downloadQueueContainer = null;
    private View infoView = null;
    private ImageView arrow = null;
    private int halfSize = 0;
    private DownloadPackage task = null;

    public void onCreate(Bundle savedInstanceState){
        super.onCreate(savedInstanceState);

        setContentView(R.layout.download_listactivity);
        //FragmentManager fm = this.getSupportFragmentManager();
        //if(fm.findFragmentById(android.R.id.content) == null){
        //  DownloadListFragment listfrag = new DownloadListFragment();
        //  fm.beginTransaction().add(android.R.id.content, listfrag).commit();
        //}

        layout = (FrameLayout)findViewById(R.id.downloadFrameLayout);
        downloadQueueContainer = (LinearLayout) findViewById(R.id.downloadQueueContainer);
    }

    public void onNewItemSelected(DownloadPackage _task, int x, int minX, int maxX, int size) {
        if(layout != null){
            if(!_task.equals(task)){//if it's a new task refresh the whole thing
                task = _task;
                layout.removeView(infoView);
                infoView = null;
            }

            if(infoView == null){//build iv if it hasn't been created yet
                infoView = this.getLayoutInflater().inflate(R.layout.download_info, layout, false);
                FrameLayout.LayoutParams params = (android.widget.FrameLayout.LayoutParams) infoView.getLayoutParams();
                params.gravity = Gravity.NO_GRAVITY;
                params.height = size;
                arrow = (ImageView)infoView.findViewById(R.id.arrow);
                arrow.setVisibility(View.INVISIBLE);
                halfSize = size/2;

                Button yes = (Button)infoView.findViewById(R.id.download);
                Button no = (Button)infoView.findViewById(R.id.cancel);
                yes.setOnClickListener(yesClicker);
                no.setOnClickListener(noClicker);

                layout.addView(infoView, params);
            }
        }
    }

    public void onViewMoved(int x, int minX, int maxX) {
        if(halfSize == -1){
            if(infoView.getHeight() != 0){
                halfSize = infoView.getHeight()/2;
            }
        }
        if(layout != null && infoView != null){
            FrameLayout.LayoutParams params = ((FrameLayout.LayoutParams)infoView.getLayoutParams());
            if(x - halfSize < minX){
                params.topMargin = 0;
                arrow.setVisibility(View.INVISIBLE);
                params.gravity = Gravity.TOP;
            }else if (x + halfSize >= maxX){
                params.topMargin = 0;
                arrow.setVisibility(View.INVISIBLE);
                params.gravity = Gravity.BOTTOM;
            }else{
                params.topMargin = x - halfSize;
                params.gravity = Gravity.NO_GRAVITY;
                arrow.setVisibility(View.VISIBLE);
            }

            infoView.requestLayout();

        }
    }

    private OnClickListener yesClicker = new OnClickListener(){
        public void onClick(View v){
            FragmentManager fm = getSupportFragmentManager();
            FragmentTransaction ft= fm.beginTransaction();
            DownloadFragment df = DownloadFragment.getInstance(task);

            ft.add(R.id.downloadQueueContainer, df).commit();
            //ft.show(new DownloadFragment());

            task = null;
            layout.removeView(infoView);
        }
    };

    private OnClickListener noClicker = new OnClickListener(){
        public void onClick(View v){
            task = null;
            layout.removeView(infoView);
        }
    };
}
