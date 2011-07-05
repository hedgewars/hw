package org.hedgewars.mobile;

import java.io.File;
import java.util.ArrayList;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.os.RemoteException;
import android.util.Log;
import android.widget.RemoteViews;
import android.widget.Toast;

public class DownloadService extends Service {

	private final static String URL = "http://www.xelification.com/tmp/data.zip";
	public static final int MSG_CANCEL = 0;
	public static final int MSG_REGISTER_CLIENT = 1;
	public static final int MSG_UNREGISTER_CLIENT = 2;

	public static final int NOTIFICATION_PROCESSING = 0;
	public static final int NOTIFICATION_DONE = 1;

	private DownloadAsyncTask downloadTask;
	private final Messenger messenger = new Messenger(new DownloadHandler());
	private NotificationManager nM;
	private RemoteViews contentView;
	private Notification notification;

	private ArrayList<Messenger> clientList = new ArrayList<Messenger>();
	private Message onRegisterMessage = null;


	class DownloadHandler extends Handler{

		public void handleMessage(Message msg){
			switch(msg.what){
			case MSG_CANCEL:
				downloadTask.cancel(false);
				break;
			case MSG_REGISTER_CLIENT:
				clientList.add(msg.replyTo);
				if(onRegisterMessage != null){
					try {
						msg.replyTo.send(Message.obtain(onRegisterMessage));
					} catch (RemoteException e) {
						e.printStackTrace();
					}
				}
				break;
			case MSG_UNREGISTER_CLIENT:
				clientList.remove(msg.replyTo);
				break;
			}
		}
	}

	public final static int TASKID_START = 0;
	public final static int TASKID_CANCEL = 1;
	
	public int onStartCommand(Intent intent, int flags, int startId){
		switch(intent.getIntExtra("taskID", TASKID_START)){
		case TASKID_START:
			nM = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);

			notification = new Notification(R.drawable.statusbar, getString(R.string.notification_title), System.currentTimeMillis());
			//notification.flags |= Notification.FLAG_ONGOING_EVENT;// | Notification.FLAG_NO_CLEAR | Notification.FLAG_FOREGROUND_SERVICE;
			notification.flags |= Notification.FLAG_ONGOING_EVENT;

			contentView = new RemoteViews(getPackageName(), R.layout.notification);
			contentView.setProgressBar(R.id.notification_progress, 100, 34, false);
			notification.contentView = contentView;

			PendingIntent contentIntent = PendingIntent.getActivity(this, 0, new Intent(this, DownloadActivity.class), Intent.FLAG_ACTIVITY_NEW_TASK);
			notification.contentIntent = contentIntent;

			//nM.notify(NOTIFICATION_PROCESSING, notification);
			startForeground(NOTIFICATION_PROCESSING, notification);

			if(downloadTask == null){
				downloadTask = new DownloadAsyncTask(this);
				downloadTask.execute(getDownloadPath(this), URL);
			}	
			break;
		case TASKID_CANCEL:
			downloadTask.cancel(false);
			stopService();
			break;
		}		
		return 0;
	}

	public void onDestroy(){
		Log.e("bla", "onDestroy");
		downloadTask.cancel(false);	
	}

	public IBinder onBind(Intent intent) {
		return messenger.getBinder();
	}

	/*
	 * Thread safe method to let clients know the processing is starting and will process int max kbytes
	 * 
	 */
	public void start(int max){
		onRegisterMessage = Message.obtain(null, DownloadActivity.MSG_START, max, -1);
		sendMessageToClients(onRegisterMessage);
	}

	public void update(int progress, int max, String fileName){
		progress = (progress/1024);
		updateNotification(progress, max, fileName);

		sendMessageToClients(Message.obtain(null, DownloadActivity.MSG_UPDATE, progress, max, fileName));
	}
	public void done(boolean succesful){
		sendMessageToClients(Message.obtain(null, DownloadActivity.MSG_DONE));
		stopService();//stopService clears all notifications and thus must be called before we show the ready notification
		showDoneNotification();
	}

	private void stopService(){
		nM.cancelAll();
		stopForeground(true);
		stopSelf();
	}
	
	private void updateNotification(int progress, int max, String fileName){

		contentView.setProgressBar(R.id.notification_progress, max, progress, false);
		contentView.setTextViewText(R.id.progressbar_sub, String.format("%dkb/%dkb (Compressed sizes)", progress, max));
		nM.notify(NOTIFICATION_PROCESSING, notification);
	}

	private void showDoneNotification(){
		nM.cancelAll();
		stopForeground(true);

		String title = getString(R.string.notification_title);

		notification = new Notification(R.drawable.icon, title, System.currentTimeMillis());
		notification.flags |= Notification.FLAG_AUTO_CANCEL;
		PendingIntent contentIntent = PendingIntent.getActivity(this, 0, new Intent(this, MainActivity.class), Intent.FLAG_ACTIVITY_NEW_TASK);
		notification.setLatestEventInfo(this, title, getString(R.string.notification_done), contentIntent);
		nM.notify(NOTIFICATION_DONE, notification);
	}	
	private void sendMessageToClients(Message msg){
		for(Messenger m : clientList){
			try {
				m.send(Message.obtain(msg));
			} catch (RemoteException e) {}//TODO should we catch this properly?
		}
	}
	public static String getDownloadPath(Context c){
		File f =  c.getExternalCacheDir();
		if(f != null){
			return f.getAbsolutePath();
		}else{
			Toast.makeText(c, R.string.sdcard_not_mounted, Toast.LENGTH_LONG);
			return null;
		}
	}
}
