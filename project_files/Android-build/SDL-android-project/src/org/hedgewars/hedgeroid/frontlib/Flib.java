package org.hedgewars.hedgeroid.frontlib;

import java.util.Collections;

import android.util.Log;

import com.sun.jna.Library;
import com.sun.jna.Native;

public class Flib {
	static {
		System.loadLibrary("SDL_net");
		System.setProperty("jna.encoding", "UTF8"); // Ugly global setting, but it seems JNA doesn't allow setting this per-library... 
	}
	public static final Frontlib INSTANCE = (Frontlib)Native.loadLibrary("frontlib", Frontlib.class, Collections.singletonMap(Library.OPTION_TYPE_MAPPER, AndroidTypeMapper.INSTANCE));
	
	// Hook frontlib logging into Android logging
	private static final Frontlib.LogCallback logCb = new Frontlib.LogCallback() {
		public void callback(int level, String message) {
			if(level >= Frontlib.FLIB_LOGLEVEL_ERROR) {
				Log.e("Frontlib", message);
			} else if(level == Frontlib.FLIB_LOGLEVEL_WARNING){
				Log.w("Frontlib", message);
			} else if(level == Frontlib.FLIB_LOGLEVEL_INFO){
				Log.i("Frontlib", message);
			} else if(level <= Frontlib.FLIB_LOGLEVEL_DEBUG){
				Log.d("Frontlib", message);
			}
		}
	};
	static {
		INSTANCE.flib_log_setLevel(Frontlib.FLIB_LOGLEVEL_ALL);
		INSTANCE.flib_log_setCallback(logCb);
	}
}