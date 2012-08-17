package org.hedgewars.hedgeroid;

import java.io.File;
import java.io.FileNotFoundException;

import org.hedgewars.hedgeroid.Datastructures.MapFile;
import org.hedgewars.hedgeroid.Datastructures.MapRecipe;
import org.hedgewars.hedgeroid.EngineProtocol.PascalExports;
import org.hedgewars.hedgeroid.frontlib.Flib;
import org.hedgewars.hedgeroid.frontlib.Frontlib;
import org.hedgewars.hedgeroid.frontlib.Frontlib.MapRecipePtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.MapconnPtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.MapimageCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.StrCallback;
import org.hedgewars.hedgeroid.util.FileUtils;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Bitmap.Config;
import android.graphics.Color;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import com.sun.jna.Pointer;

/**
 * A class that asynchronously generates a map preview from a MapRecipe.
 * 
 * For named maps, this will load the preview image from the filesystem. For others,
 * it will call the engine to generate a preview image.
 */
public final class MapPreviewGenerator implements Runnable {
	private static final String TAG = MapPreviewGenerator.class.getSimpleName();
	private static final Handler mainHandler = new Handler(Looper.getMainLooper());

	private final Context appContext;
	private final MapRecipe map;
	private final Listener listener;
	
	private boolean resultAvailable;
	private Drawable result;
	
	public static interface Listener {
		/**
		 * This is called on the UI thread once the preview is ready or failed.
		 * In case of failure, null is passed.
		 */
		void onMapPreviewResult(Drawable preview);
	}

	private MapPreviewGenerator(Context appContext, MapRecipe map, Listener listener) {
		this.appContext = appContext;
		this.map = map;
		this.listener = listener;
	}
	
	public void run() {
		if (map.mapgen == Frontlib.MAPGEN_NAMED) {
			postToListener(loadPreviewFromFile(appContext, map.name));
		} else {
			resultAvailable = false;
			result = null;
			MapconnPtr conn = Flib.INSTANCE.flib_mapconn_create(MapRecipePtr.createJavaOwned(map));
			if (conn == null) {
				postToListener(null);
				return;
			}
			try {
				int port = Flib.INSTANCE.flib_mapconn_getport(conn);
				Flib.INSTANCE.flib_mapconn_onSuccess(conn, successCb, null);
				Flib.INSTANCE.flib_mapconn_onFailure(conn, failureCb, null);
	
				String configPath;
				try {
					configPath = FileUtils.getCachePath(appContext).getAbsolutePath();
				} catch(FileNotFoundException e) {
					return;
				}
				
				startEngine(configPath, port);
				long startTime = System.nanoTime();
				do {
					Flib.INSTANCE.flib_mapconn_tick(conn);
					try {
						Thread.sleep(50);
					} catch (InterruptedException e) {
						// ignore
					}
				} while(!resultAvailable && System.nanoTime()-startTime < 15000000000l); // 15 seconds timeout
			} finally {
				Flib.INSTANCE.flib_mapconn_destroy(conn);
				postToListener(result);
			}
		}
	}
	
	public static void startPreviewGeneration(Context appContext, MapRecipe map, Listener listener) {
		new Thread(new MapPreviewGenerator(appContext, map, listener)).start();
	}
	
	private static Drawable loadPreviewFromFile(Context appContext, String mapName) {
		if(!mapName.startsWith("+")) {
			try {
				File previewFile = MapFile.getPreviewFile(appContext, mapName);
				return Drawable.createFromPath(previewFile.getAbsolutePath());
			} catch (FileNotFoundException e) {
				Log.w("MapPreviewGenerator", "Preview for map "+mapName+" not found.");
			}
		}
		return null;
	}
	
	private static void startEngine(final String configPath, final int port) {
		new Thread(new Runnable() {
			public void run() {
				Log.d(TAG, "Starting engine "+port);
				synchronized(PascalExports.engineMutex) {
					PascalExports.HWGenLandPreview(port);
				}
				Log.d(TAG, "Engine finished");
			}
		}).start();
	}
	
	private void postToListener(final Drawable result) {
		mainHandler.post(new Runnable() {
			public void run() {
				listener.onMapPreviewResult(result);
			}
		});
	}
	
	/**
	 * Let's be extra nice here and clip off the left and right sides, so the preview is centered...
	 * Since the image is present in bytes, we can save some effort by checking entire byte-columns first.
	 */
	private final MapimageCallback successCb = new MapimageCallback() {
		public void callback(Pointer context, Pointer buffer, int hedgehogCount) {
			Log.d(TAG, "Running success handler");
			byte[] mapdata = buffer.getByteArray(0, Frontlib.MAPIMAGE_BYTES);
			
			int leftmostPixel = Frontlib.MAPIMAGE_WIDTH;
			int rightmostPixel = -1;
			int bytesPerLine = Frontlib.MAPIMAGE_WIDTH/8;
			
			// Find the leftmost pixel
			for(int xbyte=0; xbyte<bytesPerLine; xbyte++) {
				for(int y=0; y<Frontlib.MAPIMAGE_HEIGHT; y++) {
					int b = 0xff&mapdata[xbyte+y*bytesPerLine];
					if(b != 0) {
						leftmostPixel = Math.min(leftmostPixel, Integer.numberOfLeadingZeros(b)-24+xbyte*8);
					}
				}
				if(leftmostPixel!=Frontlib.MAPIMAGE_WIDTH) break;
			}
			
			// Find the rightmost pixel
			for(int xbyte=bytesPerLine-1; xbyte>=0; xbyte--) {
				for(int y=0; y<Frontlib.MAPIMAGE_HEIGHT; y++) {
					int b = mapdata[xbyte+y*bytesPerLine];
					if(b != 0) {
						rightmostPixel = Math.max(rightmostPixel, xbyte*8+7-Integer.numberOfTrailingZeros(b));
					}
				}
				if(rightmostPixel!=-1) break;
			}
		
			// No pixel was set at all -> use default width
			if(rightmostPixel==-1) {
				leftmostPixel = 0;
				rightmostPixel = Frontlib.MAPIMAGE_WIDTH-1;
			}
			
			Bitmap bitmap = Bitmap.createBitmap(rightmostPixel-leftmostPixel+1, Frontlib.MAPIMAGE_HEIGHT, Config.ARGB_8888);
			for(int y=0; y<Frontlib.MAPIMAGE_HEIGHT; y++) {
				for(int x=0; x<bitmap.getWidth(); x++) {
					bitmap.setPixel(x, y, isPixelSet(mapdata, x+leftmostPixel, y) ? Color.YELLOW : Color.TRANSPARENT);
				}
			}
			result = new BitmapDrawable(bitmap);
			resultAvailable = true;
		}
	};
	
	private static boolean isPixelSet(byte[] imgdata, int x, int y) {
		int pixelnum = x+Frontlib.MAPIMAGE_WIDTH*y;
		return (imgdata[pixelnum>>3] & (128>>(pixelnum&7))) != 0;
	}
	
	private final StrCallback failureCb = new StrCallback() {
		public void callback(Pointer context, String reason) {
			Log.e(TAG, "Error generating map preview: "+reason);
			result = null;
			resultAvailable = true;
		}
	};
}