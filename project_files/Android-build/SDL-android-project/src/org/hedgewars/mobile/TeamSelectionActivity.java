package org.hedgewars.mobile;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;

import org.hedgewars.mobile.EngineProtocol.FrontendDataUtils;
import org.hedgewars.mobile.EngineProtocol.Team;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.os.Parcelable;
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

public class TeamSelectionActivity extends Activity{

	private ImageButton addTeam, back;
	private ListView availableTeams, selectedTeams;
	private ArrayList<HashMap<String, ?>> availableTeamsList, selectedTeamsList;
	private int minTeams = 2;

	public void onCreate(Bundle savedInstanceState){
		super.onCreate(savedInstanceState);

		setContentView(R.layout.team_selector);

		addTeam = (ImageButton) findViewById(R.id.btnAdd);
		back = (ImageButton) findViewById(R.id.btnBack);

		addTeam.setOnClickListener(addTeamClicker);
		back.setOnClickListener(backClicker);

		availableTeams = (ListView) findViewById(R.id.availableTeams);
		availableTeamsList = FrontendDataUtils.getTeams(this);
		SimpleAdapter adapter = new SimpleAdapter(this, availableTeamsList, R.layout.team_selection_entry, new String[]{"txt", "img"}, new int[]{R.id.txtName, R.id.imgDifficulty});
		availableTeams.setAdapter(adapter);
		registerForContextMenu(availableTeams);
		availableTeams.setOnItemClickListener(availableClicker);

		selectedTeams = (ListView) findViewById(R.id.selectedTeams);
		selectedTeamsList = new ArrayList<HashMap<String, ?>>();
		ArrayList<HashMap<String, ?>> toBeRemoved = new ArrayList<HashMap<String, ?>>();
		ArrayList<Team> teamsStartGame = getIntent().getParcelableArrayListExtra("teams");
		for(HashMap<String, ?> hashmap : availableTeamsList){
			for(Team t : teamsStartGame){
				if(((Team)hashmap.get("team")).equals(t)){
					toBeRemoved.add(hashmap);
					selectedTeamsList.add(hashmap);
				}
			}
		}
		for(HashMap<String, ?> hashmap : toBeRemoved) availableTeamsList.remove(hashmap);

		adapter = new SimpleAdapter(this, selectedTeamsList, R.layout.team_selection_entry, new String[]{"txt", "img", "color", "count"}, new int[]{R.id.txtName, R.id.imgDifficulty, R.id.teamColor, R.id.teamCount});
		adapter.setViewBinder(viewBinder);
		selectedTeams.setAdapter(adapter);
		selectedTeams.setOnItemClickListener(selectedClicker);

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

	private void setTeamColor(int position, int color){
		View iv = ((RelativeLayout)selectedTeams.getChildAt(position)).findViewById(R.id.teamCount);
		setTeamColor(iv, color);
	}
	private void setTeamColor(View iv, int color){
		iv.setBackgroundColor(color);
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
			startActivity(new Intent(TeamSelectionActivity.this, TeamCreatorActivity.class));

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
			availableTeamsList.add((HashMap<String, ?>) selectedTeamsList.get(position));
			selectedTeamsList.remove(position);
			((SimpleAdapter)availableTeams.getAdapter()).notifyDataSetChanged();
			((SimpleAdapter)selectedTeams.getAdapter()).notifyDataSetChanged();
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
		switch(item.getItemId()){
		case 0://select
			selectAvailableTeamsItem(position);
			return true;
		case 1://delete
			availableTeamsList.remove(position);
			((SimpleAdapter)availableTeams.getAdapter()).notifyDataSetChanged();
			File f = new File(String.format("%s/%s/%s.xml", TeamSelectionActivity.this.getFilesDir(), Team.DIRECTORY_TEAMS, availableTeamsList.get(position).get("txt")));
			f.delete();
			return true;
		case 2://edit
			Intent i = new Intent(TeamSelectionActivity.this, TeamCreatorActivity.class);
			Team t = (Team)availableTeamsList.get(position).get("team");
			i.putExtra("team", t);
			startActivity(i);
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
	}

	private void returnTeams(){
		int teamsCount = selectedTeamsList.size();
		if(teamsCount >= minTeams){
			Intent i = new Intent();
			Parcelable[] teams = new Parcelable[teamsCount];
			for(int x = 0 ; x < teamsCount; x++){
				teams[x] = (Team)selectedTeamsList.get(x).get("team");
			}
			i.putExtra("teams", teams);
			setResult(Activity.RESULT_OK, i);
		}else{
			setResult(Activity.RESULT_CANCELED);
		}
	}
}
