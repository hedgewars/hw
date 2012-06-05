package org.hedgewars.hedgeroid;

import javax.microedition.khronos.egl.EGL10;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.egl.EGLContext;
import javax.microedition.khronos.egl.EGLDisplay;
import javax.microedition.khronos.egl.EGLSurface;

import org.hedgewars.hedgeroid.EngineProtocol.EngineProtocolNetwork;
import org.hedgewars.hedgeroid.EngineProtocol.GameConfig;
import org.hedgewars.hedgeroid.EngineProtocol.PascalExports;

import android.app.Activity;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.PixelFormat;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;


/**
    SDL Activity
 */
public class SDLActivity extends Activity {

	// Main components
	public static SDLActivity mSingleton;
	private static SDLSurface mSurface;

	// This is what SDL runs in. It invokes SDL_main(), eventually
	private static Thread mSDLThread;

	// Audio
	private static Thread mAudioThread;
	private static AudioTrack mAudioTrack;

	// EGL private objects
	private static EGLContext  mEGLContext;
	private static EGLSurface  mEGLSurface;
	private static EGLDisplay  mEGLDisplay;
	private static EGLConfig   mEGLConfig;
	private static int mGLMajor, mGLMinor;

	// Load the .so
	static {
		System.loadLibrary("SDL");
		//System.loadLibrary("SDL_image");
		//System.loadLibrary("SDL_mixer");
		//System.loadLibrary("SDL_ttf");
		System.loadLibrary("main");
	}

	// Setup
	protected void onCreate(Bundle savedInstanceState) {
		//Log.v("SDL", "onCreate()");
		super.onCreate(savedInstanceState);

		// So we can call stuff from static callbacks
		mSingleton = this;

		// Set up the surface
		GameConfig config = getIntent().getParcelableExtra("config");

		mSurface = new SDLSurface(getApplication(), config);
		setContentView(mSurface);
		SurfaceHolder holder = mSurface.getHolder();
	}

	// Events
	protected void onPause() {
		Log.v("SDL", "onPause()");
		super.onPause();

		if(mEGLDisplay != null && mEGLContext != null){
			EGL10 egl = (EGL10)EGLContext.getEGL();
			egl.eglDestroyContext(mEGLDisplay, mEGLContext);
			mEGLDisplay = null;
			mEGLContext = null;
		}

		SDLActivity.nativePause();
	}

	protected void onResume() {
		Log.v("SDL", "onResume()");
		super.onResume();
	}

	protected void onDestroy() {
		super.onDestroy();
		Log.v("SDL", "onDestroy()");
		// Send a quit message to the application
		SDLActivity.nativeQuit();

		// Now wait for the SDL thread to quit
		if (mSDLThread != null) {
			try {
				mSDLThread.join();
			} catch(Exception e) {
				Log.v("SDL", "Problem stopping thread: " + e);
			}
			mSDLThread = null;

			//Log.v("SDL", "Finished waiting for SDL thread");
		}
	}

	// Messages from the SDLMain thread
	static int COMMAND_CHANGE_TITLE = 1;

	// Handler for the messages
	Handler commandHandler = new Handler() {
		public void handleMessage(Message msg) {
			if (msg.arg1 == COMMAND_CHANGE_TITLE) {
				setTitle((String)msg.obj);
			}
		}
	};

	// Send a message from the SDLMain thread
	void sendCommand(int command, Object data) {
		Message msg = commandHandler.obtainMessage();
		msg.arg1 = command;
		msg.obj = data;
		commandHandler.sendMessage(msg);
	}

	// C functions we call
	public static native void nativeInit(String...args);
	public static native void nativeQuit();
	public static native void nativePause();
	public static native void nativeResume();
	public static native void onNativeResize(int x, int y, int format);
	public static native void onNativeKeyDown(int keycode);
	public static native void onNativeKeyUp(int keycode);
	public static native void onNativeTouch(int touchDevId, int pointerFingerId,
			int action, float x, 
			float y, float p);
	public static native void onNativeAccel(float x, float y, float z);
	public static native void nativeRunAudioThread();


	// Java functions called from C

	public static boolean createGLContext(int majorVersion, int minorVersion) {
		return initEGL(majorVersion, minorVersion);
	}

	public static void flipBuffers() {
		flipEGL();
	}

	public static void setActivityTitle(String title) {
		// Called from SDLMain() thread and can't directly affect the view
		mSingleton.sendCommand(COMMAND_CHANGE_TITLE, title);
	}

	public static Context getContext() {
		return mSingleton;
	}

	public static void startApp(int width, int height, GameConfig config) {
		// Start up the C app thread
		if (mSDLThread == null) {
			mSDLThread = new Thread(new SDLMain(width, height, config), "SDLThread");
			mSDLThread.start();
		}
		else {
			SDLActivity.nativeResume();
		}
	}

	// EGL functions
	public static boolean initEGL(int majorVersion, int minorVersion) {
		if (SDLActivity.mEGLDisplay == null) {
			//Log.v("SDL", "Starting up OpenGL ES " + majorVersion + "." + minorVersion);

			try {
				EGL10 egl = (EGL10)EGLContext.getEGL();

				EGLDisplay dpy = egl.eglGetDisplay(EGL10.EGL_DEFAULT_DISPLAY);

				int[] version = new int[2];
				egl.eglInitialize(dpy, version);

				int EGL_OPENGL_ES_BIT = 1;
				int EGL_OPENGL_ES2_BIT = 4;
				int renderableType = 0;
				if (majorVersion == 2) {
					renderableType = EGL_OPENGL_ES2_BIT;
				} else if (majorVersion == 1) {
					renderableType = EGL_OPENGL_ES_BIT;
				}
				int[] configSpec = {
						//EGL10.EGL_DEPTH_SIZE,   16,
						EGL10.EGL_RENDERABLE_TYPE, renderableType,
						EGL10.EGL_NONE
				};
				EGLConfig[] configs = new EGLConfig[1];
				int[] num_config = new int[1];
				if (!egl.eglChooseConfig(dpy, configSpec, configs, 1, num_config) || num_config[0] == 0) {
					Log.e("SDL", "No EGL config available");
					return false;
				}
				EGLConfig config = configs[0];

				/*int EGL_CONTEXT_CLIENT_VERSION=0x3098;
                int contextAttrs[] = new int[] { EGL_CONTEXT_CLIENT_VERSION, majorVersion, EGL10.EGL_NONE };
                EGLContext ctx = egl.eglCreateContext(dpy, config, EGL10.EGL_NO_CONTEXT, contextAttrs);

                if (ctx == EGL10.EGL_NO_CONTEXT) {
                    Log.e("SDL", "Couldn't create context");
                    return false;
                }
                SDLActivity.mEGLContext = ctx;*/
				SDLActivity.mEGLDisplay = dpy;
				SDLActivity.mEGLConfig = config;
				SDLActivity.mGLMajor = majorVersion;
				SDLActivity.mGLMinor = minorVersion;

				SDLActivity.createEGLSurface();
			} catch(Exception e) {
				Log.v("SDL", e + "");
				for (StackTraceElement s : e.getStackTrace()) {
					Log.v("SDL", s.toString());
				}
			}
		}
		else SDLActivity.createEGLSurface();

		return true;
	}

	public static boolean createEGLContext() {
		EGL10 egl = (EGL10)EGLContext.getEGL();
		int EGL_CONTEXT_CLIENT_VERSION=0x3098;
		int contextAttrs[] = new int[] { EGL_CONTEXT_CLIENT_VERSION, SDLActivity.mGLMajor, EGL10.EGL_NONE };
		SDLActivity.mEGLContext = egl.eglCreateContext(SDLActivity.mEGLDisplay, SDLActivity.mEGLConfig, EGL10.EGL_NO_CONTEXT, contextAttrs);
		if (SDLActivity.mEGLContext == EGL10.EGL_NO_CONTEXT) {
			Log.e("SDL", "Couldn't create context");
			return false;
		}
		return true;
	}

	public static boolean createEGLSurface() {
		if (SDLActivity.mEGLDisplay != null && SDLActivity.mEGLConfig != null) {
			EGL10 egl = (EGL10)EGLContext.getEGL();
			if (SDLActivity.mEGLContext == null) createEGLContext();

			Log.v("SDL", "Creating new EGL Surface");
			EGLSurface surface = egl.eglCreateWindowSurface(SDLActivity.mEGLDisplay, SDLActivity.mEGLConfig, SDLActivity.mSurface, null);
			if (surface == EGL10.EGL_NO_SURFACE) {
				Log.e("SDL", "Couldn't create surface");
				return false;
			}

			if (!egl.eglMakeCurrent(SDLActivity.mEGLDisplay, surface, surface, SDLActivity.mEGLContext)) {
				Log.e("SDL", "Old EGL Context doesnt work, trying with a new one");
				createEGLContext();
				if (!egl.eglMakeCurrent(SDLActivity.mEGLDisplay, surface, surface, SDLActivity.mEGLContext)) {
					Log.e("SDL", "Failed making EGL Context current");
					return false;
				}
			}
			SDLActivity.mEGLSurface = surface;
			return true;
		}
		return false;
	}

	// EGL buffer flip
	public static void flipEGL() {
		try {
			EGL10 egl = (EGL10)EGLContext.getEGL();

			egl.eglWaitNative(EGL10.EGL_CORE_NATIVE_ENGINE, null);

			// drawing here

			egl.eglWaitGL();

			egl.eglSwapBuffers(SDLActivity.mEGLDisplay, SDLActivity.mEGLSurface);


		} catch(Exception e) {
			Log.v("SDL", "flipEGL(): " + e);
			for (StackTraceElement s : e.getStackTrace()) {
				Log.v("SDL", s.toString());
			}
		}
	}

	// Audio
	private static Object buf;

	public static Object audioInit(int sampleRate, boolean is16Bit, boolean isStereo, int desiredFrames) {
		int channelConfig = isStereo ? AudioFormat.CHANNEL_CONFIGURATION_STEREO : AudioFormat.CHANNEL_CONFIGURATION_MONO;
		int audioFormat = is16Bit ? AudioFormat.ENCODING_PCM_16BIT : AudioFormat.ENCODING_PCM_8BIT;
		int frameSize = (isStereo ? 2 : 1) * (is16Bit ? 2 : 1);

		Log.v("SDL", "SDL audio: wanted " + (isStereo ? "stereo" : "mono") + " " + (is16Bit ? "16-bit" : "8-bit") + " " + ((float)sampleRate / 1000f) + "kHz, " + desiredFrames + " frames buffer");

		// Let the user pick a larger buffer if they really want -- but ye
		// gods they probably shouldn't, the minimums are horrifyingly high
		// latency already
		desiredFrames = Math.max(desiredFrames, (AudioTrack.getMinBufferSize(sampleRate, channelConfig, audioFormat) + frameSize - 1) / frameSize);

		mAudioTrack = new AudioTrack(AudioManager.STREAM_MUSIC, sampleRate,
				channelConfig, audioFormat, desiredFrames * frameSize, AudioTrack.MODE_STREAM);

		audioStartThread();

		Log.v("SDL", "SDL audio: got " + ((mAudioTrack.getChannelCount() >= 2) ? "stereo" : "mono") + " " + ((mAudioTrack.getAudioFormat() == AudioFormat.ENCODING_PCM_16BIT) ? "16-bit" : "8-bit") + " " + ((float)mAudioTrack.getSampleRate() / 1000f) + "kHz, " + desiredFrames + " frames buffer");

		if (is16Bit) {
			buf = new short[desiredFrames * (isStereo ? 2 : 1)];
		} else {
			buf = new byte[desiredFrames * (isStereo ? 2 : 1)]; 
		}
		return buf;
	}

	public static void audioStartThread() {
		mAudioThread = new Thread(new Runnable() {
			public void run() {
				mAudioTrack.play();
				nativeRunAudioThread();
			}
		});

		// I'd take REALTIME if I could get it!
		mAudioThread.setPriority(Thread.MAX_PRIORITY);
		mAudioThread.start();
	}

	public static void audioWriteShortBuffer(short[] buffer) {
		for (int i = 0; i < buffer.length; ) {
			int result = mAudioTrack.write(buffer, i, buffer.length - i);
			if (result > 0) {
				i += result;
			} else if (result == 0) {
				try {
					Thread.sleep(1);
				} catch(InterruptedException e) {
					// Nom nom
				}
			} else {
				Log.w("SDL", "SDL audio: error return from write(short)");
				return;
			}
		}
	}

	public static void audioWriteByteBuffer(byte[] buffer) {
		for (int i = 0; i < buffer.length; ) {
			int result = mAudioTrack.write(buffer, i, buffer.length - i);
			if (result > 0) {
				i += result;
			} else if (result == 0) {
				try {
					Thread.sleep(1);
				} catch(InterruptedException e) {
					// Nom nom
				}
			} else {
				Log.w("SDL", "SDL audio: error return from write(short)");
				return;
			}
		}
	}

	public static void audioQuit() {
		if (mAudioThread != null) {
			try {
				mAudioThread.join();
			} catch(Exception e) {
				Log.v("SDL", "Problem stopping audio thread: " + e);
			}
			mAudioThread = null;

			//Log.v("SDL", "Finished waiting for audio thread");
		}

		if (mAudioTrack != null) {
			mAudioTrack.stop();
			mAudioTrack = null;
		}
	}
	
	public static int getDensity(){
		DisplayMetrics dm = SDLActivity.getContext().getResources().getDisplayMetrics();
		return dm.densityDpi;
	}
}

/**
    Simple nativeInit() runnable
 */
class SDLMain implements Runnable {

	private int surfaceWidth, surfaceHeight;
	private GameConfig config;

	public SDLMain(int width, int height, GameConfig _config) {
		config = _config;
		surfaceWidth = width;
		surfaceHeight = height;
	}

	public void run() {
		//Set up the IPC socket server to communicate with the engine
		EngineProtocolNetwork ipc = new EngineProtocolNetwork(config);

		String path = Utils.getDataPath(SDLActivity.mSingleton);//This represents the data directory
		path = path.substring(0, path.length()-1);//remove the trailing '/'


		// Runs SDL_main() with added parameters
		SDLActivity.nativeInit(new String[] { String.valueOf(ipc.port),
				String.valueOf(surfaceWidth), String.valueOf(surfaceHeight),
				"0", "en.txt", "xeli", "1", "1", "1", path, ""  });

		try {
			ipc.quitIPC();
			ipc.join();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		Log.v("SDL", "SDL thread terminated");
		//Log.v("SDL", "SDL thread terminated");
	}
}


/**
    SDLSurface. This is what we draw on, so we need to know when it's created
    in order to do anything useful. 

    Because of this, that's where we set up the SDL thread
 */
class SDLSurface extends SurfaceView implements SurfaceHolder.Callback, 
View.OnKeyListener, View.OnTouchListener, SensorEventListener  {

	private GameConfig config;

	// Sensors
	private static SensorManager mSensorManager;

	// Startup    
	public SDLSurface(Context context, GameConfig _config) {
		super(context);
		getHolder().addCallback(this); 

		setFocusable(true);
		setFocusableInTouchMode(true);
		requestFocus();
		setOnKeyListener(this); 
		setOnTouchListener(this);   

		mSensorManager = (SensorManager)context.getSystemService("sensor");
		config = _config;
	}

	// Called when we have a valid drawing surface
	public void surfaceCreated(SurfaceHolder holder) {
		Log.v("SDL", "surfaceCreated()");
		holder.setType(SurfaceHolder.SURFACE_TYPE_GPU);
		SDLActivity.createEGLSurface();
		//		enableSensor(Sensor.TYPE_ACCELEROMETER, true);
	}

	// Called when we lose the surface
	public void surfaceDestroyed(SurfaceHolder holder) {
		Log.v("SDL", "surfaceDestroyed()");
		SDLActivity.nativePause();
		//		enableSensor(Sensor.TYPE_ACCELEROMETER, false);
	}

	// Called when the surface is resized
	public void surfaceChanged(SurfaceHolder holder,
			int format, int width, int height) {
		Log.v("SDL", "surfaceChanged()");

		int sdlFormat = 0x85151002; // SDL_PIXELFORMAT_RGB565 by default
		switch (format) {
		case PixelFormat.A_8:
			Log.v("SDL", "pixel format A_8");
			break;
		case PixelFormat.LA_88:
			Log.v("SDL", "pixel format LA_88");
			break;
		case PixelFormat.L_8:
			Log.v("SDL", "pixel format L_8");
			break;
		case PixelFormat.RGBA_4444:
			Log.v("SDL", "pixel format RGBA_4444");
			sdlFormat = 0x85421002; // SDL_PIXELFORMAT_RGBA4444
			break;
		case PixelFormat.RGBA_5551:
			Log.v("SDL", "pixel format RGBA_5551");
			sdlFormat = 0x85441002; // SDL_PIXELFORMAT_RGBA5551
			break;
		case PixelFormat.RGBA_8888:
			Log.v("SDL", "pixel format RGBA_8888");
			sdlFormat = 0x86462004; // SDL_PIXELFORMAT_RGBA8888
			break;
		case PixelFormat.RGBX_8888:
			Log.v("SDL", "pixel format RGBX_8888");
			sdlFormat = 0x86262004; // SDL_PIXELFORMAT_RGBX8888
			break;
		case PixelFormat.RGB_332:
			Log.v("SDL", "pixel format RGB_332");
			sdlFormat = 0x84110801; // SDL_PIXELFORMAT_RGB332
			break;
		case PixelFormat.RGB_565:
			Log.v("SDL", "pixel format RGB_565");
			sdlFormat = 0x85151002; // SDL_PIXELFORMAT_RGB565
			break;
		case PixelFormat.RGB_888:
			Log.v("SDL", "pixel format RGB_888");
			// Not sure this is right, maybe SDL_PIXELFORMAT_RGB24 instead?
			sdlFormat = 0x86161804; // SDL_PIXELFORMAT_RGB888
			break;
		default:
			Log.v("SDL", "pixel format unknown " + format);
			break;
		}
		SDLActivity.onNativeResize(width, height, sdlFormat);
		Log.v("SDL", "Window size:" + width + "x"+height);

		SDLActivity.startApp(width, height, config);
	}

	// unused
	public void onDraw(Canvas canvas) {}




	// Key events
	public boolean onKey(View  v, int keyCode, KeyEvent event) {
		switch(keyCode){
		case KeyEvent.KEYCODE_BACK:
		        PascalExports.HWterminate(true);
                        return true;
		case KeyEvent.KEYCODE_VOLUME_DOWN:
		case KeyEvent.KEYCODE_VOLUME_UP:
		case KeyEvent.KEYCODE_VOLUME_MUTE:
			return false;
		}
		if (event.getAction() == KeyEvent.ACTION_DOWN) {
			//Log.v("SDL", "key down: " + keyCode);
			SDLActivity.onNativeKeyDown(keyCode);
			return true;
		}
		else if (event.getAction() == KeyEvent.ACTION_UP) {
			//Log.v("SDL", "key up: " + keyCode);
			SDLActivity.onNativeKeyUp(keyCode);
			return true;
		}

		return false;
	}

	// Touch events
	public boolean onTouch(View v, MotionEvent event) {
		{
			final int touchDevId = event.getDeviceId();
			final int pointerCount = event.getPointerCount();
			// touchId, pointerId, action, x, y, pressure
			int actionPointerIndex = event.getActionIndex();
			int pointerFingerId = event.getPointerId(actionPointerIndex);
			int action = event.getActionMasked();

			float x = event.getX(actionPointerIndex);
			float y = event.getY(actionPointerIndex);
			float p = event.getPressure(actionPointerIndex);

			if (action == MotionEvent.ACTION_MOVE && pointerCount > 1) {
				// TODO send motion to every pointer if its position has
				// changed since prev event.
				for (int i = 0; i < pointerCount; i++) {
					pointerFingerId = event.getPointerId(i);
					x = event.getX(i);
					y = event.getY(i);
					p = event.getPressure(i);
					SDLActivity.onNativeTouch(touchDevId, pointerFingerId, action, x, y, p);
				}
			} else {
				SDLActivity.onNativeTouch(touchDevId, pointerFingerId, action, x, y, p);
			}
		}
		return true;
	} 

	// Sensor events
	public void enableSensor(int sensortype, boolean enabled) {
		// TODO: This uses getDefaultSensor - what if we have >1 accels?
		if (enabled) {
			mSensorManager.registerListener(this, 
					mSensorManager.getDefaultSensor(sensortype), 
					SensorManager.SENSOR_DELAY_GAME, null);
		} else {
			mSensorManager.unregisterListener(this, 
					mSensorManager.getDefaultSensor(sensortype));
		}
	}

	public void onAccuracyChanged(Sensor sensor, int accuracy) {
		// TODO
	}

	public void onSensorChanged(SensorEvent event) {
		if (event.sensor.getType() == Sensor.TYPE_ACCELEROMETER) {
			SDLActivity.onNativeAccel(event.values[0] / SensorManager.GRAVITY_EARTH,
					event.values[1] / SensorManager.GRAVITY_EARTH,
					event.values[2] / SensorManager.GRAVITY_EARTH);
		}
	}

}

