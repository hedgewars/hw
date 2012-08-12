/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011-2012 Richard Deurwaarder <xeli@xelification.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */


package org.hedgewars.hedgeroid;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import org.hedgewars.hedgeroid.Datastructures.FrontendDataUtils;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.Datastructures.TeamIngameAttributes;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.ContextMenu;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.AdapterView;
import android.widget.AdapterView.AdapterContextMenuInfo;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.SimpleAdapter;
import android.widget.SimpleAdapter.ViewBinder;
import android.widget.TextView;

public class TeamSelectionActivity extends Activity implements Runnable{
	private static final int ACTIVITY_TEAMCREATION = 0;
	
	public static volatile List<TeamInGame> activityParams;
	public static volatile List<TeamInGame> activityReturn;

	private ImageButton addTeam;
	private ListView availableTeams, selectedTeams;
	private List<HashMap<String, Object>> availableTeamsList, selectedTeamsList;
	private TextView txtInfo;

	public void onCreate(Bundle savedInstanceState){
		super.onCreate(savedInstanceState);

		setContentView(R.layout.team_selector);

		addTeam = (ImageButton) findViewById(R.id.btnAdd);
		txtInfo = (TextView) findViewById(R.id.txtInfo);
		selectedTeams = (ListView) findViewById(R.id.selectedTeams);
		availableTeams = (ListView) findViewById(R.id.availableTeams);
		addTeam.setOnClickListener(addTeamClicker);

		availableTeamsList = new ArrayList<HashMap<String, Object>>();
		SimpleAdapter adapter = new SimpleAdapter(this, availableTeamsList, R.layout.team_selection_entry_simple, new String[]{"txt", "img"}, new int[]{R.id.txtName, R.id.imgDifficulty});
		availableTeams.setAdapter(adapter);
		availableTeams.setOnItemClickListener(availableClicker);
		registerForContextMenu(availableTeams);

		selectedTeamsList = new ArrayList<HashMap<String, Object>>();
		adapter = new SimpleAdapter(this, selectedTeamsList, R.layout.team_selection_entry, new String[]{"txt", "img", "color", "count"}, new int[]{R.id.txtName, R.id.imgDifficulty, R.id.teamColor, R.id.teamCount});
		adapter.setViewBinder(viewBinder);
		selectedTeams.setAdapter(adapter);
		selectedTeams.setOnItemClickListener(selectedClicker);

		txtInfo.setText(String.format(getResources().getString(R.string.teams_info_template), selectedTeams.getChildCount()));

		new Thread(this).start();//load the teams from xml async
	}

	public void run(){
		List<Team> teams = FrontendDataUtils.getTeams(this);
		List<TeamInGame> existingTeams = activityParams;
		final List<TeamInGame> newSelectedList = new ArrayList<TeamInGame>();
		final List<Team> newAvailableList = new ArrayList<Team>();
		
		for(Team team : teams){
			boolean added = false;
			for(TeamInGame existingTeam : existingTeams){
				if(team.name.equals(existingTeam.team.name)){ // add to available or add to selected
					newSelectedList.add(new TeamInGame(team, existingTeam.ingameAttribs));
					added = true;
					break;
				}
			}
			if(!added) newAvailableList.add(team);
		}

		this.runOnUiThread(new Runnable(){
			public void run() {
				availableTeamsList.clear();
				selectedTeamsList.clear();
				for(TeamInGame t : newSelectedList) {
					selectedTeamsList.add(toMap(t));
				}
				for(Team t : newAvailableList) {
					availableTeamsList.add(toMap(t));
				}
				((SimpleAdapter)selectedTeams.getAdapter()).notifyDataSetChanged();
				((SimpleAdapter)availableTeams.getAdapter()).notifyDataSetChanged();		
			}
		});
	}

	private ViewBinder viewBinder = new ViewBinder(){
		public boolean setViewValue(View view, Object data,	String textRepresentation) {
			switch(view.getId()){
			case R.id.teamColor:
				setTeamColor(view, (Integer)data);
				return true;
			case R.id.teamCount:
				setTeamHogCount((ImageView)view, (Integer)data);
				return true;
			default:
				return false;
			}
		}
	};

	public void onActivityResult(int requestCode, int resultCode, Intent data){
		if(requestCode == ACTIVITY_TEAMCREATION){
			if(resultCode == Activity.RESULT_OK){
				updateListViews();
			}
		}else{
			super.onActivityResult(requestCode, resultCode, data);
		}
	}

	/*
	 * Updates the list view when TeamCreationActivity is shutdown and the user returns to this point
	 */
	private void updateListViews(){
		List<Team> teams = FrontendDataUtils.getTeams(this);
		availableTeamsList.clear();
		for(Team team : teams) {
			availableTeamsList.add(toMap(team));
		}
		
		ArrayList<HashMap<String, Object>> toBeRemoved = new ArrayList<HashMap<String, Object>>();
		ArrayList<HashMap<String, Object>> toBeRemovedFromSelected = new ArrayList<HashMap<String, Object>>();
		for(HashMap<String, Object> hashmap : selectedTeamsList){
			String name = (String)hashmap.get("txt");
			boolean exists = false;
			for(HashMap<String, Object> hash : availableTeamsList){
				if(name.equals((String)hash.get("txt"))){
					toBeRemoved.add(hash);
					exists = true;
					break;
				}
			}
			if(!exists) {
				toBeRemovedFromSelected.add(hashmap);
			}
		}
		for(HashMap<String, Object> hash: toBeRemoved) availableTeamsList.remove(hash);
		for(HashMap<String, Object> hash: toBeRemovedFromSelected) selectedTeamsList.remove(hash);
		((SimpleAdapter)selectedTeams.getAdapter()).notifyDataSetChanged();
		((SimpleAdapter)availableTeams.getAdapter()).notifyDataSetChanged();
	}

	private void setTeamColor(View iv, int colorIndex){
		iv.setBackgroundColor(0xFF000000 + TeamIngameAttributes.TEAM_COLORS[colorIndex]);
	}

	private void setTeamHogCount(ImageView iv, int count){

		switch(count){
		case 0:
			iv.setImageResource(R.drawable.teamcount0);
			break;
		case 1:
			iv.setImageResource(R.drawable.teamcount1);
			break;
		case 2:
			iv.setImageResource(R.drawable.teamcount2);
			break;
		case 3:
			iv.setImageResource(R.drawable.teamcount3);
			break;
		case 4:
			iv.setImageResource(R.drawable.teamcount4);
			break;
		case 5:
			iv.setImageResource(R.drawable.teamcount5);
			break;
		case 6:
			iv.setImageResource(R.drawable.teamcount6);
			break;
		case 7:
			iv.setImageResource(R.drawable.teamcount7);
			break;
		case 8:
			iv.setImageResource(R.drawable.teamcount8);
			break;
		case 9:
			iv.setImageResource(R.drawable.teamcount9);
			break;
		}
	}

	public void onBackPressed(){
		returnTeams();
		super.onBackPressed();
	}

	private OnClickListener addTeamClicker = new OnClickListener(){
		public void onClick(View v) {
			startActivityForResult(new Intent(TeamSelectionActivity.this, TeamCreatorActivity.class), ACTIVITY_TEAMCREATION);
		}
	};

	private OnItemClickListener availableClicker = new OnItemClickListener(){
		public void onItemClick(AdapterView<?> arg0, View arg1, int position,long arg3) {
			selectAvailableTeamsItem(position);
		}
	};
	private OnItemClickListener selectedClicker = new OnItemClickListener(){
		public void onItemClick(AdapterView<?> arg0, View arg1, int position,long arg3) {
			availableTeamsList.add((HashMap<String, Object>) selectedTeamsList.get(position));
			selectedTeamsList.remove(position);
			((SimpleAdapter)availableTeams.getAdapter()).notifyDataSetChanged();
			((SimpleAdapter)selectedTeams.getAdapter()).notifyDataSetChanged();

			txtInfo.setText(String.format(getResources().getString(R.string.teams_info_template), selectedTeamsList.size()));
		}

	};

	public void onCreateContextMenu(ContextMenu menu, View v, ContextMenu.ContextMenuInfo menuinfo){
		menu.add(ContextMenu.NONE, 0, ContextMenu.NONE, R.string.select);
		menu.add(ContextMenu.NONE, 2, ContextMenu.NONE, R.string.edit);
		menu.add(ContextMenu.NONE, 1, ContextMenu.NONE, R.string.delete);

	}
	public boolean onContextItemSelected(MenuItem item){
		AdapterView.AdapterContextMenuInfo menuInfo = (AdapterContextMenuInfo) item.getMenuInfo();
		int position = menuInfo.position;
		Team team = (Team)availableTeamsList.get(position).get("team");
		switch(item.getItemId()){
		case 0://select
			selectAvailableTeamsItem(position);
			return true;
		case 1://delete
			Team.getTeamfileByName(getApplicationContext(), team.name).delete();
			availableTeamsList.remove(position);
			((SimpleAdapter)availableTeams.getAdapter()).notifyDataSetChanged();
			return true;
		case 2://edit
			Intent i = new Intent(TeamSelectionActivity.this, TeamCreatorActivity.class);
			i.putExtra(TeamCreatorActivity.PARAMETER_EXISTING_TEAMNAME, team.name);
			startActivityForResult(i, ACTIVITY_TEAMCREATION);
			return true;
		}
		return false;
	}

	private void selectAvailableTeamsItem(int position){
		HashMap<String, Object> hash = (HashMap<String, Object>) availableTeamsList.get(position);
		int[] illegalcolors = new int[selectedTeamsList.size()];
		for(int i = 0; i < selectedTeamsList.size(); i++){
			illegalcolors[i] = (Integer)selectedTeamsList.get(i).get("color");
		}
		hash.put("color", TeamIngameAttributes.randomColorIndex(illegalcolors));
		hash.put("count", TeamIngameAttributes.DEFAULT_HOG_COUNT);

		selectedTeamsList.add(hash);
		availableTeamsList.remove(position);
		((SimpleAdapter)availableTeams.getAdapter()).notifyDataSetChanged();
		((SimpleAdapter)selectedTeams.getAdapter()).notifyDataSetChanged();

		txtInfo.setText(String.format(getResources().getString(R.string.teams_info_template), selectedTeamsList.size()));
	}

	private void returnTeams() {
		List<TeamInGame> result = new ArrayList<TeamInGame>();
		for(HashMap<String, Object> item : selectedTeamsList) {
			result.add(new TeamInGame((Team)item.get("team"), new TeamIngameAttributes("Player", (Integer)item.get("color"), (Integer)item.get("count"), false)));
		}
		activityReturn = result;
		setResult(Activity.RESULT_OK);
	}
	
	private static final int[] botlevelDrawables = new int[] {
		R.drawable.human, R.drawable.bot5, R.drawable.bot4, R.drawable.bot3, R.drawable.bot2, R.drawable.bot1
	};
		
	private static HashMap<String, Object> toMap(Team t) {
		HashMap<String, Object> map = new HashMap<String, Object>();
		map.put("team", t);
		map.put("txt", t.name);
		int botlevel = t.hogs.get(0).level;
		if(botlevel<0 || botlevel>=botlevelDrawables.length) {
			map.put("img", R.drawable.bot1);
		} else {
			map.put("img", botlevelDrawables[botlevel]);
		}	
		return map;
	}
	
	private static HashMap<String, Object> toMap(TeamInGame t) {
		HashMap<String, Object> map = toMap(t.team);
		map.put("color", t.ingameAttribs.colorIndex);
		map.put("count", t.ingameAttribs.hogCount);
		return map;
	}
}
