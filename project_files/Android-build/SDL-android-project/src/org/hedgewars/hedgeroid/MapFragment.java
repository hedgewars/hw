/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
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

import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Random;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Datastructures.FrontendDataUtils;
import org.hedgewars.hedgeroid.Datastructures.MapFile;
import org.hedgewars.hedgeroid.Datastructures.MapRecipe;
import org.hedgewars.hedgeroid.frontlib.Frontlib;
import org.hedgewars.hedgeroid.util.CalmDownHandler;

import android.content.Context;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemSelectedListener;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.Spinner;
import android.widget.TableRow;
import android.widget.Toast;

/**
 * Display a map preview, and configuration options for the map.
 *
 * Mostly for layout reasons, this does not include the theme setting, which
 * (arguably) is more a map setting than a general game setting.
 */
public class MapFragment extends Fragment {
    private Spinner mapTypeSpinner, mapNameSpinner, templateSpinner, mazeSizeSpinner;
    private TableRow nameRow, templateRow, mazeSizeRow;
    private ImageView mapPreview;

    private List<MapFile> mapFiles;
    private RoomStateManager stateManager;
    private Random random = new Random();
    private CalmDownHandler mapPreviewHandler;

    /*
     * Rendering the preview can take a few seconds on Android, so we want to prevent preview
     * requests from queueing up if maps are changed quickly. So if there is already a preview
     * being generated, we store our latest request in the newPreviewRequest variable instead.
     * Once the current preview is finished generating it will start on that one.
     */
    private boolean previewGenerationInProgress;
    private MapRecipe newPreviewRequest;
    private MapRecipe currentMap; // kept for reference on every change to find out what changed

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View v = inflater.inflate(R.layout.fragment_map, container, false);
        final Context appContext = getActivity().getApplicationContext();

        /*
         * This handler will start the map preview after none of the map settings
         * have been updated for a short time.
         */
        mapPreviewHandler = new CalmDownHandler(getActivity().getMainLooper(), new Runnable() {
            public void run() {
                if(!previewGenerationInProgress) {
                    mapPreview.setImageResource(R.drawable.roomlist_preparing);
                    MapPreviewGenerator.startPreviewGeneration(appContext, stateManager.getMapRecipe(), mapPreviewListener);
                    previewGenerationInProgress = true;
                } else {
                    newPreviewRequest = stateManager.getMapRecipe();
                }
            }
        }, 250);

        nameRow = (TableRow) v.findViewById(R.id.rowMapName);
        templateRow = (TableRow) v.findViewById(R.id.rowTemplateFilter);
        mazeSizeRow = (TableRow) v.findViewById(R.id.rowMazeSize);
        mapPreview = (ImageView) v.findViewById(R.id.mapPreview);
        mapPreview.setImageDrawable(null);;
        mapPreview.setOnClickListener(mapClickListener);

        try {
            mapFiles = FrontendDataUtils.getMaps(getActivity());
        } catch (IOException e) {
            Toast.makeText(getActivity().getApplicationContext(), R.string.error_missing_sdcard_or_files, Toast.LENGTH_LONG).show();
            getActivity().finish();
            return null;
        }
        Collections.sort(mapFiles, MapFile.MISSIONS_FIRST_NAME_ORDER);

        List<String> mapNames = MapFile.toDisplayNameList(mapFiles, getResources());
        mapTypeSpinner = prepareSpinner(v, R.id.spinMapType, Arrays.asList(getResources().getStringArray(R.array.map_types)), mapTypeSelectedListener);
        mapNameSpinner = prepareSpinner(v, R.id.spinMapName, mapNames, mapNameSelectedListener);
        templateSpinner = prepareSpinner(v, R.id.spinTemplateFilter, Arrays.asList(getResources().getStringArray(R.array.map_templates)), mapTemplateSelectedListener);
        mazeSizeSpinner = prepareSpinner(v, R.id.spinMazeSize, Arrays.asList(getResources().getStringArray(R.array.map_maze_sizes)), mazeSizeSelectedListener);

        stateManager.addListener(roomStateChangeListener);
        currentMap = stateManager.getMapRecipe();
        if(currentMap != null) {
            updateDisplay(currentMap);
        }
        setChiefState(stateManager.getChiefStatus());
        mapPreviewHandler.activity();
        return v;
    }

    private static Spinner prepareSpinner(View v, int id, List<String> items, OnItemSelectedListener itemSelectedListener) {
        Spinner spinner = (Spinner)v.findViewById(id);
        ArrayAdapter<String> adapter = new ArrayAdapter<String>(v.getContext(), R.layout.listview_item, items);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spinner.setAdapter(adapter);
        spinner.setOnItemSelectedListener(itemSelectedListener);
        return spinner;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        try {
            stateManager = ((RoomStateManager.Provider)getActivity()).getRoomStateManager();
        } catch(ClassCastException e) {
            throw new RuntimeException("Hosting activity must implement RoomStateManager.Provider.", e);
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        mapPreviewHandler.stop();
        newPreviewRequest = null;

        stateManager.removeListener(roomStateChangeListener);
    }

    private void setChiefState(boolean chiefState) {
        mapTypeSpinner.setEnabled(chiefState);
        mapNameSpinner.setEnabled(chiefState);
        templateSpinner.setEnabled(chiefState);
        mazeSizeSpinner.setEnabled(chiefState);
        mapPreview.setEnabled(chiefState);

        if(chiefState) {
            sendMapnameAndGenerator();
            stateManager.changeMapTemplate(templateSpinner.getSelectedItemPosition());
            stateManager.changeMazeSize(mazeSizeSpinner.getSelectedItemPosition());
        }
    }

    private void updateDisplay(MapRecipe map) {
        nameRow.setVisibility(map.mapgen == Frontlib.MAPGEN_NAMED ? View.VISIBLE : View.GONE);
        templateRow.setVisibility(map.mapgen == Frontlib.MAPGEN_REGULAR ? View.VISIBLE : View.GONE);
        mazeSizeRow.setVisibility(map.mapgen == Frontlib.MAPGEN_MAZE ? View.VISIBLE : View.GONE);

        mapTypeSpinner.setSelection(map.mapgen);
        int mapPosition = findMapPosition(mapFiles, map.name);
        if(mapPosition >= 0) {
            mapNameSpinner.setSelection(mapPosition);
        }
        templateSpinner.setSelection(map.templateFilter);
        mazeSizeSpinner.setSelection(map.mazeSize);
    }

    private static int findMapPosition(List<MapFile> mapFiles, String mapName) {
        for(int i=0; i<mapFiles.size(); i++) {
            if(mapName.equals(mapFiles.get(i).name)) {
                return i;
            }
        }
        return -1;
    }

    private void sendMapnameAndGenerator() {
        int mapType = mapTypeSpinner.getSelectedItemPosition();
        String mapName = mapFiles.get(mapNameSpinner.getSelectedItemPosition()).name;
        stateManager.changeMapNameAndGenerator(MapRecipe.mapnameForGenerator(mapType, mapName));
    }

    private final OnItemSelectedListener mapTypeSelectedListener = new OnItemSelectedListener() {
        public void onItemSelected(AdapterView<?> adapter, View v, int position, long arg3) {
            sendMapnameAndGenerator();
        }
        public void onNothingSelected(AdapterView<?> arg0) {}
    };

    private final OnItemSelectedListener mapNameSelectedListener = new OnItemSelectedListener() {
        public void onItemSelected(AdapterView<?> adapter, View v, int position, long arg3) {
            sendMapnameAndGenerator();
        }
        public void onNothingSelected(AdapterView<?> arg0) {}
    };

    private final OnItemSelectedListener mapTemplateSelectedListener = new OnItemSelectedListener() {
        public void onItemSelected(AdapterView<?> adapter, View v, int position, long arg3) {
            stateManager.changeMapTemplate(position);
        }
        public void onNothingSelected(AdapterView<?> arg0) {}
    };

    private final OnItemSelectedListener mazeSizeSelectedListener = new OnItemSelectedListener() {
        public void onItemSelected(AdapterView<?> adapter, View v, int position, long arg3) {
            stateManager.changeMazeSize(position);
        }
        public void onNothingSelected(AdapterView<?> arg0) {}
    };

    private final OnClickListener mapClickListener = new OnClickListener() {
        public void onClick(View v) {
            stateManager.changeMapSeed(MapRecipe.makeRandomSeed());
            if(mapTypeSpinner.getSelectedItemPosition() == Frontlib.MAPGEN_NAMED) {
                mapNameSpinner.setSelection(random.nextInt(mapNameSpinner.getCount()));
            }
        }
    };

    private final RoomStateManager.Listener roomStateChangeListener = new RoomStateManager.ListenerAdapter() {
        @Override
        public void onChiefStatusChanged(boolean isChief) {
            setChiefState(isChief);
        };

        @Override
        public void onMapChanged(MapRecipe recipe) {
            // Only trigger a preview update if a relevant field changed (not theme)
            if(currentMap==null
                    || currentMap.mapgen != recipe.mapgen
                    || currentMap.mazeSize != recipe.mazeSize
                    || !currentMap.name.equals(recipe.name)
                    || !currentMap.seed.equals(recipe.seed)
                    || currentMap.templateFilter != recipe.templateFilter
                    || !Arrays.equals(currentMap.getDrawData(), recipe.getDrawData())) {
                mapPreviewHandler.activity();
            }
            updateDisplay(recipe);
            currentMap = recipe;
        };
    };

    private MapPreviewGenerator.Listener mapPreviewListener = new MapPreviewGenerator.Listener() {
        public void onMapPreviewResult(Drawable preview) {
            if(newPreviewRequest != null) {
                MapPreviewGenerator.startPreviewGeneration(getActivity().getApplicationContext(), newPreviewRequest, mapPreviewListener);
                newPreviewRequest = null;
            } else {
                if(mapPreview != null) {
                    mapPreview.setImageDrawable(preview);
                }
                previewGenerationInProgress = false;
            }
        }
    };
}
