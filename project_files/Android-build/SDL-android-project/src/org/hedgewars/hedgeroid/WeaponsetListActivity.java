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
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import org.hedgewars.hedgeroid.Datastructures.Weaponset;
import org.hedgewars.hedgeroid.Datastructures.Weaponsets;

import android.app.ListActivity;
import android.content.Intent;
import android.os.Bundle;
import android.view.ContextMenu;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.AdapterView;
import android.widget.AdapterView.AdapterContextMenuInfo;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.Button;
import android.widget.ListAdapter;
import android.widget.SimpleAdapter;
import android.widget.Toast;

public class WeaponsetListActivity extends ListActivity implements OnItemClickListener {
    private List<Weaponset> userWeaponsets;
    private Button addButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_weaponsetlist);
        addButton = (Button)findViewById(R.id.addButton);
        addButton.setOnClickListener(new OnClickListener() {
            public void onClick(View v) {
                editWeaponset(null);
            }
        });
    }

    @Override
    public void onResume() {
        super.onResume();
        updateList();
        getListView().setOnItemClickListener(this);
        registerForContextMenu(getListView());
    }

    private List<Map<String, ?>> weaponsetsToMap(List<Weaponset> weaponsets) {
        List<Map<String, ?>> result = new ArrayList<Map<String, ?>>();
        for(Weaponset weaponset : weaponsets) {
            result.add(Collections.singletonMap("txt", weaponset.name));
        }
        return result;
    }

    public void onItemClick(AdapterView<?> adapterView, View v, int position, long arg3) {
        editWeaponset(userWeaponsets.get(position).name);
    }

    @Override
    public void onCreateContextMenu(ContextMenu menu, View v, ContextMenu.ContextMenuInfo menuinfo){
        menu.add(ContextMenu.NONE, 0, ContextMenu.NONE, R.string.edit);
        menu.add(ContextMenu.NONE, 1, ContextMenu.NONE, R.string.delete);
    }

    @Override
    public boolean onContextItemSelected(MenuItem item){
        AdapterView.AdapterContextMenuInfo menuInfo = (AdapterContextMenuInfo) item.getMenuInfo();
        int position = menuInfo.position;
        Weaponset weaponset = userWeaponsets.get(position);
        switch(item.getItemId()){
        case 0:
            editWeaponset(weaponset.name);
            return true;
        case 1:
            try {
                Weaponsets.deleteUserWeaponset(this, weaponset.name);
            } catch (IOException e) {
                Toast.makeText(this.getApplicationContext(), R.string.error_missing_sdcard_or_files, Toast.LENGTH_SHORT).show();
            }
            updateList();
            return true;
        }
        return false;
    }

    private void updateList() {
        try {
            userWeaponsets = Weaponsets.loadUserWeaponsets(this);
        } catch (IOException e) {
            Toast.makeText(this, R.string.error_missing_sdcard_or_files, Toast.LENGTH_LONG).show();
            finish();
        }
        Collections.sort(userWeaponsets, Weaponset.NAME_ORDER);
        ListAdapter adapter = new SimpleAdapter(this, weaponsetsToMap(userWeaponsets), android.R.layout.simple_list_item_1, new String[]{"txt"}, new int[]{android.R.id.text1});
        setListAdapter(adapter);
    }

    private void editWeaponset(String weaponsetName) {
        Intent i = new Intent(this, WeaponsetCreatorActivity.class);
        i.putExtra(WeaponsetCreatorActivity.PARAMETER_EXISTING_WEAPONSETNAME, weaponsetName);
        startActivity(i);
    }
}
