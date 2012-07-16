package org.hedgewars.hedgeroid.netplay;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.Collections;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Utils;
import org.hedgewars.hedgeroid.R.layout;

import com.sun.jna.Library;
import com.sun.jna.Native;
import com.sun.jna.Pointer;

import android.os.Bundle;
import android.os.CountDownTimer;
import android.app.Activity;
import android.support.v4.app.FragmentActivity;
import android.text.Html;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.inputmethod.EditorInfo;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;

public class LobbyActivity extends FragmentActivity {
	static {
		System.loadLibrary("SDL_net");
	}
	static final JnaFrontlib FRONTLIB = (JnaFrontlib)Native.loadLibrary("frontlib", JnaFrontlib.class, Collections.singletonMap(Library.OPTION_TYPE_MAPPER, FrontlibTypeMapper.INSTANCE));
	
	TextView textView;
	EditText editText;
	
	boolean disconnected;
	JnaFrontlib.NetconnPtr netconn;
	CountDownTimer timer;
	
	private void commitText() {
		if(!disconnected && netconn!=null) {
			String text = editText.getText().toString();
			editText.setText("");
			textView.append(Html.fromHtml("<b>AndroidChatter</b>: " + text + "<br/>"));
			FRONTLIB.flib_netconn_send_chat(netconn, text);
		}
	}
	
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        disconnected = false;
        setContentView(R.layout.activity_lobby);
        textView = (TextView)findViewById(R.id.lobbyConsole);
        editText = (EditText)findViewById(R.id.lobbyChatInput);
        
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
        
    	FRONTLIB.flib_init();
    	try {
    		JnaFrontlib.MetaschemePtr scheme = FRONTLIB.flib_metascheme_from_ini(new File(Utils.getDataPathFile(this), "metasettings.ini").getAbsolutePath());
			netconn = FRONTLIB.flib_netconn_create("AndroidChatter", scheme, Utils.getDataPathFile(this).getAbsolutePath(), "140.247.62.101", 46631);
			Log.d("Netconn", "netconn is "+netconn);
			FRONTLIB.flib_metascheme_release(scheme);
		} catch (FileNotFoundException e) {
			throw new RuntimeException(e);
		}
        
    	FRONTLIB.flib_netconn_onConnected(netconn, handleNetConnected, null);
    	FRONTLIB.flib_netconn_onDisconnected(netconn, handleNetDisconnect, null);
    	FRONTLIB.flib_netconn_onChat(netconn, handleChat, null);
    	FRONTLIB.flib_netconn_onMessage(netconn, handleMessage, null);
    	timer = new CountDownTimer(100000000, 100) {
			@Override
			public void onTick(long millisUntilFinished) {
				if(!disconnected) {
					FRONTLIB.flib_netconn_tick(netconn);
				}
			}
			
			@Override
			public void onFinish() {
			}
		};
		timer.start();
    }

    @Override
    protected void onPause() {
    	super.onPause();
    	FRONTLIB.flib_netconn_send_quit(netconn, "Activity paused");
    }
    
    private JnaFrontlib.VoidCallback handleNetConnected = new JnaFrontlib.VoidCallback() {
		public void callback(Pointer context) {
			textView.append("Connected. You can chat now.\n");
		}
	};
	
    private JnaFrontlib.IntStrCallback handleNetDisconnect = new JnaFrontlib.IntStrCallback() {
		public void callback(Pointer context, int arg1, String arg2) {
			disconnected = true;
			timer.cancel();
			FRONTLIB.flib_netconn_destroy(netconn);
			netconn.setPointer(Pointer.NULL);
			textView.append("You have been disconnected.");
		}
	};
	
    private JnaFrontlib.StrStrCallback handleChat = new JnaFrontlib.StrStrCallback() {
		public void callback(Pointer context, String arg1, String arg2) {
			textView.append(arg1+": "+arg2+"\n");
		}
	};
	
    private JnaFrontlib.IntStrCallback handleMessage = new JnaFrontlib.IntStrCallback() {
		public void callback(Pointer context, int arg1, String arg2) {
			textView.append(Html.fromHtml(arg2+"<br/>"));
		}
	};
}
