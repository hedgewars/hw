package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.R;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.support.v4.content.LocalBroadcastManager;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TabHost;
import android.widget.TextView;
import android.widget.Toast;

public class LobbyActivity extends FragmentActivity {
    private TabHost tabHost;
    private Netplay netconn;
    private boolean isInForeground;
    
    private final BroadcastReceiver disconnectReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			if(isInForeground && intent.getBooleanExtra(Netplay.EXTRA_HAS_ERROR, true)) {
				String message = intent.getStringExtra(Netplay.EXTRA_MESSAGE);
				Toast.makeText(getApplicationContext(), "Disconnected: "+message, Toast.LENGTH_LONG).show();
			}
			finish();
		}
	};
    
    @Override
    protected void onCreate(Bundle icicle) {
        super.onCreate(icicle);
        LocalBroadcastManager.getInstance(getApplicationContext()).registerReceiver(disconnectReceiver, new IntentFilter(Netplay.ACTION_DISCONNECTED));
        netconn = Netplay.getAppInstance(getApplicationContext());
        
        setContentView(R.layout.activity_lobby);
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
    
    @Override
    protected void onDestroy() {
    	super.onDestroy();
    	LocalBroadcastManager.getInstance(getApplicationContext()).unregisterReceiver(disconnectReceiver);
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
    protected void onStart() {
    	super.onStart();
    	isInForeground = true;
    	Netplay.getAppInstance(getApplicationContext()).requestFastTicks();
    }
    
    @Override
    protected void onStop() {
    	super.onStop();
    	isInForeground = false;
    	Netplay.getAppInstance(getApplicationContext()).unrequestFastTicks();
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
			Toast.makeText(this, R.string.not_implemented_yet, Toast.LENGTH_SHORT).show();
			return true;
		case R.id.disconnect:
			netconn.disconnect();
			return true;
		default:
			return super.onOptionsItemSelected(item);
		}
	}
	
	@Override
	public void onBackPressed() {
		netconn.disconnect();
		super.onBackPressed();
	}
	
    @Override
    protected void onSaveInstanceState(Bundle icicle) {
        super.onSaveInstanceState(icicle);
        if(tabHost != null) {
        	icicle.putString("currentTab", tabHost.getCurrentTabTag());
        }
    }
}
