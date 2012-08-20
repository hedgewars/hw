package org.hedgewars.hedgeroid;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.Datastructures.TeamIngameAttributes;

import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ImageButton;
import android.widget.TextView;

public class TeamlistAdapter extends BaseAdapter {
	private boolean colorHogcountEnabled = false;
	private Listener listener;
	private List<TeamInGame> teams = new ArrayList<TeamInGame>();
	
	public void setColorHogcountEnabled(boolean colorHogcountEnabled) {
		this.colorHogcountEnabled = colorHogcountEnabled;
		notifyDataSetChanged();
	}
	
	public void setListener(Listener listener) {
		this.listener = listener;
	}
	
	public int getCount() {
		return teams.size();
	}
	
	public TeamInGame getItem(int position) {
		return teams.get(position);
	}
	
	public long getItemId(int position) {
		return position;
	}
	
	@Override
	public boolean hasStableIds() {
		return false;
	}
	
	public void updateTeamlist(Collection<TeamInGame> newTeams) {
		teams.clear();
		teams.addAll(newTeams);
		Collections.sort(teams, TeamInGame.NAME_ORDER);
		notifyDataSetChanged();
	}
	
	public View getView(int position, View convertView, ViewGroup parent) {
		View v = convertView;
		if (v == null) {
			LayoutInflater vi = LayoutInflater.from(parent.getContext());
			v = vi.inflate(R.layout.listview_team, null);
		}

		TeamInGame team = getItem(position);
		TextView teamNameView = (TextView) v.findViewById(android.R.id.text1);
		ImageButton colorButton = (ImageButton) v.findViewById(R.id.colorButton);
		ImageButton hogCountButton = (ImageButton) v.findViewById(R.id.hogCountButton);
		
		teamNameView.setText(team.team.name);
		int teamImage;
		if(team.ingameAttribs.remoteDriven) {
			teamImage = R.drawable.team_net_by_level;
		} else {
			teamImage = R.drawable.team_local_by_level;
		}
		
		Drawable d = parent.getContext().getResources().getDrawable(teamImage).mutate();
		d.setLevel(team.team.hogs.get(0).level);
		teamNameView.setCompoundDrawablesWithIntrinsicBounds(d, null, null, null);
		hogCountButton.getDrawable().setLevel(team.ingameAttribs.hogCount);
		colorButton.setImageDrawable(new ColorDrawable(TeamIngameAttributes.TEAM_COLORS[team.ingameAttribs.colorIndex]));
		
		colorButton.setEnabled(colorHogcountEnabled);
		hogCountButton.setEnabled(colorHogcountEnabled);
		
		colorButton.setOnClickListener(new ButtonClickListener(team, Type.COLOR_BUTTON));
		hogCountButton.setOnClickListener(new ButtonClickListener(team, Type.HOGCOUNT_BUTTON));
		
		if(team.ingameAttribs.remoteDriven) {
			teamNameView.setClickable(false);
		} else {
			teamNameView.setOnClickListener(new ButtonClickListener(team, Type.TEAM_VIEW));
		}
		
		return v;
	}
	
	private static enum Type {COLOR_BUTTON, HOGCOUNT_BUTTON, TEAM_VIEW}
	private final class ButtonClickListener implements OnClickListener {
		private final TeamInGame team;
		private final Type type;
		
		public ButtonClickListener(TeamInGame team, Type type) {
			this.team = team;
			this.type = type;
		}
		
		public void onClick(View v) {
			if(listener != null) {
				switch(type) {
				case COLOR_BUTTON:
					listener.onColorClicked(team);
					break;
				case HOGCOUNT_BUTTON:
					listener.onHogcountClicked(team);
					break;
				case TEAM_VIEW:
					listener.onTeamClicked(team);
					break;
				default:
					throw new IllegalStateException();	
				}
			}
		}
	}
	
	public interface Listener {
		void onTeamClicked(TeamInGame team);
		void onColorClicked(TeamInGame team);
		void onHogcountClicked(TeamInGame team);
	}
}