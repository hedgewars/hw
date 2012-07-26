package org.hedgewars.hedgeroid.netplay;


import org.hedgewars.hedgeroid.R;

import android.os.Bundle;
import android.support.v4.app.Fragment;
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
	private ChatlogAdapter adapter;
	private Netplay netconn;
	
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		netconn = Netplay.getAppInstance(getActivity().getApplicationContext());
		adapter = new ChatlogAdapter(getActivity());
    	adapter.setLog(netconn.lobbyChatlog.getLog());
    	netconn.lobbyChatlog.registerObserver(adapter);
	}
	
	@Override
	public void onStart() {
		super.onStart();
	}
	
	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		View view = inflater.inflate(R.layout.lobby_chat_fragment, container, false);
		
		ListView listView = (ListView) view.findViewById(R.id.lobbyConsole);
		listView.setAdapter(adapter);
		listView.setDivider(null);
		listView.setDividerHeight(0);
		listView.setVerticalFadingEdgeEnabled(true);
		
		EditText editText = (EditText) view.findViewById(R.id.lobbyChatInput);
        editText.setOnEditorActionListener(new ChatSendListener());
        
		return view;
	}
	
	@Override
	public void onDestroy() {
		super.onDestroy();
		netconn.lobbyChatlog.unregisterObserver(adapter);
	}

	private final class ChatSendListener implements OnEditorActionListener {
		public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
			String text = v.getText().toString();
			if(text.length()>0) {
				v.setText("");
				netconn.sendChat(text);
			}
			return true;
		}
	}
}
