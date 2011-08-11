package org.hedgewars.mobile.TouchInterface;

import org.hedgewars.mobile.SDLActivity;

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
		
		if(firstEvent){
			firstEvent = false;
			SDLActivity.onNativeTouch(-1, -1, v.getWidth(), v.getHeight(), 1);
		}
		
		int action = event.getAction();
		int actionCode = action & MotionEvent.ACTION_MASK;
		
		for (int i = 0; i < event.getPointerCount(); i++) {
			SDLActivity.onNativeTouch(actionCode, event.getPointerId(i), event.getX(i), event.getY(i), event.getPressure(i));
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

