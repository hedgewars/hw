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

public class ConnectingDialog extends ConnectionDependendDialogFragment {
	@Override
	public void onStart() {
		super.onStart();
		LocalBroadcastManager.getInstance(getActivity().getApplicationContext()).registerReceiver(connectedReceiver, new IntentFilter(Netplay.ACTION_CONNECTED));

		if(Netplay.getAppInstance(getActivity().getApplicationContext()).getState() != State.CONNECTING) {
			dismiss();
		}
	}
	
	@Override
	public void onStop() {
		super.onStop();
		LocalBroadcastManager.getInstance(getActivity().getApplicationContext()).unregisterReceiver(connectedReceiver);
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
	
	public void onCancel(DialogInterface dialog) {
		super.onCancel(dialog);
		Netplay.getAppInstance(getActivity().getApplicationContext()).disconnect();
	};
}
