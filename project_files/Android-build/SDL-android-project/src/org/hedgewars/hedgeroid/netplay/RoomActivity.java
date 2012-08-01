package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.netplay.JnaFrontlib.NetconnPtr;

import android.content.IntentFilter;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.support.v4.content.LocalBroadcastManager;
import android.widget.LinearLayout;
import android.widget.TabHost;

public class RoomActivity extends FragmentActivity {
	private TabHost tabHost;
	private Netplay netconn;
	
    @Override
    protected void onCreate(Bundle icicle) {
        super.onCreate(icicle);
        netconn = Netplay.getAppInstance(getApplicationContext());
        
        setContentView(R.layout.activity_lobby);
        Fragment chatFragment = getSupportFragmentManager().findFragmentById(R.id.chatFragment);
        chatFragment.getArguments().putBoolean(ChatFragment.ARGUMENT_INROOM, true);
        
        tabHost = (TabHost)findViewById(android.R.id.tabhost);
        if(tabHost != null) {
	        tabHost.setup();
	        tabHost.getTabWidget().setOrientation(LinearLayout.VERTICAL);

	        //tabHost.addTab(tabHost.newTabSpec("chat").setIndicator(createIndicatorView(tabHost, R.string.lobby_tab_chat, getResources().getDrawable(R.drawable.edit))).setContent(R.id.chatFragment));
	        //tabHost.addTab(tabHost.newTabSpec("players").setIndicator(createIndicatorView(tabHost, R.string.lobby_tab_players, getResources().getDrawable(R.drawable.human))).setContent(R.id.playerListFragment));
	
	        if (icicle != null) {
	            tabHost.setCurrentTabByTag(icicle.getString("currentTab"));
	        }
        }
    }

    @Override
    protected void onSaveInstanceState(Bundle icicle) {
        super.onSaveInstanceState(icicle);
        if(tabHost != null) {
        	icicle.putString("currentTab", tabHost.getCurrentTabTag());
        }
    }
}
