package org.hedgewars.hedgeroid.netplay;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.hedgewars.hedgeroid.netplay.MessageLog.Observer;

import android.content.Context;
import android.text.method.LinkMovementMethod;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AbsListView.LayoutParams;
import android.widget.BaseAdapter;
import android.widget.TextView;

/**
 * A simple TextView that remembers its contents to avoid having to
 * re-layout them.
 */
class LoglineView extends TextView {
	CharSequence chatlogAdapterText;
	
	public LoglineView(Context context) {
		super(context);
	}
}

public class ChatlogAdapter extends BaseAdapter implements Observer {
	long idOffset = 0;
	private List<CharSequence> log = new ArrayList<CharSequence>();
	private Context context;
	
	public ChatlogAdapter(Context context) {
		this.context = context;
	}
	
	public int getCount() {
		return log.size();
	}

	public Object getItem(int position) {
		return log.get(position);
	}

	public long getItemId(int position) {
		return position+idOffset;
	}

	public boolean hasStableIds() {
		return true;
	}

	public void clear() {
		idOffset += log.size();
		log.clear();
		notifyDataSetChanged();
	}
	
	public void lineAdded(CharSequence text) {
		log.add(text);
		notifyDataSetChanged();
	}
	
	public void lineRemoved() {
		log.remove(0);
		idOffset += 1;
		notifyDataSetChanged();
	}
	
	public void setLog(Collection<CharSequence> log) {
		idOffset += log.size();
		this.log = new ArrayList<CharSequence>(log);
		notifyDataSetChanged();
	}
	
	public View getView(int position, View convertView, ViewGroup parent) {
		LoglineView v = (LoglineView)convertView;
		CharSequence line = log.get(position);
		if (v == null) {
			v = new LoglineView(context);
			v.setLayoutParams(new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.WRAP_CONTENT));
			v.setMovementMethod(LinkMovementMethod.getInstance());
		}
		if(line != v.chatlogAdapterText) {
			v.setText(line);
			v.chatlogAdapterText = line;
		}
		return v;
	}
}