package org.hedgewars.hedgeroid.netplay;


import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.netplay.NetplayService.NetplayBinder;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;

public class LobbyChatFragment extends Fragment {
	private EditText editText;
	private ListView listView;
	private ChatlogAdapter adapter;
	private Netconn netconn;
	
	private void commitText() {
		String text = editText.getText().toString();
		if(netconn != null && netconn.isConnected() && text.length()>0) {
			editText.setText("");
			netconn.sendChat(text);
		}
	}
	
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		adapter = new ChatlogAdapter(getActivity());
	}
	
	@Override
	public void onStart() {
		super.onStart();
		getActivity().bindService(new Intent(getActivity(), NetplayService.class), serviceConnection,
	            Context.BIND_AUTO_CREATE);
	}
	
	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		View view = inflater.inflate(R.layout.lobby_chat_fragment, container, false);
		editText = (EditText) view.findViewById(R.id.lobbyChatInput);
		listView = (ListView) view.findViewById(R.id.lobbyConsole);
		
		listView.setAdapter(adapter);
		listView.setDivider(null);
		listView.setDividerHeight(0);
		listView.setVerticalFadingEdgeEnabled(true);
		
        editText.setOnEditorActionListener(new OnEditorActionListener() {
			public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
				boolean handled = false;
				if(actionId == EditorInfo.IME_ACTION_SEND) {
					commitText();
					handled = true;
				}
				return handled;
			}
		});
        
		return view;
	}
	
	@Override
	public void onDestroy() {
		super.onDestroy();
		getActivity().unbindService(serviceConnection);
	}

    private ServiceConnection serviceConnection = new ServiceConnection() {
        public void onServiceConnected(ComponentName className, IBinder binder) {
        	Log.d("LobbyChatFragment", "netconn received");
        	netconn = ((NetplayBinder) binder).getNetconn();
        	adapter.setLog(netconn.lobbyLog.getLog());
        	netconn.lobbyLog.registerObserver(adapter);
        }

        public void onServiceDisconnected(ComponentName className) {
        	// TODO navigate away
        	netconn.lobbyLog.unregisterObserver(adapter);
        	netconn = null;
        }
    };
}
