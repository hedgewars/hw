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


package org.hedgewars.hedgeroid.Downloader;

import org.hedgewars.hedgeroid.MainActivity;
import org.hedgewars.hedgeroid.R;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.os.RemoteException;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.TextView;

public class DownloadActivity extends Activity{
	private Messenger messageService;
	private boolean boundToService = false;
	
	private TextView progress_sub;
	private ProgressBar progress;
	private Button positive, negative;
	
	public static final int MSG_START = 0;
	public static final int MSG_UPDATE = 1;
	public static final int MSG_DONE = 2;
	public static final int MSG_FAILED = 3;
	private Handler.Callback messageCallback = new Handler.Callback() {
		
		public boolean handleMessage(Message msg) {
			switch(msg.what){
			case MSG_START:
				progress.setMax(msg.arg1);
				progress_sub.setText(String.format("%dkb/%dkb\n%s", 0, msg.arg1, ""));
				positive.setText(R.string.download_background);
				positive.setOnClickListener(backgroundClicker);
				negative.setText(R.string.download_cancel);
				negative.setOnClickListener(cancelClicker);
				break;
			case MSG_UPDATE:
				progress_sub.setText(String.format("%d%% - %dkb/%dkb\n%s",(msg.arg1*100)/msg.arg2, msg.arg1, msg.arg2, msg.obj));
				progress.setProgress(msg.arg1);
				break;
			case MSG_DONE:
				progress.setProgress(progress.getMax());
				progress_sub.setText(R.string.download_done);
				
				positive.setText(R.string.download_back);
				positive.setOnClickListener(doneClicker);
				
				negative.setVisibility(View.INVISIBLE);
				break;
			case MSG_FAILED:
				progress.setProgress(progress.getMax());
				progress_sub.setText(R.string.download_failed);
				positive.setText(R.string.download_back);
				positive.setOnClickListener(doneClicker);
				
				negative.setText(R.string.download_tryagain);
				negative.setOnClickListener(tryAgainClicker);
				break;
			}
			return false;
		}
	};
	private Handler messageHandler = new Handler(messageCallback);
	private Messenger messenger = new Messenger(messageHandler);
	
	public void onCreate(Bundle savedInstanceState){
		super.onCreate(savedInstanceState);
		setContentView(R.layout.download);
		
		progress_sub = (TextView)findViewById(R.id.progressbar_sub);
		progress = (ProgressBar)findViewById(R.id.progressbar);
		
		positive = (Button) findViewById(R.id.background);
		negative = (Button) findViewById(R.id.cancelDownload);
		positive.setOnClickListener(backgroundClicker);
		negative.setOnClickListener(cancelClicker);
		
	}
	
	private OnClickListener backgroundClicker = new OnClickListener(){
		public void onClick(View v){
			finish();
		}
	};
	private OnClickListener cancelClicker = new OnClickListener(){
		public void onClick(View v){
			Intent i = new Intent(getApplicationContext(), DownloadService.class);
			i.putExtra("taskID", DownloadService.TASKID_CANCEL);
			startService(i);
			finish();
		}
	};
	private OnClickListener doneClicker = new OnClickListener(){
		public void onClick(View v){
			finish();
			startActivity(new Intent(getApplicationContext(), MainActivity.class));
		}
	};
	
	private OnClickListener tryAgainClicker = new OnClickListener(){
		public void onClick(View v){
			bindToService(DownloadService.TASKID_RETRY);
		}
	};
	
	public void onStart(){
		super.onStart();
		bindToService(DownloadService.TASKID_START);
	}
	
	public void onStop(){
		super.onStop();
		unBindFromService();
	}
	
	private ServiceConnection connection = new ServiceConnection(){

		public void onServiceConnected(ComponentName name, IBinder service) {
			messageService = new Messenger(service);
			
			try{
				Message msg = Message.obtain(null, DownloadService.MSG_REGISTER_CLIENT);
				msg.replyTo = messenger;
				messageService.send(msg);
				
			}catch (RemoteException e){}
		}

		public void onServiceDisconnected(ComponentName name) {
			messageService = null;
		}
		
	};
	
	private void bindToService(int taskId){
		Intent i = new Intent(getApplicationContext(), DownloadService.class);
		i.putExtra("taskID", taskId);
		startService(i);
		bindService(new Intent(getApplicationContext(), DownloadService.class), connection, Context.BIND_AUTO_CREATE);
		boundToService = true;
	}
	
	private void unBindFromService(){
		if(boundToService){
			boundToService = false;
			unbindService(connection);
		}	
	}
}
