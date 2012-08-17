package org.hedgewars.hedgeroid.util;

import android.os.Handler;
import android.os.Looper;
import android.os.Message;

/**
 * This class handles regularly calling a specified runnable
 * on the looper provided in the constructor. The first call
 * occurs without delay (though still via the looper), all
 * following calls are delayed by (approximately) the interval.
 * The interval can be changed at any time, which will cause
 * an immediate execution of the runnable again.
 */
public class TickHandler extends Handler {
	private final Runnable callback;
	private int messageId;
	private long interval;
	private boolean running;
	
	public TickHandler(Looper looper, long interval, Runnable callback) {
		super(looper);
		this.callback = callback;
		this.interval = interval;
	}
	
	public synchronized void stop() {
		messageId++;
		running = false;
	}
	
	public synchronized void start() {
		messageId++;
		sendMessage(obtainMessage(messageId));
		running = true;
	}
	
	public synchronized void setInterval(long interval) {
		this.interval = interval;
		if(running) {
			start();
		}
	}
	
	@Override
	public synchronized void handleMessage(Message msg) {
		if(msg.what == messageId) {
			callback.run();
		}
		if(msg.what == messageId) {
			sendMessageDelayed(obtainMessage(messageId), interval);
		}
	}
}