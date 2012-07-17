package org.hedgewars.hedgeroid.netplay;

import java.util.List;

public class Signal<CallbackType> {
	private List<CallbackType> observers; 
	
	public void addListener(CallbackType cb) {
		observers.add(cb);
	}
	
	public void removeListener(CallbackType cb) {
		observers.remove(cb);
	}
}
