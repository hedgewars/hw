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
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.support.v4.app.DialogFragment;
import android.support.v4.content.LocalBroadcastManager;

/**
 * Helper class for DialogFragments that are supposed to be dismissed when the
 * network connection is lost. This is used for some dialog fragments that
 * appear during connecting (e.g. username input)
 */
public class ConnectionDependendDialogFragment extends DialogFragment {
    @Override
    public void onStart() {
        super.onStart();
        LocalBroadcastManager.getInstance(getActivity().getApplicationContext()).registerReceiver(dismissReceiver, new IntentFilter(Netplay.ACTION_DISCONNECTED));
        if(Netplay.getAppInstance(getActivity().getApplicationContext()).getState() == State.NOT_CONNECTED) {
            dismiss();
        }
    }

    @Override
    public void onStop() {
        super.onStop();
        LocalBroadcastManager.getInstance(getActivity().getApplicationContext()).unregisterReceiver(dismissReceiver);
    }

    private BroadcastReceiver dismissReceiver = new BroadcastReceiver() {
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
}
