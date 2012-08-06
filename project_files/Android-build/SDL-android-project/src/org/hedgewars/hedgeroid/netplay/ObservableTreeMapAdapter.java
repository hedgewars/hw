package org.hedgewars.hedgeroid.netplay;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import android.database.DataSetObserver;
import android.widget.BaseAdapter;

public abstract class ObservableTreeMapAdapter<K,V> extends BaseAdapter {
	private boolean sourceChanged = true;
	private List<V> entries = new ArrayList<V>();
	private ObservableTreeMap<K, V> source;
	
	private DataSetObserver observer = new DataSetObserver() {
		@Override
		public void onChanged() {
			sourceChanged = true;
			notifyDataSetChanged();
		}
		
		@Override
		public void onInvalidated() {
			invalidate();
		}
	};
	
	abstract protected Comparator<V> getEntryOrder();
	
	protected List<V> getEntries() {
		if(sourceChanged) {
			entries.clear();
			entries.addAll(source.getMap().values());
			Collections.sort(entries, getEntryOrder());
			sourceChanged = false;
		}
		return entries;
	}
	
	public int getCount() {
		return getEntries().size();
	}

	public void setSource(ObservableTreeMap<K,V> source) {
		if(this.source != null) {
			this.source.unregisterObserver(observer);
		}
		this.source = source;
		this.source.registerObserver(observer);
		sourceChanged = true;
		notifyDataSetChanged();
	}
	
	public void invalidate() {
		if(source != null) {
			source.unregisterObserver(observer);
		}
		source = null;
		notifyDataSetInvalidated();
	}
}