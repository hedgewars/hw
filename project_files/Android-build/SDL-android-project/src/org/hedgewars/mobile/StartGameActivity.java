package org.hedgewars.mobile;

import android.app.Activity;
import android.content.SharedPreferences;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.view.View;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemSelectedListener;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.Spinner;

public class StartGameActivity extends Activity {

	private Spinner maps, gameplay, gamescheme, weapons, themes;
	private ImageView themeIcon;
	
	public void onCreate(Bundle savedInstanceState){
		super.onCreate(savedInstanceState);
		
		setContentView(R.layout.starting_game);

		maps = (Spinner) findViewById(R.id.spinMaps);
		gameplay = (Spinner) findViewById(R.id.spinGameplay);
		gamescheme = (Spinner) findViewById(R.id.spinGamescheme);
		weapons = (Spinner) findViewById(R.id.spinweapons);
		themes = (Spinner) findViewById(R.id.spinTheme);
		
		themeIcon = (ImageView) findViewById(R.id.imgTheme);
		
		ArrayAdapter<?> adapter = new ArrayAdapter<String>(this, android.R.layout.simple_spinner_item, FrontendDataUtil.getMaps(this));
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		maps.setAdapter(adapter);
		
		adapter = new ArrayAdapter<String>(this, R.layout.listview_item, FrontendDataUtil.getGameplay(this));
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		gameplay.setAdapter(adapter);

		adapter = new ArrayAdapter<Scheme>(this, R.layout.listview_item, FrontendDataUtil.getSchemes(this));
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		gamescheme.setAdapter(adapter);

		adapter = new ArrayAdapter<Weapon>(this, R.layout.listview_item, FrontendDataUtil.getWeapons(this));
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		weapons.setAdapter(adapter);
		
		adapter = new ArrayAdapter<String>(this, R.layout.listview_item, FrontendDataUtil.getThemes(this));
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		themes.setAdapter(adapter);
		
		
		themes.setOnItemSelectedListener(themesClicker);
		
		SharedPreferences sharedPref = PreferenceManager.getDefaultSharedPreferences(this);
		
		Utils.resRawToFilesDir(this,R.array.schemes, Scheme.DIRECTORY_SCHEME);
		Utils.resRawToFilesDir(this, R.array.weapons, Weapon.DIRECTORY_WEAPON);
	}
	
	private OnItemSelectedListener themesClicker = new OnItemSelectedListener(){

		public void onItemSelected(AdapterView<?> arg0, View view, int position, long rowId) {
			String themeName = (String) arg0.getAdapter().getItem(position);
			Drawable themeIconDrawable = Drawable.createFromPath(Utils.getDownloadPath(StartGameActivity.this) + "/Data/Themes/" + themeName + "/icon@2X.png");
			themeIcon.setImageDrawable(themeIconDrawable);
		}

		public void onNothingSelected(AdapterView<?> arg0) {
			// TODO Auto-generated method stub
			
		}
		
	};
	
}
