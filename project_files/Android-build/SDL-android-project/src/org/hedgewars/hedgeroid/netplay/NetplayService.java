package org.hedgewars.hedgeroid.netplay;

import java.io.IOException;

import android.app.Service;
import android.content.Intent;
import android.os.Binder;
import android.os.CountDownTimer;
import android.os.IBinder;

public class NetplayService extends Service {
	private final NetplayBinder binder = new NetplayBinder();
	public Netconn netconn;
	private CountDownTimer timer;
	
	@Override
	public IBinder onBind(Intent intent) {
		return binder;
	}
	
	@Override
	public void onCreate() {
		if(Flib.INSTANCE.flib_init() != 0) {
			throw new RuntimeException("Unable to start frontlib");
		}
		try {
			netconn = new Netconn(getApplicationContext(), "AndroidTester");
		} catch (IOException e) {
			// TODO better handling
			throw new RuntimeException("Unable to start frontlib");
		}
    	timer = new CountDownTimer(Long.MAX_VALUE, 50) {
			@Override
			public void onTick(long millisUntilFinished) {
				if(netconn != null) {
					netconn.tick();
				}
			}
			
			@Override
			public void onFinish() {
			}
		};
		timer.start();
	}
	
	@Override
	public void onDestroy() {
		netconn.disconnect();
		Flib.INSTANCE.flib_quit();
	}

	public class NetplayBinder extends Binder {
		Netconn getNetconn() {
            return netconn;
        }
	}

	public boolean isConnected() {
		return netconn!=null;
	}
}
