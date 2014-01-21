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
import org.hedgewars.hedgeroid.netplay.Netplay.State;

import android.app.Dialog;
import android.app.ProgressDialog;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.support.v4.content.LocalBroadcastManager;
import android.widget.Toast;

/**
 * Indeterminate progress dialog that is shown in the MainActivity while trying
 * to connect to the server. If the connection fails (disconnect before we reach
 * lobby state), an error toast with the disconnect message is shown.
 *
 */
public class ConnectingDialog extends ConnectionDependendDialogFragment {
    @Override
    public void onStart() {
        super.onStart();
        LocalBroadcastManager.getInstance(getActivity().getApplicationContext()).registerReceiver(connectedReceiver, new IntentFilter(Netplay.ACTION_CONNECTED));
        LocalBroadcastManager.getInstance(getActivity().getApplicationContext()).registerReceiver(disconnectedReceiver, new IntentFilter(Netplay.ACTION_DISCONNECTED));

        if(Netplay.getAppInstance(getActivity().getApplicationContext()).getState() != State.CONNECTING) {
            dismiss();
        }
    }

    @Override
    public void onStop() {
        super.onStop();
        LocalBroadcastManager.getInstance(getActivity().getApplicationContext()).unregisterReceiver(connectedReceiver);
        LocalBroadcastManager.getInstance(getActivity().getApplicationContext()).unregisterReceiver(disconnectedReceiver);
    }

    @Override
    public Dialog onCreateDialog(Bundle savedInstanceState) {
        ProgressDialog dialog = new ProgressDialog(getActivity());
        dialog.setIndeterminate(true);
        dialog.setProgressStyle(ProgressDialog.STYLE_SPINNER);
        dialog.setTitle(R.string.dialog_connecting_title);
        dialog.setMessage(getString(R.string.dialog_connecting_message));
        return dialog;
    }

    private BroadcastReceiver connectedReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            Dialog dialog = getDialog();
            if(dialog != null) {
                dialog.dismiss();
            } else {
                dismiss();
            }
        }
    };

    private BroadcastReceiver disconnectedReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            Toast.makeText(getActivity(), intent.getExtras().getString(Netplay.EXTRA_MESSAGE), Toast.LENGTH_LONG).show();
        }
    };

    public void onCancel(DialogInterface dialog) {
        super.onCancel(dialog);
        Netplay.getAppInstance(getActivity().getApplicationContext()).disconnect();
    };
}
