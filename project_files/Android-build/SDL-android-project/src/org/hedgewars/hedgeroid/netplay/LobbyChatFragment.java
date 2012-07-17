package org.hedgewars.hedgeroid.netplay;


import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.netplay.NetplayService.NetplayBinder;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.res.Configuration;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.support.v4.app.Fragment;
import android.text.Spanned;
import android.text.method.LinkMovementMethod;
import android.util.Log;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;

public class LobbyChatFragment extends Fragment {
	private TextView textView;
	private EditText editText;
	private ScrollView scrollView;
	private Netconn netconn;
	
	private void scrollDown() {
		scrollView.post(new Runnable() {
			public void run() {
				scrollView.smoothScrollTo(0, textView.getBottom());
			}
		});
	}
	
	private void commitText() {
		if(netconn != null && netconn.isConnected()) {
			String text = editText.getText().toString();
			editText.setText("");
			netconn.sendChat(text);
		}
	}
	
	@Override
	public void onStart() {
		super.onStart();
		getActivity().bindService(new Intent(getActivity(), NetplayService.class), serviceConnection,
	            Context.BIND_AUTO_CREATE);
		Log.d("LobbyChatFragment", "started");
	}
	
	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		View view = inflater.inflate(R.layout.lobby_chat_fragment, container, false);
		textView = (TextView) view.findViewById(R.id.lobbyConsole);
		editText = (EditText) view.findViewById(R.id.lobbyChatInput);
		scrollView = (ScrollView) view.findViewById(R.id.lobbyConsoleScroll);
		
		textView.setMovementMethod(LinkMovementMethod.getInstance());
		
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
        	netconn.lobbyLog.observe(observer);
        }

        public void onServiceDisconnected(ComponentName className) {
        	// TODO navigate away
        	netconn.lobbyLog.unobserve(observer);
        	netconn = null;
        }
    };
    
    private MessageLog.Observer observer = new MessageLog.Observer() {
		public void textChanged(Spanned text) {
			if(textView != null) {
				int overhang = textView.getHeight()-scrollView.getHeight();
				boolean followBottom = overhang<=0 || Math.abs(overhang-scrollView.getScrollY())<5;
				textView.setText(text);
				if(followBottom) {
					scrollDown();
				}
			}
		}
	};
}
