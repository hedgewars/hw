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

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.frontlib.Frontlib;
import org.hedgewars.hedgeroid.netplay.Netplay;
import org.hedgewars.hedgeroid.netplay.Netplay.State;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.content.LocalBroadcastManager;
import android.widget.Toast;

/**
 * Fragment for use by an activity that depends on the state of the network
 * connection. The activity must implement the NetplayStateListener interface.
 *
 * This fragment manages reacting to changes in the networking state by calling
 * a callback method on the activity.
 */
public class NetplayStateFragment extends Fragment {
    private Netplay netplay;
    private Context appContext;
    private LocalBroadcastManager broadcastManager;
    private NetplayStateListener listener;
    private State knownState;

    interface NetplayStateListener {
        /**
         * This is called while the activity is running, and every time during resume, if
         * a change in the networking state is detected. It is also called once
         * with the initial state (which could be called a change from the "unknown" state).
         */
        void onNetplayStateChanged(State newState);
    }

    @Override
    public void onAttach(Activity activity) {
        super.onAttach(activity);
        try {
            listener = (NetplayStateListener) activity;
        } catch(ClassCastException e) {
            throw new ClassCastException("Activity " + activity + " must implement NetplayStateListener to use NetplayStateFragment.");
        }
    }

    @Override
    public void onDetach() {
        super.onDetach();
        listener = null;
    }

    @Override
    public void onCreate(Bundle icicle) {
        super.onCreate(icicle);
        appContext = getActivity().getApplicationContext();
        broadcastManager = LocalBroadcastManager.getInstance(appContext);
        netplay = Netplay.getAppInstance(appContext);
    }

    @Override
    public void onResume() {
        super.onResume();
        broadcastManager.registerReceiver(disconnectReceiver, new IntentFilter(Netplay.ACTION_DISCONNECTED));
        broadcastManager.registerReceiver(leaveRoomReceiver, new IntentFilter(Netplay.ACTION_LEFT_ROOM));
        broadcastManager.registerReceiver(stateChangeReceiver, new IntentFilter(Netplay.ACTION_STATE_CHANGED));

        State newState = netplay.getState();
        if(knownState != newState) {
            listener.onNetplayStateChanged(newState);
            knownState = newState;
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        broadcastManager.unregisterReceiver(disconnectReceiver);
        broadcastManager.unregisterReceiver(leaveRoomReceiver);
        broadcastManager.unregisterReceiver(stateChangeReceiver);
    }

    private final BroadcastReceiver disconnectReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if(intent.getBooleanExtra(Netplay.EXTRA_HAS_ERROR, true)) {
                String message = intent.getStringExtra(Netplay.EXTRA_MESSAGE);
                String toastText = getString(R.string.toast_disconnected, message);
                Toast.makeText(appContext, toastText, Toast.LENGTH_LONG).show();
            }
        }
    };

    private final BroadcastReceiver leaveRoomReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            int reason = intent.getIntExtra(Netplay.EXTRA_REASON, -1);
            if(reason == Frontlib.NETCONN_ROOMLEAVE_ABANDONED) {
                Toast.makeText(appContext, R.string.toast_room_abandoned, Toast.LENGTH_LONG).show();
            } else if(reason == Frontlib.NETCONN_ROOMLEAVE_KICKED) {
                Toast.makeText(appContext, R.string.toast_kicked, Toast.LENGTH_LONG).show();
            }
        }
    };

    private final BroadcastReceiver stateChangeReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            State newState = netplay.getState();
            listener.onNetplayStateChanged(newState);
            knownState = newState;
        }
    };
}
