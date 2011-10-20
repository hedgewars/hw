/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011 Richard Deurwaarder <xeli@xelification.com>
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

import org.hedgewars.hedgeroid.EngineProtocol.FrontendDataUtils;
import org.hedgewars.hedgeroid.EngineProtocol.GameConfig;
import org.hedgewars.hedgeroid.EngineProtocol.Map;
import org.hedgewars.hedgeroid.EngineProtocol.Scheme;
import org.hedgewars.hedgeroid.EngineProtocol.Team;
import org.hedgewars.hedgeroid.EngineProtocol.Weapon;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.os.Parcelable;
import android.preference.PreferenceManager;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemSelectedListener;
import android.widget.ArrayAdapter;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.Spinner;
import android.widget.Toast;

public class StartGameActivity extends Activity {

	public static final int ACTIVITY_TEAM_SELECTOR = 0;

	private GameConfig config = null;
	private ImageButton start, back, team;
	private Spinner maps, gameplay, gamescheme, weapons, themes;
	private ImageView themeIcon, mapPreview, teamCount;

	public void onCreate(Bundle savedInstanceState){
		super.onCreate(savedInstanceState);

		SharedPreferences sharedPref = PreferenceManager.getDefaultSharedPreferences(this);
		boolean firstTime = sharedPref.getBoolean("firstTime", true);
		//Copy all the xml files to the device TODO only do first time launch of the app...
		if(firstTime){
			sharedPref.edit().putBoolean("firstTime", false).commit();
			
			Utils.resRawToFilesDir(this,R.array.schemes, Scheme.DIRECTORY_SCHEME);
			Utils.resRawToFilesDir(this, R.array.weapons, Weapon.DIRECTORY_WEAPON);
			Utils.resRawToFilesDir(this, R.array.teams, Team.DIRECTORY_TEAMS);
			Scheme.parseBasicFlags(this);
		}

		config = new GameConfig();

		setContentView(R.layout.starting_game);

		back = (ImageButton) findViewById(R.id.btnBack);
		team = (ImageButton) findViewById(R.id.btnTeams);
		start = (ImageButton) findViewById(R.id.btnStart);

		maps = (Spinner) findViewById(R.id.spinMaps);
		gameplay = (Spinner) findViewById(R.id.spinGameplay);
		gamescheme = (Spinner) findViewById(R.id.spinGamescheme);
		weapons = (Spinner) findViewById(R.id.spinweapons);
		themes = (Spinner) findViewById(R.id.spinTheme);

		themeIcon = (ImageView) findViewById(R.id.imgTheme);
		mapPreview = (ImageView) findViewById(R.id.mapPreview);
		teamCount = (ImageView) findViewById(R.id.imgTeamsCount);

		start.setOnClickListener(startClicker);
		back.setOnClickListener(backClicker);
		team.setOnClickListener(teamClicker);

		ArrayAdapter<?> adapter = new ArrayAdapter<Map>(this, R.layout.listview_item, FrontendDataUtils.getMaps(this));
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		maps.setAdapter(adapter);
		maps.setOnItemSelectedListener(mapsClicker);

		adapter = new ArrayAdapter<String>(this, R.layout.listview_item, FrontendDataUtils.getGameplay(this));
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		gameplay.setAdapter(adapter);
		gameplay.setOnItemSelectedListener(gameplayClicker);

		adapter = new ArrayAdapter<Scheme>(this, R.layout.listview_item, FrontendDataUtils.getSchemes(this));
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		gamescheme.setAdapter(adapter);
		gamescheme.setOnItemSelectedListener(schemeClicker);

		adapter = new ArrayAdapter<Weapon>(this, R.layout.listview_item, FrontendDataUtils.getWeapons(this));
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		weapons.setAdapter(adapter);
		weapons.setOnItemSelectedListener(weaponClicker);

		adapter = new ArrayAdapter<String>(this, R.layout.listview_item, FrontendDataUtils.getThemes(this));
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		themes.setAdapter(adapter);
		themes.setOnItemSelectedListener(themesClicker);

	}

	private void startTeamsActivity(){
		Intent i = new Intent(StartGameActivity.this, TeamSelectionActivity.class);
		i.putParcelableArrayListExtra("teams", config.teams);
		startActivityForResult(i, ACTIVITY_TEAM_SELECTOR);
	}

	public void onActivityResult(int requestCode, int resultCode, Intent data){
		switch(requestCode){
		case ACTIVITY_TEAM_SELECTOR:
			if(resultCode == Activity.RESULT_OK){
				Parcelable[] parcelables = (Parcelable[])data.getParcelableArrayExtra("teams");
				config.teams.clear();
				for(Parcelable t : parcelables){
					config.teams.add((Team)t);
				}
				teamCount.getDrawable().setLevel(config.teams.size());
			}
			break;
		}
	}


	private OnItemSelectedListener themesClicker = new OnItemSelectedListener(){

		public void onItemSelected(AdapterView<?> arg0, View view, int position, long rowId) {
			String themeName = (String) arg0.getAdapter().getItem(position);
			Drawable themeIconDrawable = Drawable.createFromPath(Utils.getDownloadPath(StartGameActivity.this) + "Themes/" + themeName + "/icon@2X.png");
			themeIcon.setImageDrawable(themeIconDrawable);
			config.theme = themeName;
		}

		public void onNothingSelected(AdapterView<?> arg0) {
		}

	};

	private OnItemSelectedListener mapsClicker = new OnItemSelectedListener(){

		public void onItemSelected(AdapterView<?> arg0, View view, int position,long rowId) {
			Map map = (Map)arg0.getAdapter().getItem(position);
			mapPreview.setImageDrawable(map.getDrawable());
			config.map = map;
		}

		public void onNothingSelected(AdapterView<?> arg0) {
		}

	};

	private OnItemSelectedListener weaponClicker = new OnItemSelectedListener(){
		public void onItemSelected(AdapterView<?> arg0, View arg1, int arg2, long arg3) {
			config.weapon = (Weapon)arg0.getAdapter().getItem(arg2);
		}
		public void onNothingSelected(AdapterView<?> arg0) {

		}
	};
	private OnItemSelectedListener schemeClicker = new OnItemSelectedListener(){
		public void onItemSelected(AdapterView<?> arg0, View arg1, int arg2, long arg3) {
			config.scheme = (Scheme)arg0.getAdapter().getItem(arg2);
		}
		public void onNothingSelected(AdapterView<?> arg0) {

		}
	};
	private OnItemSelectedListener gameplayClicker = new OnItemSelectedListener(){
		public void onItemSelected(AdapterView<?> arg0, View arg1, int arg2, long arg3) {
			//config = ()arg0.getAdapter().getItem(arg2);
		}
		public void onNothingSelected(AdapterView<?> arg0) {

		}
	};

	private OnClickListener startClicker = new OnClickListener(){
		public void onClick(View v) {
			if(config.teams.size() < 2){
				Toast.makeText(StartGameActivity.this, R.string.not_enough_teams, Toast.LENGTH_LONG).show();
				startTeamsActivity();
			}
			else{
				Intent i = new Intent(StartGameActivity.this, SDLActivity.class);
				i.putExtra("config", config);
				startActivity(i);}
		}
	};

	private OnClickListener backClicker = new OnClickListener(){
		public void onClick(View v) {
			finish();
		}
	};

	private OnClickListener teamClicker = new OnClickListener(){
		public void onClick(View v) {
			startTeamsActivity();
		}
	};

}
