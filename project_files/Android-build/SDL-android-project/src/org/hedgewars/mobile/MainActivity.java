package org.hedgewars.mobile;

import org.hedgewars.mobile.Downloader.DownloadActivity;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;

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
			startActivityForResult(new Intent(getApplicationContext(), DownloadActivity.class), 0);
		}
	};

	private OnClickListener startGameClicker = new OnClickListener(){
		public void onClick(View v){
			startActivity(new Intent(getApplicationContext(), StartGameActivity.class));
		}
	};
	
}
