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
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import org.hedgewars.hedgeroid.Datastructures.FrontendDataUtils;
import org.hedgewars.hedgeroid.Datastructures.GameConfig;
import org.hedgewars.hedgeroid.Datastructures.MapFile;
import org.hedgewars.hedgeroid.Datastructures.MapRecipe;
import org.hedgewars.hedgeroid.Datastructures.Scheme;
import org.hedgewars.hedgeroid.Datastructures.Schemes;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.Datastructures.Weaponset;
import org.hedgewars.hedgeroid.Datastructures.Weaponsets;

import android.app.Activity;
import android.content.Intent;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.util.Log;
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
	
	private ImageButton start, back, team;
	private Spinner maps, gameplay, gamescheme, weapons, themes;
	private ImageView themeIcon, mapPreview, teamCount;
	
	private List<TeamInGame> teams = new ArrayList<TeamInGame>();

	public void onCreate(Bundle savedInstanceState){
		super.onCreate(savedInstanceState);

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

		List<MapFile> mapFiles;
		try {
			mapFiles = FrontendDataUtils.getMaps(this);
		} catch (FileNotFoundException e) {
			Log.e("StartGameActivity", e.getMessage(), e);
			mapFiles = Collections.emptyList();
		}
		ArrayAdapter<?> adapter = new ArrayAdapter<MapFile>(this, R.layout.listview_item, mapFiles);
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		maps.setAdapter(adapter);
		maps.setOnItemSelectedListener(mapsClicker);
		//set to first nonmission
		for(int i = 0; i < adapter.getCount(); i++){
			if(!((MapFile)adapter.getItem(i)).isMission){
				maps.setSelection(i, false);
				break;
			}
		}

		List<String> gameStyles;
		try {
			gameStyles = FrontendDataUtils.getGameStyles(this);
		} catch (FileNotFoundException e) {
			Log.e("StartGameActivity", e.getMessage(), e);
			gameStyles = Collections.emptyList();
		}
		adapter = new ArrayAdapter<String>(this, R.layout.listview_item, gameStyles);
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		gameplay.setAdapter(adapter);
		//set to first nonmap
		for(int i = 0; i < adapter.getCount(); i++){
			if(((String)adapter.getItem(i)).equals("None")){
				gameplay.setSelection(i, false);
				break;
			}
		}

		List<Scheme> schemes;
		try {
			schemes = new ArrayList<Scheme>(Schemes.loadAllSchemes(this).values());
		} catch (IOException e) {
			Log.e("StartGameActivity", e.getMessage(), e);
			schemes = Collections.emptyList();
		} 
		adapter = new ArrayAdapter<Scheme>(this, R.layout.listview_item, schemes);
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		gamescheme.setAdapter(adapter);
		for(int i = 0; i < adapter.getCount(); i++){
			if(((Scheme)adapter.getItem(i)).name.equals("Default")){
				gamescheme.setSelection(i, false);
				break;
			}
		}
		
		List<Weaponset> weaponsets;
		try {
			weaponsets = Weaponsets.loadAllWeaponsets(this);
		} catch(IOException e) {
			Log.e("StartGameActivity", e.getMessage(), e);
			weaponsets = Collections.emptyList();
		}
		adapter = new ArrayAdapter<Weaponset>(this, R.layout.listview_item, weaponsets);
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		weapons.setAdapter(adapter);
		for(int i = 0; i < adapter.getCount(); i++){
			if(((Weaponset)adapter.getItem(i)).name.equals("Crazy")){
				weapons.setSelection(i, false);
				break;
			}
		}
		
		List<String> themeList;
		try {
			themeList = FrontendDataUtils.getThemes(this);
		} catch(FileNotFoundException e) {
			Log.e("StartGameActivity", e.getMessage(), e);
			themeList = Collections.emptyList();
		}
		adapter = new ArrayAdapter<String>(this, R.layout.listview_item, themeList);
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		themes.setAdapter(adapter);
		themes.setOnItemSelectedListener(themesClicker);
	}

	private void startTeamsActivity(){
		Intent i = new Intent(StartGameActivity.this, TeamSelectionActivity.class);
		TeamSelectionActivity.activityParams = new ArrayList<TeamInGame>(teams);
		startActivityForResult(i, ACTIVITY_TEAM_SELECTOR);
	}

	public void onActivityResult(int requestCode, int resultCode, Intent data){
		switch(requestCode){
		case ACTIVITY_TEAM_SELECTOR:
			if(resultCode == Activity.RESULT_OK){
				teams = new ArrayList<TeamInGame>(TeamSelectionActivity.activityReturn);
				TeamSelectionActivity.activityReturn = Collections.emptyList();
				teamCount.getDrawable().setLevel(teams.size());
			}
			break;
		}
	}


	private OnItemSelectedListener themesClicker = new OnItemSelectedListener(){

		public void onItemSelected(AdapterView<?> arg0, View view, int position, long rowId) {
			String themeName = (String) arg0.getAdapter().getItem(position);
			Drawable themeIconDrawable = Drawable.createFromPath(Utils.getDataPath(StartGameActivity.this) + "Themes/" + themeName + "/icon@2X.png");
			themeIcon.setImageDrawable(themeIconDrawable);
		}

		public void onNothingSelected(AdapterView<?> arg0) {
		}

	};

	private OnItemSelectedListener mapsClicker = new OnItemSelectedListener(){

		public void onItemSelected(AdapterView<?> arg0, View view, int position,long rowId) {
			MapFile map = (MapFile)arg0.getAdapter().getItem(position);
			try {
				File previewFile = map.getPreviewFile(getApplicationContext());
				mapPreview.setImageDrawable(Drawable.createFromPath(previewFile.getAbsolutePath()));
			} catch (FileNotFoundException e) {
				mapPreview.setImageDrawable(null);
			}
		}

		public void onNothingSelected(AdapterView<?> arg0) {
		}

	};

	private OnClickListener startClicker = new OnClickListener(){
		public void onClick(View v) {
			if(teams.size() < 2) {
				Toast.makeText(getApplicationContext(), R.string.not_enough_teams, Toast.LENGTH_LONG).show();
				startTeamsActivity();
			} else {
				String style = (String)gameplay.getSelectedItem();
				Scheme scheme = (Scheme)gamescheme.getSelectedItem();
				String mapName = ((MapFile)maps.getSelectedItem()).name;
				String theme = (String)themes.getSelectedItem();
				MapRecipe map = MapRecipe.makeMap(mapName, UUID.randomUUID().toString(), theme);
				Weaponset weaponset = (Weaponset)weapons.getSelectedItem();
				SDLActivity.startConfig = new GameConfig(style, scheme, map, teams, weaponset);
				Intent i = new Intent(StartGameActivity.this, SDLActivity.class);
				startActivity(i);
			}
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
