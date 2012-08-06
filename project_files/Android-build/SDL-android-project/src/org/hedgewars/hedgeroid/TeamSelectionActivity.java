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

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import org.hedgewars.hedgeroid.Datastructures.FrontendDataUtils;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.TeamFile;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.Datastructures.TeamIngameAttributes;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Parcelable;
import android.util.Pair;
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
import android.widget.RelativeLayout;
import android.widget.SimpleAdapter;
import android.widget.SimpleAdapter.ViewBinder;
import android.widget.TextView;

public class TeamSelectionActivity extends Activity implements Runnable{
	private static final int ACTIVITY_TEAMCREATION = 0;
	
	private static volatile List<Pair<TeamFile, TeamIngameAttributes>> activityParams;
	private static volatile List<Pair<TeamFile, TeamIngameAttributes>> activityReturn;

	private ImageButton addTeam, back;
	private ListView availableTeams, selectedTeams;
	private List<HashMap<String, Object>> availableTeamsList, selectedTeamsList;
	private TextView txtInfo;

	public void onCreate(Bundle savedInstanceState){
		super.onCreate(savedInstanceState);

		setContentView(R.layout.team_selector);

		addTeam = (ImageButton) findViewById(R.id.btnAdd);
		back = (ImageButton) findViewById(R.id.btnBack);
		txtInfo = (TextView) findViewById(R.id.txtInfo);
		selectedTeams = (ListView) findViewById(R.id.selectedTeams);
		availableTeams = (ListView) findViewById(R.id.availableTeams);
		addTeam.setOnClickListener(addTeamClicker);
		back.setOnClickListener(backClicker);

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
		List<HashMap<String, Object>> teamsList = getTeams(this);//teams from xml
		ArrayList<String> teamsStartGame = getIntent().getStringArrayListExtra("selectedTeamNames");

		for(HashMap<String, Object> hashmap : teamsList){
			boolean added = false;
			for(String teamName : teamsStartGame){
				if(((Team)hashmap.get("team")).name.equals(teamName)){ // add to available or add to selected
					selectedTeamsList.add(hashmap);
					added = true;
					break;
				}
			}
			if(!added) availableTeamsList.add(hashmap);
		}

		this.runOnUiThread(new Runnable(){
			public void run() {
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
		unregisterForContextMenu(availableTeams);
		availableTeamsList = getTeams(this);
		ArrayList<HashMap<String, Object>> toBeRemoved = new ArrayList<HashMap<String, Object>>();
		for(HashMap<String, Object> hashmap : selectedTeamsList){
			String name = (String)hashmap.get("txt");

			for(HashMap<String, Object> hash : availableTeamsList){
				if(name.equals((String)hash.get("txt"))){
					toBeRemoved.add(hash);
				}
			}
		}
		for(HashMap<String, Object> hash: toBeRemoved) availableTeamsList.remove(hash);

		SimpleAdapter adapter = new SimpleAdapter(this, availableTeamsList, R.layout.team_selection_entry, new String[]{"txt", "img"}, new int[]{R.id.txtName, R.id.imgDifficulty});
		availableTeams.setAdapter(adapter);
		registerForContextMenu(availableTeams);
		availableTeams.setOnItemClickListener(availableClicker);


	}

	private void setTeamColor(int position, int color){
		View iv = ((RelativeLayout)selectedTeams.getChildAt(position)).findViewById(R.id.teamCount);
		setTeamColor(iv, color);
	}
	private void setTeamColor(View iv, int color){
		iv.setBackgroundColor(0xFF000000 + color);
	}

	private void setTeamHogCount(int position, int count){
		ImageView iv = (ImageView)((RelativeLayout)selectedTeams.getChildAt(position)).findViewById(R.id.teamCount);
		setTeamHogCount(iv, count);
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

	private OnClickListener backClicker = new OnClickListener(){
		public void onClick(View v){
			returnTeams();
			finish();
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
		TeamFile teamfile = (TeamFile)availableTeamsList.get(position).get("teamfile");
		switch(item.getItemId()){
		case 0://select
			selectAvailableTeamsItem(position);
			return true;
		case 1://delete
			teamfile.file.delete();
			availableTeamsList.remove(position);
			((SimpleAdapter)availableTeams.getAdapter()).notifyDataSetChanged();
			return true;
		case 2://edit
			Intent i = new Intent(TeamSelectionActivity.this, TeamCreatorActivity.class);
			i.putExtra("teamfile", teamfile.file);
			startActivityForResult(i, ACTIVITY_TEAMCREATION);
			return true;
		}
		return false;
	}

	private void selectAvailableTeamsItem(int position){
		HashMap<String, Object> hash = (HashMap<String, Object>) availableTeamsList.get(position);
		Team t = (Team)hash.get("team");
		int[] illegalcolors = new int[selectedTeamsList.size()];
		for(int i = 0; i < selectedTeamsList.size(); i++){
			illegalcolors[i] = ((Team)selectedTeamsList.get(i).get("team")).color;
		}
		t.setRandomColor(illegalcolors);
		hash.put("color", t.color);
		hash.put("count", t.hogCount);

		selectedTeamsList.add(hash);
		availableTeamsList.remove(position);
		((SimpleAdapter)availableTeams.getAdapter()).notifyDataSetChanged();
		((SimpleAdapter)selectedTeams.getAdapter()).notifyDataSetChanged();

		txtInfo.setText(String.format(getResources().getString(R.string.teams_info_template), selectedTeamsList.size()));
	}

	private void returnTeams(){
		int teamsCount = selectedTeamsList.size();
		Intent i = new Intent();
		Parcelable[] teams = new Parcelable[teamsCount];
		for(int x = 0 ; x < teamsCount; x++){
			teams[x] = (Team)selectedTeamsList.get(x).get("team");
		}
		i.putExtra("teams", teams);
		setResult(Activity.RESULT_OK, i);

	}
	
	private static List<HashMap<String, Object>> getTeams(Context c){
		List<HashMap<String, Object>> ret = new ArrayList<HashMap<String, Object>>();
		List<TeamFile> teamfiles = FrontendDataUtils.getTeamFiles(c);
		for(TeamFile tf : teamfiles) {
			ret.add(teamfileToMap(tf));
		}
		return ret;
	}
	
	private static final int[] botlevelDrawables = new int[] {
		R.drawable.human, R.drawable.bot5, R.drawable.bot4, R.drawable.bot3, R.drawable.bot2, R.drawable.bot1
	};
	
	private static HashMap<String, Object> teamfileToMap(TeamFile tf){
		HashMap<String, Object> hashmap = new HashMap<String, Object>();
		Team t = tf.team;
		hashmap.put("team", t);
		hashmap.put("teamfile", tf);
		hashmap.put("txt", t.name);
		hashmap.put("color", t.color);
		hashmap.put("count", t.hogCount);
		
		int botlevel = t.hogs.get(0).level;
		if(botlevel<0 || botlevel>=botlevelDrawables.length) {
			hashmap.put("img", R.drawable.bot1);
		} else {
			hashmap.put("img", botlevelDrawables[botlevel]);
		}
		return hashmap;
		return null;
	}
}
