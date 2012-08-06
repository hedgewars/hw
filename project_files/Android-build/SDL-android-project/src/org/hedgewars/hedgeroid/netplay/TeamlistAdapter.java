package org.hedgewars.hedgeroid.netplay;

import java.util.Comparator;

import org.hedgewars.hedgeroid.Datastructures.TeamInGame;

import android.content.Context;
import android.util.Pair;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

public class TeamlistAdapter extends ObservableTreeMapAdapter<String, Pair<TeamInGame, Long>> {
	private Context context;
	
	public TeamlistAdapter(Context context) {
		this.context = context;
	}
	
	@Override
	protected Comparator<Pair<TeamInGame, Long>> getEntryOrder() {
		return AlphabeticalOrderComparator.INSTANCE;
	}

	public TeamInGame getItem(int position) {
		return getEntries().get(position).first;
	}

	public long getItemId(int position) {
		return getEntries().get(position).second;
	}

	public boolean hasStableIds() {
		return true;
	}
	
	public View getView(int position, View convertView, ViewGroup parent) {
		View v = convertView;
		if (v == null) {
			LayoutInflater vi = LayoutInflater.from(context);
			v = vi.inflate(android.R.layout.simple_list_item_2, null);
		}

		TeamInGame team = getItem(position);
		TextView tv1 = (TextView) v.findViewById(android.R.id.text1);
		TextView tv2 = (TextView) v.findViewById(android.R.id.text2);
		
		tv1.setText(team.team.name);
		tv2.setText("Hogs: "+team.ingameAttribs.hogCount);
		return v;
	}
	
	private static final class AlphabeticalOrderComparator implements Comparator<Pair<TeamInGame, Long>> {
		public static final AlphabeticalOrderComparator INSTANCE = new AlphabeticalOrderComparator();
		public int compare(Pair<TeamInGame, Long> lhs, Pair<TeamInGame, Long> rhs) {
			return lhs.first.team.name.compareToIgnoreCase(rhs.first.team.name);
		};
	}
}