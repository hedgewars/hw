package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.netplay.Netplay.State;

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
 * connection.
 * 
 * This fragment manages a few aspects of the netplay connection: Requesting
 * the network system loop to run at high frequency while the activity is in
 * the foreground, and reacting to changes in the networking state by switching
 * to the appropriate activity or finishing the activity if the network connection
 * is closed.
 */
public class NetplayStateFragment extends Fragment {
    private Netplay netplay;
    private Context appContext;
    private LocalBroadcastManager broadcastManager;
    
    private final BroadcastReceiver disconnectReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			if(intent.getBooleanExtra(Netplay.EXTRA_HAS_ERROR, true)) {
				String message = intent.getStringExtra(Netplay.EXTRA_MESSAGE);
				Toast.makeText(appContext, "Disconnected: "+message, Toast.LENGTH_LONG).show();
			}
			getActivity().finish();
		}
	};
    
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
    	netplay.requestFastTicks();
    	
    	if(netplay.getState() == State.NOT_CONNECTED) {
    		getActivity().finish();
    	}
    }
    
    @Override
    public void onPause() {
    	super.onPause();
    	broadcastManager.unregisterReceiver(disconnectReceiver);
    	netplay.unrequestFastTicks();
    }
}
