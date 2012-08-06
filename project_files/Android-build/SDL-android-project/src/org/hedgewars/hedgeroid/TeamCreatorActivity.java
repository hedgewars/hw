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
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.hedgewars.hedgeroid.Datastructures.FrontendDataUtils;
import org.hedgewars.hedgeroid.Datastructures.Hog;
import org.hedgewars.hedgeroid.Datastructures.Team;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.media.MediaPlayer;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.View.OnFocusChangeListener;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemSelectedListener;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.ScrollView;
import android.widget.SimpleAdapter;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

public class TeamCreatorActivity extends Activity implements Runnable{

	private TextView name;
	private Spinner difficulty, grave, flag, voice, fort;
	private ImageView imgFort;
	private ArrayList<ImageButton> hogDice = new ArrayList<ImageButton>();
	private ArrayList<Spinner> hogHat = new ArrayList<Spinner>();
	private ArrayList<EditText> hogName = new ArrayList<EditText>();
	private ImageButton back, save, voiceButton;
	private ScrollView scroller;
	private MediaPlayer mp = null;
	private boolean settingsChanged = false;
	private boolean saved = false;
	private String fileName = null;

	private final List<HashMap<String, ?>> flagsData = new ArrayList<HashMap<String, ?>>();
	private final List<HashMap<String, ?>> typesData = new ArrayList<HashMap<String, ?>>();
	private final List<HashMap<String, ?>> gravesData = new ArrayList<HashMap<String, ?>>();
	private final List<HashMap<String, ?>> hatsData = new ArrayList<HashMap<String, ?>>();
	private final List<String> voicesData = new ArrayList<String>();
	private final List<String> fortsData = new ArrayList<String>();

	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.team_creation);

		name = (TextView) findViewById(R.id.txtName);
		difficulty = (Spinner) findViewById(R.id.spinType);
		grave = (Spinner) findViewById(R.id.spinGrave);
		flag = (Spinner) findViewById(R.id.spinFlag);
		voice = (Spinner) findViewById(R.id.spinVoice);
		fort = (Spinner) findViewById(R.id.spinFort);

		imgFort = (ImageView) findViewById(R.id.imgFort);

		back = (ImageButton) findViewById(R.id.btnBack);
		save = (ImageButton) findViewById(R.id.btnSave);
		voiceButton = (ImageButton) findViewById(R.id.btnPlay);

		scroller = (ScrollView) findViewById(R.id.scroller);

		save.setOnClickListener(saveClicker);
		back.setOnClickListener(backClicker);

		LinearLayout ll = (LinearLayout) findViewById(R.id.HogsContainer);
		for (int i = 0; i < ll.getChildCount(); i++) {
			RelativeLayout team_creation_entry = (RelativeLayout) ll.getChildAt(i);

			hogHat.add((Spinner) team_creation_entry
					.findViewById(R.id.spinTeam1));
			hogDice.add((ImageButton) team_creation_entry
					.findViewById(R.id.btnTeam1));
			hogName.add((EditText) team_creation_entry
					.findViewById(R.id.txtTeam1));
		}

		SimpleAdapter sa = new SimpleAdapter(this, gravesData,
				R.layout.spinner_textimg_entry, new String[] { "txt", "img" },
				new int[] { R.id.spinner_txt, R.id.spinner_img });
		sa.setDropDownViewResource(R.layout.spinner_textimg_dropdown_entry);
		sa.setViewBinder(viewBinder);
		grave.setAdapter(sa);
		grave.setOnFocusChangeListener(focusser);

		sa = new SimpleAdapter(this, flagsData, R.layout.spinner_textimg_entry,
				new String[] { "txt", "img" }, new int[] { R.id.spinner_txt,
				R.id.spinner_img });
		sa.setDropDownViewResource(R.layout.spinner_textimg_dropdown_entry);
		sa.setViewBinder(viewBinder);
		flag.setAdapter(sa);
		flag.setOnFocusChangeListener(focusser);

		sa = new SimpleAdapter(this, typesData, R.layout.spinner_textimg_entry,
				new String[] { "txt", "img" }, new int[] { R.id.spinner_txt,
				R.id.spinner_img });
		sa.setDropDownViewResource(R.layout.spinner_textimg_dropdown_entry);
		difficulty.setAdapter(sa);
		difficulty.setOnFocusChangeListener(focusser);

		sa = new SimpleAdapter(this, hatsData, R.layout.spinner_textimg_entry,
				new String[] { "txt", "img" }, new int[] { R.id.spinner_txt,
				R.id.spinner_img });
		sa.setDropDownViewResource(R.layout.spinner_textimg_dropdown_entry);
		sa.setViewBinder(viewBinder);
		for (Spinner spin : hogHat) {
			spin.setAdapter(sa);
		}

		ArrayAdapter<String> adapter = new ArrayAdapter<String>(this, R.layout.listview_item, voicesData);
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		voice.setAdapter(adapter);
		voice.setOnFocusChangeListener(focusser);
		voiceButton.setOnClickListener(voiceClicker);

		adapter = new ArrayAdapter<String>(this, R.layout.listview_item, fortsData);
		adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
		fort.setAdapter(adapter);
		fort.setOnItemSelectedListener(fortSelector);
		fort.setOnFocusChangeListener(focusser);

		new Thread(this).start();
	}

	public void run(){
		final ArrayList<HashMap<String, ?>> gravesDataNew = FrontendDataUtils.getGraves(this);
		this.runOnUiThread(new Runnable(){
			public void run() {
				copy(gravesData, gravesDataNew);
				((SimpleAdapter)grave.getAdapter()).notifyDataSetChanged();
			}
		});
		
		final ArrayList<HashMap<String, ?>> flagsDataNew = FrontendDataUtils.getFlags(this);
		this.runOnUiThread(new Runnable(){
			public void run() {
				copy(flagsData, flagsDataNew);
				((SimpleAdapter)flag.getAdapter()).notifyDataSetChanged();
			}
		});
		
		final ArrayList<HashMap<String, ?>> typesDataNew = FrontendDataUtils.getTypes(this);
		this.runOnUiThread(new Runnable(){
			public void run() {
				copy(typesData, typesDataNew);
				((SimpleAdapter)difficulty.getAdapter()).notifyDataSetChanged();
			}
		});
		
		final ArrayList<HashMap<String, ?>> hatsDataNew = FrontendDataUtils.getHats(this);
		this.runOnUiThread(new Runnable(){
			public void run() {
				copy(hatsData, hatsDataNew);
				((SimpleAdapter)hogHat.get(0).getAdapter()).notifyDataSetChanged();
			}
		});
		
		final ArrayList<String> voicesDataNew = FrontendDataUtils.getVoices(this);
		this.runOnUiThread(new Runnable(){
			public void run() {
				copy(voicesData, voicesDataNew);
				((ArrayAdapter<String>)voice.getAdapter()).notifyDataSetChanged();
			}
		});
		
		final ArrayList<String> fortsDataNew = FrontendDataUtils.getForts(this);
		this.runOnUiThread(new Runnable(){
			public void run() {
				copy(fortsData, fortsDataNew);
				((ArrayAdapter<String>)fort.getAdapter()).notifyDataSetChanged();
			}
		});
	}
	
	private static <T> void copy(List<T> dest, List<T> src){
		for(T t: src) dest.add(t);
	}

	public void onDestroy() {
		super.onDestroy();
		if (mp != null) {
			mp.release();
			mp = null;
		}
	}

	private OnFocusChangeListener focusser = new OnFocusChangeListener() {
		public void onFocusChange(View v, boolean hasFocus) {
			settingsChanged = true;
		}

	};

	public void onBackPressed() {
		onFinishing();
		super.onBackPressed();

	}

	private OnClickListener backClicker = new OnClickListener() {
		public void onClick(View v) {
			onFinishing();
			finish();
		}
	};

	private void onFinishing() {
		if (settingsChanged) {
			setResult(RESULT_OK);
		} else {
			setResult(RESULT_CANCELED);
		}
	}

	private OnClickListener saveClicker = new OnClickListener() {
		public void onClick(View v) {
			String teamName = name.getText().toString();
			String teamFlag = (String)((Map<String, Object>) flag.getSelectedItem()).get("txt");
			String teamFort = fort.getSelectedItem().toString();
			String teamGrave = (String)((Map<String, Object>) grave.getSelectedItem()).get("txt");
			String teamVoice = voice.getSelectedItem().toString();
			String levelString = (String)((Map<String, Object>) difficulty.getSelectedItem()).get("txt");
			int levelInt;
			if (levelString.equals(getString(R.string.human))) {
				levelInt = 0;
			} else if (levelString.equals(getString(R.string.bot5))) {
				levelInt = 1;
			} else if (levelString.equals(getString(R.string.bot4))) {
				levelInt = 2;
			} else if (levelString.equals(getString(R.string.bot3))) {
				levelInt = 3;
			} else if (levelString.equals(getString(R.string.bot2))) {
				levelInt = 4;
			} else {
				levelInt = 5;
			}
			
			List<Hog> hogs = new ArrayList<Hog>();
			for (int i = 0; i < hogName.size(); i++) {
				String name = hogName.get(i).getText().toString();
				String hat = ((Map<String, Object>) hogHat.get(i).getSelectedItem()).get("txt").toString();
				hogs.add(new Hog(name, hat, levelInt));
			}
			
			Team team = new Team(teamName, teamGrave, teamFlag, teamVoice, teamFort, hogs);
			File teamsDir = new File(getFilesDir(), Team.DIRECTORY_TEAMS);
			if (!teamsDir.exists()) teamsDir.mkdir();
			if(fileName == null){
				fileName = createNewFilename(Utils.replaceBadChars(team.name));
			}
			try {
				team.save(new File(teamsDir, fileName));
				Toast.makeText(TeamCreatorActivity.this, R.string.saved, Toast.LENGTH_SHORT).show();
				saved = true;
			} catch(IOException e) {
				Toast.makeText(getApplicationContext(), R.string.error_save_failed, Toast.LENGTH_SHORT).show();
			}
		}
	};

	private String createNewFilename(String suggestedName){
		File f = new File(getFilesDir(), suggestedName);
		if(f.exists()){
			return createNewFilename(suggestedName + (int)(Math.random()*10));
		} else {
			return suggestedName + (int)(Math.random()*10);
		}
	}
	
	private OnItemSelectedListener fortSelector = new OnItemSelectedListener() {
		public void onItemSelected(AdapterView<?> arg0, View arg1,
				int position, long arg3) {
			settingsChanged = true;
			String fortName = (String) arg0.getAdapter().getItem(position);
			Drawable fortIconDrawable = Drawable.createFromPath(Utils
					.getDataPath(TeamCreatorActivity.this)
					+ "Forts/"
					+ fortName + "L.png");
			imgFort.setImageDrawable(fortIconDrawable);
			scroller.fullScroll(ScrollView.FOCUS_DOWN);// Scroll the scrollview
			// to the bottom, work
			// around for scrollview
			// invalidation (scrolls
			// back to top)
		}

		public void onNothingSelected(AdapterView<?> arg0) {
		}

	};

	private OnClickListener voiceClicker = new OnClickListener() {
		public void onClick(View v) {
			try {
				File dir = new File(String.format("%sSounds/voices/%s",
						Utils.getDataPath(TeamCreatorActivity.this),
						voice.getSelectedItem()));
				String file = "";
				File[] dirs = dir.listFiles();
				File f = dirs[(int) Math.round(Math.random() * dirs.length)];
				if (f.getName().endsWith(".ogg"))
					file = f.getAbsolutePath();

				if (mp == null)
					mp = new MediaPlayer();
				else
					mp.reset();
				mp.setDataSource(file);
				mp.prepare();
				mp.start();
			} catch (IllegalArgumentException e) {
				e.printStackTrace();
			} catch (IllegalStateException e) {
				e.printStackTrace();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	};

	private void setTeamValues(Team t){

		if (t != null) {
			name.setText(t.name);
			int position = ((ArrayAdapter<String>) voice.getAdapter()).getPosition(t.voice);
			voice.setSelection(position);

			position = ((ArrayAdapter<String>) fort.getAdapter()).getPosition(t.fort);
			fort.setSelection(position);

			position = 0;
			for (HashMap<String, ?> hashmap : typesData) {
				if (t.hogs.get(0) != null && hashmap.get("txt").equals(t.hogs.get(0).level)) {
					difficulty.setSelection(position);
					break;
				}
			}

			position = 0;
			for (HashMap<String, ?> hashmap : gravesData) {
				if (hashmap.get("txt").equals(t.grave)) {
					grave.setSelection(position);
					break;
				}
			}

			position = 0;
			for (HashMap<String, ?> hashmap : typesData) {
				if (hashmap.get("txt").equals(t.flag)) {
					flag.setSelection(position);
					break;
				}
			}

			for (int i = 0; i < Team.maxNumberOfHogs; i++) {
				position = 0;
				for (HashMap<String, ?> hashmap : hatsData) {
					if (hashmap.get("txt").equals(t.hogs.get(i).hat)) {
						hogHat.get(i).setSelection(position);
					}
				}

				hogName.get(i).setText(t.hogs.get(i).name);
			}
			//this.fileName = t.file;
		}
	}


	private SimpleAdapter.ViewBinder viewBinder = new SimpleAdapter.ViewBinder() {

		public boolean setViewValue(View view, Object data,
				String textRepresentation) {
			if (view instanceof ImageView && data instanceof Bitmap) {
				ImageView v = (ImageView) view;
				v.setImageBitmap((Bitmap) data);
				return true;
			} else {
				return false;
			}
		}
	};

}
