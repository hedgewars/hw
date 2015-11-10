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

import org.hedgewars.hedgeroid.netplay.Netplay;

import android.app.AlertDialog;
import android.app.Dialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.os.Bundle;
import android.support.v4.app.DialogFragment;
import android.view.KeyEvent;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;

public class StartNetgameDialog extends DialogFragment {
    private static final String PREF_PLAYERNAME = "playerName";

    @Override
    public Dialog onCreateDialog(Bundle savedInstanceState) {
        SharedPreferences prefs = getActivity().getSharedPreferences("settings", Context.MODE_PRIVATE);
        final String playerName = prefs.getString(PREF_PLAYERNAME, "Player");
        final EditText editText = new EditText(getActivity());
        final AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());

        editText.setText(playerName);
        editText.setHint(R.string.start_netgame_dialog_playername_hint);
        editText.setId(android.R.id.text1);
        editText.setImeOptions(EditorInfo.IME_ACTION_DONE);
        editText.setSingleLine();

        builder.setTitle(R.string.start_netgame_dialog_title);
        builder.setMessage(R.string.start_netgame_dialog_message);
        builder.setView(editText);
        builder.setNegativeButton(android.R.string.cancel, new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int which) {
                editText.setText(playerName);
            }
        });

        editText.setOnEditorActionListener(new OnEditorActionListener() {
            public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
                boolean handled = false;
                if(actionId == EditorInfo.IME_ACTION_DONE) {
                    startConnection(v.getText().toString());
                    handled = true;
                }
                return handled;
            }
        });

        builder.setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int which) {
                startConnection(editText.getText().toString());
            }
        });

        return builder.create();
    }

    private void startConnection(String username) {
        if(username.length() > 0) {
            SharedPreferences prefs = getActivity().getSharedPreferences("settings", Context.MODE_PRIVATE);
            Editor edit = prefs.edit();
            edit.putString(PREF_PLAYERNAME, username);
            edit.commit();

            Netplay.getAppInstance(getActivity().getApplicationContext()).connectToDefaultServer(username);
            getDialog().dismiss();
            ((MainActivity)getActivity()).onNetConnectingStarted();
        }
    }
}
