package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.StartGameActivity;
import org.hedgewars.hedgeroid.netplay.Netplay.State;
import org.hedgewars.hedgeroid.netplay.NetplayStateFragment.NetplayStateListener;
import org.hedgewars.hedgeroid.netplay.TextInputDialog.TextInputDialogListener;

import android.content.Context;
import android.content.Intent;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentTransaction;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TabHost;
import android.widget.TextView;

public class LobbyActivity extends FragmentActivity implements TextInputDialogListener, NetplayStateListener {
	private static final int DIALOG_CREATE_ROOM = 0;
	
    private TabHost tabHost;
    private Netplay netplay;
    
    @Override
    protected void onCreate(Bundle icicle) {
        super.onCreate(icicle);
        
        setContentView(R.layout.activity_lobby);
        ChatFragment chatFragment = (ChatFragment)getSupportFragmentManager().findFragmentById(R.id.chatFragment);
        chatFragment.setInRoom(false);
        
        FragmentTransaction trans = getSupportFragmentManager().beginTransaction();
        trans.add(new NetplayStateFragment(), "netplayFragment");
        trans.commit();
        
        netplay = Netplay.getAppInstance(getApplicationContext());
        
        tabHost = (TabHost)findViewById(android.R.id.tabhost);
        if(tabHost != null) {
	        tabHost.setup();
	        tabHost.getTabWidget().setOrientation(LinearLayout.VERTICAL);

	        tabHost.addTab(tabHost.newTabSpec("rooms").setIndicator(createIndicatorView(tabHost, R.string.lobby_tab_rooms, getResources().getDrawable(R.drawable.roomlist_ingame))).setContent(R.id.roomListFragment));
	        tabHost.addTab(tabHost.newTabSpec("chat").setIndicator(createIndicatorView(tabHost, R.string.lobby_tab_chat, getResources().getDrawable(R.drawable.edit))).setContent(R.id.chatFragment));
	        tabHost.addTab(tabHost.newTabSpec("players").setIndicator(createIndicatorView(tabHost, R.string.lobby_tab_players, getResources().getDrawable(R.drawable.human))).setContent(R.id.playerListFragment));
	
	        if (icicle != null) {
	            tabHost.setCurrentTabByTag(icicle.getString("currentTab"));
	        }
        }
    }
    
    private View createIndicatorView(TabHost tabHost, int label, Drawable icon) {
        LayoutInflater inflater = (LayoutInflater) getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        View tabIndicator = inflater.inflate(R.layout.tab_indicator,
                tabHost.getTabWidget(), // tab widget is the parent
                false); // no inflate params

        final TextView tv = (TextView) tabIndicator.findViewById(R.id.title);
        tv.setText(label);
        
        if(icon != null) {
	        final ImageView iconView = (ImageView) tabIndicator.findViewById(R.id.icon);
	        iconView.setImageDrawable(icon);
        }
        
        return tabIndicator;
    }
    
	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		super.onCreateOptionsMenu(menu);
		getMenuInflater().inflate(R.menu.lobby_options, menu);
		return true;
	}
	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		switch(item.getItemId()) {
		case R.id.room_create:
	        TextInputDialog dialog = new TextInputDialog(DIALOG_CREATE_ROOM, R.string.dialog_create_room_title, 0, R.string.dialog_create_room_hint);
	        dialog.show(getSupportFragmentManager(), "create_room_dialog");
			return true;
		case R.id.disconnect:
			netplay.disconnect();
			return true;
		default:
			return super.onOptionsItemSelected(item);
		}
	}
	
	@Override
	public void onBackPressed() {
		super.onBackPressed();
		netplay.disconnect();
	}
	
    @Override
    protected void onSaveInstanceState(Bundle icicle) {
        super.onSaveInstanceState(icicle);
        if(tabHost != null) {
        	icicle.putString("currentTab", tabHost.getCurrentTabTag());
        }
    }
    
    public void onTextInputDialogSubmitted(int dialogId, String text) {
    	if(text != null && text.length()>0) {
    		netplay.sendCreateRoom(text);
    	}
    }
    
    public void onTextInputDialogCancelled(int dialogId) {
    }
    
    public void onNetplayStateChanged(State newState) {
    	switch(newState) {
    	case CONNECTING:
    	case NOT_CONNECTED:
    		finish();
    		break;
    	case ROOM:
    	case INGAME:
    		startActivity(new Intent(getApplicationContext(), RoomActivity.class));
    		break;
    	case LOBBY:
    		// Do nothing
    		break;
		default:
			throw new IllegalStateException("Unknown connection state: "+newState);
    	}
    }
}
