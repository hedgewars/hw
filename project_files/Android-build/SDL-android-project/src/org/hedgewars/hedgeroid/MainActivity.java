/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011 Richard Deurwaarder <xeli@xelification.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

package org.hedgewars.hedgeroid;

import org.hedgewars.hedgeroid.Downloader.DownloadActivity;
import org.hedgewars.hedgeroid.Downloader.DownloadListActivity;
import org.hedgewars.hedgeroid.Downloader.DownloadService;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.Toast;

public class MainActivity extends Activity {

	Button downloader, startGame;
	
	public void onCreate(Bundle sis){
		super.onCreate(sis);
		setContentView(R.layout.main);
		
		downloader = (Button)findViewById(R.id.downloader);
		startGame = (Button)findViewById(R.id.startGame);
		
		downloader.setOnClickListener(downloadClicker);
		startGame.setOnClickListener(startGameClicker);
	}
	
	
	
	private OnClickListener downloadClicker = new OnClickListener(){
		public void onClick(View v){
			//startActivityForResult(new Intent(getApplicationContext(), DownloadActivity.class), 0);
			startActivityForResult(new Intent(getApplicationContext(), DownloadListActivity.class), 0);
		}
	};

	private OnClickListener startGameClicker = new OnClickListener(){
		public void onClick(View v){
			if(PreferenceManager.getDefaultSharedPreferences(MainActivity.this).getBoolean(DownloadService.PREF_DOWNLOADED, false))
				startActivity(new Intent(getApplicationContext(), StartGameActivity.class));
			else {
				Toast.makeText(MainActivity.this, R.string.download_userexplain, Toast.LENGTH_LONG).show();
				startActivityForResult(new Intent(getApplicationContext(), DownloadActivity.class), 0);
			}
		}
	};
	
}
