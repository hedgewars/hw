package org.hedgewars.mobile.Downloader;

import org.hedgewars.mobile.MainActivity;
import org.hedgewars.mobile.R;

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
	private Handler.Callback messageCallback = new Handler.Callback() {
		
		@Override
		public boolean handleMessage(Message msg) {
			switch(msg.what){
			case MSG_START:
				progress.setMax(msg.arg1);
				progress_sub.setText(String.format("%dkb/%dkb\n%s", 0, msg.arg1, ""));
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
	
	public void onStart(){
		super.onStart();
		bindToService();
	}
	
	public void onStop(){
		super.onStop();
		unBindFromService();
	}
	
	private ServiceConnection connection = new ServiceConnection(){

		@Override
		public void onServiceConnected(ComponentName name, IBinder service) {
			messageService = new Messenger(service);
			
			try{
				Message msg = Message.obtain(null, DownloadService.MSG_REGISTER_CLIENT);
				msg.replyTo = messenger;
				messageService.send(msg);
				
			}catch (RemoteException e){}
		}

		@Override
		public void onServiceDisconnected(ComponentName name) {
			messageService = null;
		}
		
	};
	
	private void bindToService(){
		Intent i = new Intent(getApplicationContext(), DownloadService.class);
		i.putExtra("taskID", DownloadService.TASKID_START);
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
