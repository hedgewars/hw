package org.hedgewars.hedgeroid.util;

import java.util.Collections;
import java.util.Map;
import java.util.TreeMap;

import android.database.DataSetObservable;

public class ObservableTreeMap<K,V> extends DataSetObservable {
	private final Map<K, V> map = new TreeMap<K, V>();
	
	public void replaceContent(Map<? extends K, ? extends V> newMap) {
		map.clear();
		map.putAll(newMap);
		notifyChanged();
	}
	
	public void put(K key, V value) {
		map.put(key, value);
		notifyChanged();
	}
	
	public V get(K key) {
		return map.get(key);
	}
	
	public void remove(K key) {
		if(map.remove(key) != null) {
			notifyChanged();
		}
	}
	
	public void clear() {
		if(!map.isEmpty()) {
			map.clear();
			notifyChanged();
		}
	}
	
	public Map<K, V> getMap() {
		return Collections.unmodifiableMap(map);
	}
}
