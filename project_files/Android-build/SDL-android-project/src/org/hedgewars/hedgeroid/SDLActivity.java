/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011-2012 Richard Deurwaarder <xeli@xelification.com>
 * Copyright (C) 2012 Simeon Maxein <smaxein@googlemail.com>
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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

package org.hedgewars.hedgeroid;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.ConnectException;

import javax.microedition.khronos.egl.EGL10;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.egl.EGLContext;
import javax.microedition.khronos.egl.EGLDisplay;
import javax.microedition.khronos.egl.EGLSurface;

import org.hedgewars.hedgeroid.Datastructures.GameConfig;
import org.hedgewars.hedgeroid.EngineProtocol.PascalExports;
import org.hedgewars.hedgeroid.netplay.Netplay;
import org.hedgewars.hedgeroid.util.FileUtils;

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
import android.util.Base64;
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
    /**
     * Set startConfig to the desired config when starting this activity. This avoids having to parcel all
     * the config objects into the Intent. Not particularly elegant, but it's actually a recommended
     * way to do this (http://developer.android.com/guide/faq/framework.html#3)
     */
    public static volatile GameConfig startConfig;
    public static volatile boolean startNetgame;

    // Main components
    public static SDLActivity mSingleton;
    private static SDLSurface mSurface;
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
        System.loadLibrary("main");
    }

    // Setup
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // So we can call stuff from static callbacks
        mSingleton = this;

        // Set up the surface
        mSurface = new SDLSurface(getApplication(), startConfig, startNetgame);
        startConfig = null;
        setContentView(mSurface);
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
                Log.w("SDL", "Problem stopping thread: " + e);
            }
            mSDLThread = null;
        }
        mSingleton = null;
    }

    public static void synchronizedNativeInit(String...args) {
        synchronized(PascalExports.engineMutex) {
            nativeInit(args);
        }
    }

    // C functions we call
    private static native void nativeInit(String...args);
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

    public static void setActivityTitle(final String title) {
        // Called from SDLMain() thread and can't directly affect the view
        mSingleton.runOnUiThread(new Runnable() {
            public void run() {
                mSingleton.setTitle(title);
            }
        });
    }

    public static Context getContext() {
        return mSingleton;
    }

    public static void startApp(final int width, final int height, GameConfig config, boolean netgame) {
        // Start up the C app thread
        if (mSDLThread == null) {
            mSDLThread = new Thread(new SDLMain(width, height, config, netgame));
            mSDLThread.start();
        } else {
            SDLActivity.nativeResume();
        }
    }

    // EGL functions
    public static boolean initEGL(int majorVersion, int minorVersion) {
        if (SDLActivity.mEGLDisplay == null) {
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
    public static final String TAG = "SDLMain";

    public static final int RQ_LOWRES            = 0x00000001; // use half land array
    public static final int RQ_BLURRY_LAND       = 0x00000002; // downscaled terrain
    public static final int RQ_NO_BACKGROUND     = 0x00000004; // don't draw background
    public static final int RQ_SIMPLE_ROPE       = 0x00000008; // avoid drawing rope
    public static final int RQ_2D_WATER          = 0x00000010; // disabe 3D water effect
    public static final int RQ_SIMPLE_EXPLOSIONS = 0x00000020; // no fancy explosion effects
    public static final int RQ_NO_FLAKES         = 0x00000040; // no flakes
    public static final int RQ_NO_MENU_ANIM      = 0x00000080; // ammomenu appears with no animation
    public static final int RQ_NO_DROPLETS       = 0x00000100; // no droplets
    public static final int RQ_NO_CLAMPING       = 0x00000200; // don't clamp textures
    public static final int RQ_NO_TOOLTIPS       = 0x00000400; // tooltips are not drawn
    public static final int RQ_NO_VSYNC          = 0x00000800; // don't sync on vblank

    private final int surfaceWidth, surfaceHeight;
    private final String playerName;
    private final GameConfig config;
    private final boolean netgame;

    public SDLMain(int width, int height, GameConfig config, boolean netgame) {
        surfaceWidth = width;
        surfaceHeight = height;
        if(netgame) {
            playerName = Netplay.getAppInstance(SDLActivity.getContext().getApplicationContext()).getPlayerName();
        } else {
            playerName = "Player";
        }
        this.config = config;
        this.netgame = netgame;
    }

    public void run() {
        //Set up the IPC socket server to communicate with the engine
        GameConnection gameConn;
        String path;
        try {
            if(netgame) {
                Netplay netplay = Netplay.getAppInstance(SDLActivity.mSingleton.getApplicationContext());
                gameConn = GameConnection.forNetgame(config, netplay);
            } else {
                gameConn = GameConnection.forLocalGame(config);
            }

            path = FileUtils.getDataPathFile(SDLActivity.mSingleton).getAbsolutePath();
            Log.d(TAG, "Starting engine");
            // Runs SDL_main() with added parameters
            try {
                String pPort = String.valueOf(gameConn.port);
                String pWidth = String.valueOf(surfaceWidth);
                String pHeight = String.valueOf(surfaceHeight);
                String pQuality = Integer.toString(RQ_NO_FLAKES|RQ_NO_DROPLETS|RQ_SIMPLE_EXPLOSIONS);
                String pPlayerName = Base64.encodeToString(playerName.getBytes("UTF-8"), 0);
                SDLActivity.synchronizedNativeInit(new String[] { pPort, pWidth, pHeight, pQuality, "en.txt", pPlayerName, "1", "1", "1", path, ""  });
            } catch (UnsupportedEncodingException e) {
                throw new AssertionError(e); // never happens
            }
            Log.d(TAG, "Engine stopped");
        } catch(ConnectException e) {
            Log.e(TAG, "Error starting IPC connection");
        } catch (IOException e) {
            Log.e(TAG, "Missing SDCard");
        }
        SDLActivity.mSingleton.runOnUiThread(new Runnable() { public void run() {
            if(SDLActivity.mSingleton != null) {
                SDLActivity.mSingleton.finish();
            }
        }});
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
    private boolean netgame;

    // Sensors
    private static SensorManager mSensorManager;

    // Startup
    public SDLSurface(Context context, GameConfig _config, boolean netgame) {
        super(context);
        getHolder().addCallback(this);

        setFocusable(true);
        setFocusableInTouchMode(true);
        requestFocus();
        setOnKeyListener(this);
        setOnTouchListener(this);

        mSensorManager = (SensorManager)context.getSystemService("sensor");
        config = _config;
        this.netgame = netgame;
    }

    // Called when we have a valid drawing surface
    public void surfaceCreated(SurfaceHolder holder) {
        Log.v("SDL", "surfaceCreated()");
        holder.setType(SurfaceHolder.SURFACE_TYPE_GPU);
        SDLActivity.createEGLSurface();
        //      enableSensor(Sensor.TYPE_ACCELEROMETER, true);
    }

    // Called when we lose the surface
    public void surfaceDestroyed(SurfaceHolder holder) {
        Log.v("SDL", "surfaceDestroyed()");
        SDLActivity.nativePause();
        //      enableSensor(Sensor.TYPE_ACCELEROMETER, false);
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

        SDLActivity.startApp(width, height, config, netgame);
    }

    // unused
    public void onDraw(Canvas canvas) {}




    // Key events
    public boolean onKey(View  v, int keyCode, KeyEvent event) {
        switch(keyCode){
        case KeyEvent.KEYCODE_BACK:
            Log.d("SDL", "KEYCODE_BACK");
            SDLActivity.nativeQuit();
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
        final int action = event.getAction() & MotionEvent.ACTION_MASK;
        final int actionPointerIndex = (event.getAction() & MotionEvent.ACTION_POINTER_ID_MASK) >> MotionEvent.ACTION_POINTER_INDEX_SHIFT;

        if (action == MotionEvent.ACTION_MOVE) {
            // TODO send motion to every pointer if its position has
            // changed since prev event.
            for (int i = 0; i < event.getPointerCount(); i++) {
                sendNativeTouch(event, action, i);
            }
        } else {
            sendNativeTouch(event, action, actionPointerIndex);
        }
        return true;
    }

    private static void sendNativeTouch(MotionEvent event, int action, int pointerIndex) {
        int touchDevId = event.getDeviceId();
        int pointerFingerId = event.getPointerId(pointerIndex);
        float x = event.getX(pointerIndex);
        float y = event.getY(pointerIndex);
        float pressure = event.getPressure(pointerIndex);
        SDLActivity.onNativeTouch(touchDevId, pointerFingerId, action, x, y, pressure);
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

