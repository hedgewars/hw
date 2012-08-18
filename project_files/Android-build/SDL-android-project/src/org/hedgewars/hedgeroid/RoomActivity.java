package org.hedgewars.hedgeroid;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.NetplayStateFragment.NetplayStateListener;
import org.hedgewars.hedgeroid.netplay.Netplay;
import org.hedgewars.hedgeroid.netplay.Netplay.State;

import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentTransaction;
import android.widget.TabHost;
import android.widget.Toast;

public class RoomActivity extends FragmentActivity implements NetplayStateListener, TeamAddDialog.Listener, RoomStateManager.Provider {
	private TabHost tabHost;
	private Netplay netplay;
	
    @Override
    protected void onCreate(Bundle icicle) {
        super.onCreate(icicle);
        netplay = Netplay.getAppInstance(getApplicationContext());
        
        setContentView(R.layout.activity_netroom);
        ChatFragment chatFragment = (ChatFragment)getSupportFragmentManager().findFragmentById(R.id.chatFragment);
        chatFragment.setInRoom(true);
        
        FragmentTransaction trans = getSupportFragmentManager().beginTransaction();
        trans.add(new NetplayStateFragment(), "netplayFragment");
        trans.commit();
        
        /*tabHost = (TabHost)findViewById(android.R.id.tabhost);
        if(tabHost != null) {
	        tabHost.setup();
	        tabHost.getTabWidget().setOrientation(LinearLayout.VERTICAL);

	        //tabHost.addTab(tabHost.newTabSpec("chat").setIndicator(createIndicatorView(tabHost, R.string.lobby_tab_chat, getResources().getDrawable(R.drawable.edit))).setContent(R.id.chatFragment));
	        //tabHost.addTab(tabHost.newTabSpec("players").setIndicator(createIndicatorView(tabHost, R.string.lobby_tab_players, getResources().getDrawable(R.drawable.human))).setContent(R.id.playerListFragment));
	
	        if (icicle != null) {
	            tabHost.setCurrentTabByTag(icicle.getString("currentTab"));
	        }
        }*/
    }

	@Override
	public void onBackPressed() {
		netplay.sendLeaveRoom(null);
	}
    
    @Override
    protected void onSaveInstanceState(Bundle icicle) {
        super.onSaveInstanceState(icicle);
        if(tabHost != null) {
        	icicle.putString("currentTab", tabHost.getCurrentTabTag());
        }
    }
    
    public void onNetplayStateChanged(State newState) {
    	switch(newState) {
    	case NOT_CONNECTED:
    	case CONNECTING:
    	case LOBBY:
    		finish();
    		break;
    	case ROOM:
    		// Do nothing
    		break;
    	case INGAME:
    		//startActivity(new Intent(getApplicationContext(), RoomActivity.class));
    		Toast.makeText(getApplicationContext(), R.string.not_implemented_yet, Toast.LENGTH_SHORT).show();
    		break;
		default:
			throw new IllegalStateException("Unknown connection state: "+newState);
    	}
    }
    
	public void onTeamAddDialogSubmitted(Team newTeam) {
		netplay.sendAddTeam(newTeam, TeamInGame.getUnusedOrRandomColorIndex(netplay.roomTeamlist.getMap().values()));
	}
	
	public RoomStateManager getRoomStateManager() {
		return netplay.getRoomStateManager();
	}
}
