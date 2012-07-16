package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.R;

import android.os.Bundle;
import android.os.Handler;
import android.support.v4.app.Fragment;
import android.text.Html;
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
	
	private void commitText() {
		String text = editText.getText().toString();
		int overhang = textView.getHeight()-scrollView.getHeight();
		boolean followBottom = overhang<=0 || Math.abs(overhang-scrollView.getScrollY())<5;
		textView.append(Html.fromHtml("<b>Chatter:</b> " + text + "<br/>"));
		editText.setText("");
		if(followBottom) {
			new Handler().post(new Runnable() {
				public void run() {
					scrollView.fullScroll(ScrollView.FOCUS_DOWN);
				}
			});
		}
	}
	/*
	@Override
	public void onStart() {
		super.onStart();
		getActivity().bindService(new Intent(getActivity(), NetplayService.class), serviceConnection,
	            Context.BIND_AUTO_CREATE);
	}
	*/
	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		View view = inflater.inflate(R.layout.lobby_chat_fragment, container, false);
		textView = (TextView) view.findViewById(R.id.lobbyConsole);
		editText = (EditText) view.findViewById(R.id.lobbyChatInput);
		scrollView = (ScrollView) view.findViewById(R.id.lobbyConsoleScroll);
		
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
	/*
    private ServiceConnection serviceConnection = new ServiceConnection() {
        public void onServiceConnected(ComponentName className, IBinder binder) {
        	netplayService = ((NetplayBinder) binder).getService();
        	try {
				netplayService.connect("AndroidChatter");
			} catch (IOException e) {
				throw new RuntimeException(e);
			}
        }

        public void onServiceDisconnected(ComponentName className) {
        	// TODO navigate away
        	netplayService = null;
        }
    };
    */
}
