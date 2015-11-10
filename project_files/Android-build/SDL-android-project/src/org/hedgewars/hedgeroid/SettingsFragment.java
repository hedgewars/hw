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

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Datastructures.FrontendDataUtils;
import org.hedgewars.hedgeroid.Datastructures.MapRecipe;
import org.hedgewars.hedgeroid.Datastructures.Scheme;
import org.hedgewars.hedgeroid.Datastructures.Schemes;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.Datastructures.Weaponset;
import org.hedgewars.hedgeroid.Datastructures.Weaponsets;
import org.hedgewars.hedgeroid.util.FileUtils;

import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemSelectedListener;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.Spinner;
import android.widget.Toast;

public class SettingsFragment extends Fragment {
    private Spinner styleSpinner, schemeSpinner, weaponsetSpinner, themeSpinner;
    private ImageView themeIcon;

    private List<String> styles;
    private List<Scheme> schemes;
    private List<Weaponset> weaponsets;
    private List<String> themes;

    private RoomStateManager stateManager;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
            Bundle savedInstanceState) {
        View v = inflater.inflate(R.layout.fragment_settings, container, false);
        themeIcon = (ImageView)v.findViewById(R.id.imgTheme);

        try {
            styles = FrontendDataUtils.getGameStyles(getActivity());
            schemes = Schemes.loadAllSchemes(getActivity());
            weaponsets = Weaponsets.loadAllWeaponsets(getActivity());
            themes = FrontendDataUtils.getThemes(getActivity());
        } catch (IOException e) {
            Toast.makeText(getActivity().getApplicationContext(), R.string.error_missing_sdcard_or_files, Toast.LENGTH_LONG).show();
            getActivity().finish();
            return null;
        }

        Collections.sort(styles, String.CASE_INSENSITIVE_ORDER);
        Collections.sort(schemes, Scheme.NAME_ORDER);
        Collections.sort(weaponsets, Weaponset.NAME_ORDER);
        Collections.sort(themes, String.CASE_INSENSITIVE_ORDER);

        styleSpinner = prepareSpinner(v, R.id.spinGameplay, styles, styleSelectedListener);
        schemeSpinner = prepareSpinner(v, R.id.spinGamescheme, Schemes.toNameList(schemes), schemeSelectedListener);
        weaponsetSpinner = prepareSpinner(v, R.id.spinweapons, Weaponsets.toNameList(weaponsets), weaponsetSelectedListener);
        themeSpinner = prepareSpinner(v, R.id.spinTheme, themes, themeSelectedListener);

        stateManager.addListener(roomStateChangeListener);

        if(stateManager.getGameStyle() != null) {
            styleSpinner.setSelection(styles.indexOf(stateManager.getGameStyle()), false);
        }
        if(stateManager.getScheme() != null) {
            schemeSpinner.setSelection(getSchemePosition(schemes, stateManager.getScheme().name), false);
        }
        if(stateManager.getWeaponset() != null) {
            weaponsetSpinner.setSelection(getWeaponsetPosition(weaponsets, stateManager.getWeaponset().name), false);
        }
        if(stateManager.getMapRecipe() != null) {
            themeSpinner.setSelection(themes.indexOf(stateManager.getMapRecipe().theme), false);
        }

        setChiefState(stateManager.getChiefStatus());

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
        stateManager.removeListener(roomStateChangeListener);
    }

    private static int getSchemePosition(List<Scheme> schemes, String scheme) {
        for(int i=0; i<schemes.size(); i++) {
            if(schemes.get(i).name.equals(scheme)) {
                return i;
            }
        }
        return -1;
    }

    private static int getWeaponsetPosition(List<Weaponset> weaponsets, String weaponset) {
        for(int i=0; i<weaponsets.size(); i++) {
            if(weaponsets.get(i).name.equals(weaponset)) {
                return i;
            }
        }
        return -1;
    }

    private void setChiefState(boolean chiefState) {
        styleSpinner.setEnabled(chiefState);
        schemeSpinner.setEnabled(chiefState);
        weaponsetSpinner.setEnabled(chiefState);
        themeSpinner.setEnabled(chiefState);

        if(chiefState) {
            stateManager.changeGameStyle(styles.get(styleSpinner.getSelectedItemPosition()));
            stateManager.changeScheme(schemes.get(schemeSpinner.getSelectedItemPosition()));
            stateManager.changeWeaponset(weaponsets.get(weaponsetSpinner.getSelectedItemPosition()));
            stateManager.changeMapTheme(themes.get(themeSpinner.getSelectedItemPosition()));
        }
    }

    private final OnItemSelectedListener styleSelectedListener = new OnItemSelectedListener() {
        public void onItemSelected(AdapterView<?> adapter, View v, int position, long arg3) {
            stateManager.changeGameStyle(styles.get(position));
        }
        public void onNothingSelected(AdapterView<?> arg0) {}
    };

    private final OnItemSelectedListener schemeSelectedListener = new OnItemSelectedListener() {
        public void onItemSelected(AdapterView<?> adapter, View v, int position, long arg3) {
            stateManager.changeScheme(schemes.get(position));
        }
        public void onNothingSelected(AdapterView<?> arg0) {}
    };

    private final OnItemSelectedListener weaponsetSelectedListener = new OnItemSelectedListener() {
        public void onItemSelected(AdapterView<?> adapter, View v, int position, long arg3) {
            stateManager.changeWeaponset(weaponsets.get(position));
        }
        public void onNothingSelected(AdapterView<?> arg0) {}
    };

    private final OnItemSelectedListener themeSelectedListener = new OnItemSelectedListener() {
        public void onItemSelected(AdapterView<?> adapter, View v, int position, long arg3) {
            stateManager.changeMapTheme(themes.get(position));
            String theme = themes.get(position);
            try {
                File iconFile = FileUtils.getDataPathFile(getActivity(), "Themes", theme, "icon@2X.png");
                Drawable themeIconDrawable = Drawable.createFromPath(iconFile.getAbsolutePath());
                themeIcon.setImageDrawable(themeIconDrawable);
            } catch (FileNotFoundException e) {
                Log.e("SettingsFragment", "Unable to find preview for theme "+theme, e);
            }
        };
        public void onNothingSelected(AdapterView<?> arg0) {};
    };

    private final RoomStateManager.Listener roomStateChangeListener = new RoomStateManager.Listener() {
        public void onWeaponsetChanged(Weaponset weaponset) {
            weaponsetSpinner.setSelection(getWeaponsetPosition(weaponsets, weaponset.name));
        }

        public void onTeamsChanged(Map<String, TeamInGame> teams) {}

        public void onSchemeChanged(Scheme scheme) {
            schemeSpinner.setSelection(getSchemePosition(schemes, scheme.name));
        }

        public void onMapChanged(MapRecipe recipe) {
            themeSpinner.setSelection(themes.indexOf(recipe.theme));
        }

        public void onGameStyleChanged(String gameStyle) {
            styleSpinner.setSelection(styles.indexOf(gameStyle));
        }

        public void onChiefStatusChanged(boolean isChief) {
            setChiefState(isChief);
        }
    };
}
