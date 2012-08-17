package org.hedgewars.hedgeroid;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.netplay.MessageLog;
import org.hedgewars.hedgeroid.netplay.Netplay;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;

public class ChatFragment extends Fragment {
	public static final String ARGUMENT_INROOM = "inRoom";
	
	private ChatlogAdapter adapter;
	private Netplay netconn;
	private MessageLog messageLog;
	private boolean inRoom;
	
	public void setInRoom(boolean inRoom) {
		this.inRoom = inRoom;
	}
	
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		netconn = Netplay.getAppInstance(getActivity().getApplicationContext());
		adapter = new ChatlogAdapter(getActivity());
	}
	
	@Override
	public void onStart() {
		super.onStart();
		messageLog = inRoom ? netconn.roomChatlog : netconn.lobbyChatlog;
    	adapter.setLog(messageLog.getLog());
    	messageLog.registerObserver(adapter);
	}
	
	@Override
	public void onStop() {
		super.onStop();
		messageLog.unregisterObserver(adapter);
	}
	
	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		View view = inflater.inflate(R.layout.fragment_chat, container, false);
		
		ListView listView = (ListView) view.findViewById(R.id.chatConsole);
		listView.setAdapter(adapter);
		listView.setDivider(null);
		listView.setDividerHeight(0);
		listView.setVerticalFadingEdgeEnabled(true);
		
		EditText editText = (EditText) view.findViewById(R.id.chatInput);
        editText.setOnEditorActionListener(new ChatSendListener());
        
		return view;
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
