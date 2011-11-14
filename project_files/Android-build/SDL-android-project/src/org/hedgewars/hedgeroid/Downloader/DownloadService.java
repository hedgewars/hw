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

import java.util.ArrayList;
import java.util.LinkedList;

import org.hedgewars.hedgeroid.MainActivity;
import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Utils;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.os.RemoteException;
import android.preference.PreferenceManager;
import android.util.Log;
import android.widget.RemoteViews;

public class DownloadService extends Service {

	public final static int TASKID_SETUP = 0;
	public final static int TASKID_CANCEL = 1;
	public final static int TASKID_ADDTASK = 2;

	public final static String INTENT_TASKID = "taskId";
	public final static String INTENT_TASK = "task";

	public static final String PREF_DOWNLOADED = "downloaded";
	public static final int MSG_CANCEL = 0;
	public static final int MSG_REGISTER_CLIENT = 1;
	public static final int MSG_UNREGISTER_CLIENT = 2;

	public static final int NOTIFICATION_PROCESSING = 0;
	public static final int NOTIFICATION_DONE = 1;

	private DownloadAsyncTask asyncExecutor;
	private final Messenger messenger = new Messenger(new DownloadHandler());
	private NotificationManager nM;
	private RemoteViews contentView;
	private Notification notification;

	private LinkedList<DownloadTask> downloadTasks = new LinkedList<DownloadTask>();
	private ArrayList<Messenger> clientList = new ArrayList<Messenger>();
	private Message onRegisterMessage = null;


	class DownloadHandler extends Handler{

		public void handleMessage(Message msg){
			switch(msg.what){
			case MSG_CANCEL:
				asyncExecutor.cancel(false);
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
	public IBinder onBind(Intent intent) {
		return messenger.getBinder();
	}

	/**
	 * This is the main method which controls how DownloadService and DownloadAsyncTask are running
	 */
	public int onStartCommand(Intent intent, int flags, int startId){
		switch(intent.getIntExtra("taskID", TASKID_SETUP)){
		case TASKID_SETUP:
			nM = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);

			notification = new Notification(R.drawable.statusbar, getString(R.string.notification_title), System.currentTimeMillis());
			notification.flags |= Notification.FLAG_ONGOING_EVENT;

			contentView = new RemoteViews(getPackageName(), R.layout.notification);
			contentView.setProgressBar(R.id.notification_progress, 100, 34, false);
			notification.contentView = contentView;

			PendingIntent contentIntent = PendingIntent.getActivity(this, 0, new Intent(this, DownloadActivity.class), Intent.FLAG_ACTIVITY_NEW_TASK);
			notification.contentIntent = contentIntent;

			asyncExecutor = new DownloadAsyncTask(this);
			break;
		case TASKID_ADDTASK:
			//Add downloadtask to the queue
			DownloadTask task = intent.getParcelableExtra(DownloadService.INTENT_TASK);
			downloadTasks.offer(task);
			runNextTask();
			break;
		case TASKID_CANCEL:
			asyncExecutor.cancel(false);
			break;
		}		
		return 0;
	}

	private synchronized void runNextTask(){
		if(!asyncExecutor.getStatus().equals(AsyncTask.Status.RUNNING)){//if the task isnt running right now...
			DownloadTask task = downloadTasks.poll();
			if(task == null){
				startForeground(NOTIFICATION_PROCESSING, notification);
				asyncExecutor.execute(task);
			}
		}
	}

	public void onDestroy(){
		super.onDestroy();
		asyncExecutor.cancel(false);	
	}

	/*
	 * Callbacks called from the async tasks
	 */

	//Thread safe method to let clients know the processing is starting and will process int max kbytes
	public void start(int max){
		onRegisterMessage = Message.obtain(null, DownloadActivity.MSG_START, max, -1);
		sendMessageToClients(onRegisterMessage);
	}

	//periodically gets called by the ASyncTask, we can't tell for sure when it's called
	public void update(int progress, int max, String fileName){
		progress = (progress/1024);
		updateNotification(progress, max, fileName);

		sendMessageToClients(Message.obtain(null, DownloadActivity.MSG_UPDATE, progress, max, fileName));
	}

	//Call back from the ASync task when the task has either run into an error or finished otherwise
	public void done(boolean succesful){
		if(succesful){
			sendMessageToClients(Message.obtain(null, DownloadActivity.MSG_DONE));
		}else sendMessageToClients(Message.obtain(null, DownloadActivity.MSG_FAILED));
		nM.cancel(NOTIFICATION_PROCESSING);
		stopForeground(true);
		showDoneNotification();
		runNextTask();//see if there are more tasks
	}


	private void updateNotification(int progress, int max, String fileName){

		contentView.setProgressBar(R.id.notification_progress, max, progress, false);
		contentView.setTextViewText(R.id.progressbar_sub, String.format("%dkb/%dkb (Compressed sizes)", progress, max));
		nM.notify(NOTIFICATION_PROCESSING, notification);
	}

	private void showDoneNotification(){
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

}
