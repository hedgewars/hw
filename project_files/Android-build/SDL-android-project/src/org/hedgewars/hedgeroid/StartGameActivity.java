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
import org.hedgewars.hedgeroid.util.FileUtils;

import android.app.Activity;
import android.content.Intent;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
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
	private Spinner mapSpinner, styleSpinner, schemeSpinner, weaponsetSpinner, themeSpinner;
	private ImageView themeIcon, mapPreview, teamCount;

	private List<MapFile> mapFiles;
	private List<String> styles;
	private List<Scheme> schemes;
	private List<Weaponset> weaponsets;
	private List<String> themes;
	
	private List<TeamInGame> teams = new ArrayList<TeamInGame>();

	public void onCreate(Bundle savedInstanceState){
		super.onCreate(savedInstanceState);

		setContentView(R.layout.starting_game);

		back = (ImageButton) findViewById(R.id.btnBack);
		team = (ImageButton) findViewById(R.id.btnTeams);
		start = (ImageButton) findViewById(R.id.btnStart);

		themeIcon = (ImageView) findViewById(R.id.imgTheme);
		mapPreview = (ImageView) findViewById(R.id.mapPreview);
		teamCount = (ImageView) findViewById(R.id.imgTeamsCount);

		start.setOnClickListener(startClicker);
		back.setOnClickListener(backClicker);
		team.setOnClickListener(teamClicker);

		try {
			mapFiles = FrontendDataUtils.getMaps(this);
			styles = FrontendDataUtils.getGameStyles(this);
			schemes = Schemes.loadAllSchemes(this);
			weaponsets = Weaponsets.loadAllWeaponsets(this);
			themes = FrontendDataUtils.getThemes(this);
		} catch (IOException e) {
			Toast.makeText(getApplicationContext(), R.string.error_missing_sdcard_or_files, Toast.LENGTH_LONG).show();
			finish();
		}
		
		Collections.sort(mapFiles, MapFile.MISSIONS_FIRST_NAME_ORDER);
		Collections.sort(styles, String.CASE_INSENSITIVE_ORDER);
		Collections.sort(schemes, Scheme.NAME_ORDER);
		Collections.sort(weaponsets, Weaponset.NAME_ORDER);
		Collections.sort(themes, String.CASE_INSENSITIVE_ORDER);
		
		List<String> mapNames = MapFile.toDisplayNameList(mapFiles, getResources());
		List<String> schemeNames = Schemes.toNameList(schemes);
		List<String> weaponsetNames = Weaponsets.toNameList(weaponsets);
		View rootView = findViewById(android.R.id.content);
		mapSpinner = prepareSpinner(rootView, R.id.spinMaps, mapNames, mapsClicker);
		styleSpinner = prepareSpinner(rootView, R.id.spinGameplay, styles, null);
		schemeSpinner = prepareSpinner(rootView, R.id.spinGamescheme, schemeNames, null);
		weaponsetSpinner = prepareSpinner(rootView, R.id.spinweapons, weaponsetNames, null);
		themeSpinner = prepareSpinner(rootView, R.id.spinTheme, themes, themesClicker);
		
		// set map to first nonmission
		for(int i = 0; i < mapFiles.size(); i++){
			if(!mapFiles.get(i).isMission){
				mapSpinner.setSelection(i, false);
				break;
			}
		}
		styleSpinner.setSelection(styles.indexOf(GameConfig.DEFAULT_STYLE), false);
		schemeSpinner.setSelection(schemeNames.indexOf(GameConfig.DEFAULT_SCHEME), false);
		weaponsetSpinner.setSelection(weaponsetNames.indexOf(GameConfig.DEFAULT_WEAPONSET), false);
		themeSpinner.setSelection(themes.indexOf(GameConfig.DEFAULT_THEME), false);
	}

	private static Spinner prepareSpinner(View v, int id, List<String> items, OnItemSelectedListener itemSelectedListener) {
		Spinner spinner = (Spinner)v.findViewById(id);
		ArrayAdapter<String> adapter = new ArrayAdapter<String>(v.getContext(), R.layout.listview_item, items);
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		spinner.setAdapter(adapter);
		spinner.setOnItemSelectedListener(itemSelectedListener);
		return spinner;
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
			String themeName = themes.get(position);
			Drawable themeIconDrawable = Drawable.createFromPath(FileUtils.getDataPath(StartGameActivity.this) + "Themes/" + themeName + "/icon@2X.png");
			themeIcon.setImageDrawable(themeIconDrawable);
		}

		public void onNothingSelected(AdapterView<?> arg0) {
		}

	};

	private OnItemSelectedListener mapsClicker = new OnItemSelectedListener(){

		public void onItemSelected(AdapterView<?> arg0, View view, int position,long rowId) {
			MapFile map = mapFiles.get(position);
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
				String style = styles.get(styleSpinner.getSelectedItemPosition());
				Scheme scheme = schemes.get(schemeSpinner.getSelectedItemPosition());
				String mapName = mapFiles.get(mapSpinner.getSelectedItemPosition()).name;
				String theme = themes.get(themeSpinner.getSelectedItemPosition());
				MapRecipe map = MapRecipe.makeMap(mapName, UUID.randomUUID().toString(), theme);
				Weaponset weaponset = weaponsets.get(weaponsetSpinner.getSelectedItemPosition());
				SDLActivity.startConfig = new GameConfig(style, scheme, map, teams, weaponset);
				SDLActivity.startNetgame = false;
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
