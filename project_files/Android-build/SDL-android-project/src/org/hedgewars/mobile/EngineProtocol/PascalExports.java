package org.hedgewars.mobile.EngineProtocol;

public class PascalExports {

	static{
		System.loadLibrary("SDL");
		System.loadLibrary("SDL_image");
		System.loadLibrary("mikmod");
		System.loadLibrary("SDL_net");
		System.loadLibrary("SDL_mixer");
		System.loadLibrary("SDL_ttf");
		System.loadLibrary("lua5.1");
		System.loadLibrary("hwengine");
	}
	
	public static native int HWversionInfoNetProto();
	public static native String HWversionInfoVersion();
	public static native int HWgetNumberOfWeapons();
	public static native int HWgetMaxNumberOfTeams();
	public static native int HWgetMaxNumberOfHogs();
	
}
