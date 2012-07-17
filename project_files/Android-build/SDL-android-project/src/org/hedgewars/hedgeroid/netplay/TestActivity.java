package org.hedgewars.hedgeroid.netplay;

import org.hedgewars.hedgeroid.R;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentPagerAdapter;
import android.support.v4.view.ViewPager;

public class TestActivity extends FragmentActivity {
	@Override
	protected void onCreate(Bundle arg0) {
		super.onCreate(arg0);
		setContentView(R.layout.activity_lobby);
		/*ViewPager pager = (ViewPager)findViewById(R.id.pager);
		pager.setAdapter(new Adapter(getSupportFragmentManager()));*/
	}
	
	/*private static class Adapter extends FragmentPagerAdapter {
		public Adapter(FragmentManager mgr) {
			super(mgr);
		}
		
		@Override
		public int getCount() {
			return 3;
		}
		
		@Override
		public Fragment getItem(int arg0) {
			switch(arg0) {
			case 0: return new RoomlistFragment();
			case 1: return new LobbyChatFragment();
			case 2: return new PlayerlistFragment();
			default: throw new IndexOutOfBoundsException();
			}
		}
	}*/
}
