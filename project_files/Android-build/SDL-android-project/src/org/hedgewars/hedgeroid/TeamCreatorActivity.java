/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011-2012 Richard Deurwaarder <xeli@xelification.com>
 * Copyright (C) 2012 Simeon Maxein <smaxein@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

package org.hedgewars.hedgeroid;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;

import org.hedgewars.hedgeroid.Datastructures.FrontendDataUtils;
import org.hedgewars.hedgeroid.Datastructures.Hog;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.util.FileUtils;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.media.MediaPlayer;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
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
import android.widget.SpinnerAdapter;
import android.widget.TextView;
import android.widget.Toast;

/**
 * Edit or create a team. If a team should be edited, it is supplied in the extras
 * as parameter oldTeamName.
 */
public class TeamCreatorActivity extends Activity implements Runnable {
    public static final String PARAMETER_EXISTING_TEAMNAME = "existingTeamName";
    private static final String TAG = TeamCreatorActivity.class.getSimpleName();

    private TextView name;
    private Spinner difficulty, grave, flag, voice, fort;
    private ImageView imgFort;
    private ArrayList<ImageButton> hogDice = new ArrayList<ImageButton>();
    private ArrayList<Spinner> hogHat = new ArrayList<Spinner>();
    private ArrayList<EditText> hogName = new ArrayList<EditText>();
    private ImageButton voiceButton;
    private ScrollView scroller;
    private MediaPlayer mp = null;
    private boolean initComplete = false;

    private String existingTeamName = null;

    private final List<Map<String, ?>> flagsData = new ArrayList<Map<String, ?>>();
    private final List<Map<String, ?>> typesData = new ArrayList<Map<String, ?>>();
    private final List<Map<String, ?>> gravesData = new ArrayList<Map<String, ?>>();
    private final List<Map<String, ?>> hatsData = new ArrayList<Map<String, ?>>();
    private final List<String> voicesData = new ArrayList<String>();
    private final List<String> fortsData = new ArrayList<String>();

    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        initComplete = false;

        // Restore state and read parameters
        if(savedInstanceState != null) {
            existingTeamName = savedInstanceState.getString(PARAMETER_EXISTING_TEAMNAME);
        } else {
            existingTeamName = getIntent().getStringExtra(PARAMETER_EXISTING_TEAMNAME);
        }

        // Set up view
        setContentView(R.layout.team_creation);

        name = (TextView) findViewById(R.id.txtName);
        difficulty = (Spinner) findViewById(R.id.spinType);
        grave = (Spinner) findViewById(R.id.spinGrave);
        flag = (Spinner) findViewById(R.id.spinFlag);
        voice = (Spinner) findViewById(R.id.spinVoice);
        fort = (Spinner) findViewById(R.id.spinFort);

        imgFort = (ImageView) findViewById(R.id.imgFort);

        voiceButton = (ImageButton) findViewById(R.id.btnPlay);

        scroller = (ScrollView) findViewById(R.id.scroller);

        // Wire view elements
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

        grave.setAdapter(createMapSpinnerAdapter(gravesData));
        flag.setAdapter(createMapSpinnerAdapter(flagsData));
        difficulty.setAdapter(createMapSpinnerAdapter(typesData));
        SpinnerAdapter hatAdapter = createMapSpinnerAdapter(hatsData);
        for (Spinner spin : hogHat) {
            spin.setAdapter(hatAdapter);
        }


        voice.setAdapter(createListSpinnerAdapter(voicesData));
        voiceButton.setOnClickListener(voiceClicker);

        fort.setAdapter(createListSpinnerAdapter(fortsData));
        fort.setOnItemSelectedListener(fortSelector);

        new Thread(this).start();
    }

    private SpinnerAdapter createMapSpinnerAdapter(List<? extends Map<String, ?>> data) {
        SimpleAdapter sa = new SimpleAdapter(this, data,
                R.layout.spinner_textimg_entry, new String[] { "txt", "img" },
                new int[] { R.id.spinner_txt, R.id.spinner_img });
        sa.setDropDownViewResource(R.layout.spinner_textimg_dropdown_entry);
        sa.setViewBinder(viewBinder);
        return sa;
    }

    private SpinnerAdapter createListSpinnerAdapter(List<String> data) {
        ArrayAdapter<String> adapter = new ArrayAdapter<String>(this, R.layout.listview_item, data);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        return adapter;
    }

    public void run(){
        try {
            final List<Map<String, ?>> gravesDataNew = FrontendDataUtils.getGraves(this);
            runOnUiThread(new Runnable(){
                public void run() {
                    gravesData.addAll(gravesDataNew);
                    ((SimpleAdapter)grave.getAdapter()).notifyDataSetChanged();
                }
            });

            final List<Map<String, ?>> flagsDataNew = FrontendDataUtils.getFlags(this);
            runOnUiThread(new Runnable(){
                public void run() {
                    flagsData.addAll(flagsDataNew);
                    ((SimpleAdapter)flag.getAdapter()).notifyDataSetChanged();
                }
            });

            final List<Map<String, ?>> typesDataNew = FrontendDataUtils.getTypes(this);
            runOnUiThread(new Runnable(){
                public void run() {
                    typesData.addAll(typesDataNew);
                    ((SimpleAdapter)difficulty.getAdapter()).notifyDataSetChanged();
                }
            });

            final List<Map<String, ?>> hatsDataNew = FrontendDataUtils.getHats(this);
            runOnUiThread(new Runnable(){
                public void run() {
                    hatsData.addAll(hatsDataNew);
                    ((SimpleAdapter)hogHat.get(0).getAdapter()).notifyDataSetChanged();
                }
            });

            final List<String> voicesDataNew = FrontendDataUtils.getVoices(this);
            runOnUiThread(new Runnable(){
                public void run() {
                    voicesData.addAll(voicesDataNew);
                    ((ArrayAdapter<?>)voice.getAdapter()).notifyDataSetChanged();
                }
            });

            final List<String> fortsDataNew = FrontendDataUtils.getForts(this);
            runOnUiThread(new Runnable(){
                public void run() {
                    fortsData.addAll(fortsDataNew);
                    ((ArrayAdapter<?>)fort.getAdapter()).notifyDataSetChanged();
                }
            });

            if(existingTeamName!=null) {
                final Team loadedTeam = Team.load(Team.getTeamfileByName(getApplicationContext(), existingTeamName));
                if(loadedTeam==null) {
                    existingTeamName = null;
                } else {
                    runOnUiThread(new Runnable(){
                        public void run() {
                            setTeamValues(loadedTeam);
                        }
                    });
                }
            }
            runOnUiThread(new Runnable(){
                public void run() {
                    initComplete = true;
                }
            });
        } catch(FileNotFoundException e) {
            this.runOnUiThread(new Runnable(){
                public void run() {
                    Toast.makeText(getApplicationContext(), R.string.error_missing_sdcard_or_files, Toast.LENGTH_LONG).show();
                    finish();
                }
            });
        }
    }

    public void onDestroy() {
        super.onDestroy();
        if (mp != null) {
            mp.release();
            mp = null;
        }
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putString(PARAMETER_EXISTING_TEAMNAME, existingTeamName);
    }

    public void onBackPressed() {
        if(initComplete) {
            saveTeam();
        }
        setResult(RESULT_OK);
        super.onBackPressed();
    }

    private void saveTeam() {
        String teamName = name.getText().toString();
        String teamFlag = (String)((Map<String, Object>) flag.getSelectedItem()).get("txt");
        String teamFort = fort.getSelectedItem().toString();
        String teamGrave = (String)((Map<String, Object>) grave.getSelectedItem()).get("txt");
        String teamVoice = voice.getSelectedItem().toString();
        int levelInt = (Integer)((Map<String, Object>) difficulty.getSelectedItem()).get("level");

        List<Hog> hogs = new ArrayList<Hog>();
        for (int i = 0; i < hogName.size(); i++) {
            String name = hogName.get(i).getText().toString();
            String hat = ((Map<String, Object>) hogHat.get(i).getSelectedItem()).get("txt").toString();
            hogs.add(new Hog(name, hat, levelInt));
        }

        Team team = new Team(teamName, teamGrave, teamFlag, teamVoice, teamFort, hogs);
        File teamsDir = new File(getFilesDir(), Team.DIRECTORY_TEAMS);
        if (!teamsDir.exists()) teamsDir.mkdir();

        File newFile = Team.getTeamfileByName(this, teamName);
        File oldFile = null;
        if(existingTeamName != null) {
            oldFile = Team.getTeamfileByName(this, existingTeamName);
        }
        try {
            team.save(newFile);
            // If the team was renamed, delete the old file.
            if(oldFile != null && oldFile.isFile() && !oldFile.equals(newFile)) {
                oldFile.delete();
            }
            existingTeamName = teamName;
        } catch(IOException e) {
            Toast.makeText(getApplicationContext(), R.string.error_save_failed, Toast.LENGTH_SHORT).show();
        }
    };

    private OnItemSelectedListener fortSelector = new OnItemSelectedListener() {
        public void onItemSelected(AdapterView<?> arg0, View arg1,
                int position, long arg3) {
            String fortName = (String) arg0.getAdapter().getItem(position);
            try {
                File fortImage = FileUtils.getDataPathFile(TeamCreatorActivity.this, "Forts", fortName, "L.png");
                Drawable fortIconDrawable = Drawable.createFromPath(fortImage.getAbsolutePath());
                imgFort.setImageDrawable(fortIconDrawable);
            } catch(IOException e) {
                Log.e(TAG, "Unable to show fort image", e);
            }
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
                File dir = FileUtils.getDataPathFile(TeamCreatorActivity.this, "Sounds", "voices", (String)voice.getSelectedItem());
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
                Log.e(TAG, "Unable to play voice sample", e);
            } catch (IllegalStateException e) {
                Log.e(TAG, "Unable to play voice sample", e);
            } catch (IOException e) {
                Log.e(TAG, "Unable to play voice sample", e);
            }
        }
    };

    @SuppressWarnings("unchecked")
    private void setTeamValues(Team t){
        if (t == null) {
            return;
        }

        try {
            name.setText(t.name);
            voice.setSelection(findPosition((ArrayAdapter<String>) voice.getAdapter(), t.voice));
            fort.setSelection(findPosition((ArrayAdapter<String>) fort.getAdapter(), t.fort));
            difficulty.setSelection(findPosition(typesData, "level", Integer.valueOf(t.hogs.get(0).level)));
            grave.setSelection(findPosition(gravesData, "txt", t.grave));
            flag.setSelection(findPosition(flagsData, "txt", t.flag));

            for (int i = 0; i < Team.HEDGEHOGS_PER_TEAM; i++) {
                hogHat.get(i).setSelection(findPosition(hatsData, "txt", t.hogs.get(i).hat));
                hogName.get(i).setText(t.hogs.get(i).name);
            }
        } catch(NoSuchElementException e) {
            Toast.makeText(getApplicationContext(), R.string.error_team_attribute_not_found, Toast.LENGTH_LONG).show();
            finish();
        }
    }

    int findPosition(ArrayAdapter<String> adapter, String value) throws NoSuchElementException {
        int position = adapter.getPosition(value);
        if(position<0) {
            throw new NoSuchElementException();
        }
        return position;
    }

    int findPosition(List<? extends Map<String, ?>> data, String key, Object value) throws NoSuchElementException {
        int position = 0;
        for (Map<String, ?> map : data) {
            if (map.get(key).equals(value)) {
                return position;
            }
            position++;
        }
        throw new NoSuchElementException();
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
