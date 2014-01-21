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
package org.hedgewars.hedgeroid.UserInput;

import org.hedgewars.hedgeroid.SDLActivity;

import android.os.Build;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnTouchListener;

public class TouchInterface{

    public static OnTouchListener getTouchInterface(){
        OnTouchListener toucher;
        if(Build.VERSION.SDK_INT < 5){//8 == Build.VERSION_CODES.FROYO
            toucher = new TouchInterfaceST();
        }else{
            toucher = new TouchInterfaceMT();
        }

        return toucher;
    }
}
/**
 * Touch interface with multitouch
 */
class TouchInterfaceMT implements OnTouchListener {

    private boolean firstEvent = true;

    public boolean onTouch(View v, MotionEvent event) {
        //dumpEvent(event);

        int action = event.getAction();
        int actionCode = action & MotionEvent.ACTION_MASK;

        for (int i = 0; i < event.getPointerCount(); i++) {
            SDLActivity.onNativeTouch(event.getDeviceId(),  event.getPointerId(i), actionCode, (int)event.getX(i), (int)event.getY(i), event.getPressure(i));
//          Log.d("Android", String.format("x=%f, y=%f, pntr=%d", event.getX(i), event.getY(i), event.getPointerId(i)));
           }
        return true;
    }

    /** Show an event in the LogCat view, for debugging */
    private void dumpEvent(MotionEvent event) {
       String names[] = { "DOWN" , "UP" , "MOVE" , "CANCEL" , "OUTSIDE" ,
          "POINTER_DOWN" , "POINTER_UP" , "7?" , "8?" , "9?" };
       StringBuilder sb = new StringBuilder();
       int action = event.getAction();
       int actionCode = action & MotionEvent.ACTION_MASK;
       sb.append("event ACTION_" ).append(names[actionCode]);
       if (actionCode == MotionEvent.ACTION_POINTER_DOWN
             || actionCode == MotionEvent.ACTION_POINTER_UP) {
          sb.append("(pid " ).append(
          action >> MotionEvent.ACTION_POINTER_ID_SHIFT);
          sb.append(")" );
       }
       sb.append("[" );
       for (int i = 0; i < event.getPointerCount(); i++) {
          sb.append("#" ).append(i);
          sb.append("(pid " ).append(event.getPointerId(i));
          sb.append(")=" ).append((int) event.getX(i));
          sb.append("," ).append((int) event.getY(i));
          if (i + 1 < event.getPointerCount())
             sb.append(";" );
       }
       sb.append("]" );
       Log.d("HW_APP_TOUCH", sb.toString());
    }

}

/**
 * Touch interface without multitouch
 */
class TouchInterfaceST implements OnTouchListener {

    public boolean onTouch(View v, MotionEvent event) {
        return false;
    }



}

