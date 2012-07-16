package org.hedgewars.hedgeroid.netplay;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Collections;

import org.hedgewars.hedgeroid.Utils;
import org.hedgewars.hedgeroid.netplay.JnaFrontlib.MetaschemePtr;
import org.hedgewars.hedgeroid.netplay.JnaFrontlib.NetconnPtr;

import com.sun.jna.Library;
import com.sun.jna.Native;

import android.app.Service;
import android.content.Intent;
import android.os.Binder;
import android.os.CountDownTimer;
import android.os.IBinder;

public class NetplayService extends Service {
	static {
		System.loadLibrary("SDL_net");
	}
	public static final JnaFrontlib FRONTLIB = (JnaFrontlib)Native.loadLibrary("frontlib", JnaFrontlib.class, Collections.singletonMap(Library.OPTION_TYPE_MAPPER, FrontlibTypeMapper.INSTANCE));

	private final NetplayBinder binder = new NetplayBinder();
	public NetconnPtr netconn;
	private CountDownTimer timer;
	private String playerName;
	
	@Override
	public IBinder onBind(Intent intent) {
		return binder;
	}
	
	@Override
	public void onCreate() {
		if(FRONTLIB.flib_init() != 0) {
			throw new RuntimeException("Unable to start frontlib");
		}
	}
	
	@Override
	public void onDestroy() {
		disconnect();
		FRONTLIB.flib_quit();
	}

	/**
	 * Connect to the official Hedgewars server.
	 * 
	 * @throws IOException if the metascheme file can't be read or the connection to the server fails
	 */
	public void connect(String playerName) throws IOException {
		connect(playerName, "140.247.62.101", 46631);
	}
	
	/**
	 * Connect to the server with the given hostname and port
	 * 
	 * @throws IOException if the metascheme file can't be read or the connection to the server fails
	 */
	public void connect(String playerName, String host, int port) throws IOException {
		if(playerName == null) {
			playerName = "Player";
		}
		this.playerName = playerName;
		MetaschemePtr meta = null;
		try {
			String metaschemePath = new File(Utils.getDataPathFile(this), "metasettings.ini").getAbsolutePath();
			meta = FRONTLIB.flib_metascheme_from_ini(metaschemePath);
			if(meta == null) {
				throw new RuntimeException("Missing metascheme");
			}
			netconn = FRONTLIB.flib_netconn_create(playerName, meta, Utils.getDataPathFile(this).getAbsolutePath(), host, port);
	    	timer = new CountDownTimer(Long.MAX_VALUE, 50) {
				@Override
				public void onTick(long millisUntilFinished) {
					if(netconn != null) {
						FRONTLIB.flib_netconn_tick(netconn);
					}
				}
				
				@Override
				public void onFinish() {
				}
			};
			timer.start();
		} catch(FileNotFoundException e) {
			throw new RuntimeException(e);
		} finally {
			FRONTLIB.flib_metascheme_release(meta);
		}
	}
	
	public void disconnect() {
		if(timer != null) {
			timer.cancel();
		}
		if(netconn != null) {
			FRONTLIB.flib_netconn_send_quit(netconn, "User quit");
			FRONTLIB.flib_netconn_destroy(netconn);
			netconn = null;
		}
	}
	
	public class NetplayBinder extends Binder {
		NetplayService getService() {
            return NetplayService.this;
        }
	}

	public String getPlayerName() {
		return playerName;
	}
}
