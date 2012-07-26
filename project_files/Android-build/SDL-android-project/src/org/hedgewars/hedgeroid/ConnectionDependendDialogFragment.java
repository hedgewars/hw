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
