package org.hedgewars.hedgeroid.netplay;

import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

/**
 * A map of items, sorted by time of insertion (earliest first). 
 * Observers can be notified about insertions, deletions and changes (which don't change the order).
 * This is useful for e.g. the lists of current rooms and players, because it allows easy addition
 * and removal of entries on the one side, as well as reaction to these events by UI elements.
 */
public class ObservableLinkedHashMap<K,V> {
	private LinkedHashMap<K,V> map = new LinkedHashMap<K,V>();
	private List<Observer<K,V>> observers = new LinkedList<Observer<K,V>>();
	
	public Collection<V> getValues() {
		return Collections.unmodifiableCollection(map.values());
	}
	
	public Map<K,V> getMap() {
		return Collections.unmodifiableMap(map);
	}
	
	public void observe(Observer<K,V> observer) {
		observers.add(observer);
	}
	
	public void unobserve(Observer<K,V> observer) {
		observers.remove(observer);
	}
	
	// TODO ugh
	public void clear() {
		while(!map.isEmpty()) {
			remove(map.keySet().iterator().next());
		}
	}
	
	public void put(K key, V value) {
		V oldValue = map.put(key, value);
		Map<K,V> unmodifiableMap = Collections.unmodifiableMap(map);
		if(oldValue != null) {
			for(Observer<K,V> o : observers) {
				o.itemReplaced(unmodifiableMap, key, oldValue, value);
			}
		} else {
			for(Observer<K,V> o : observers) {
				o.itemAdded(unmodifiableMap, key, value);
			}
		}
	}
	
	public void remove(K key) {
		V oldValue = map.remove(key);
		if(oldValue != null) {
			Map<K,V> unmodifiableMap = Collections.unmodifiableMap(map);
			for(Observer<K,V> o : observers) {
				o.itemRemoved(unmodifiableMap, key, oldValue);
			}
		}
	}

	public static interface Observer<K,V> {
		void itemAdded(Map<K,V> map, K key, V value);
		void itemRemoved(Map<K,V> map, K key, V oldValue);
		void itemReplaced(Map<K,V> map, K key, V oldValue, V newValue);
	}
}
