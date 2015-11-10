/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011-2012 Richard Deurwaarder <xeli@xelification.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

package org.hedgewars.hedgeroid.Downloader;

import java.util.LinkedList;
import java.util.List;

import org.hedgewars.hedgeroid.R;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.os.RemoteException;
import android.widget.RemoteViews;

public class DownloadService extends Service {
    public final static String INTENT_TASKID = "taskId";
    public final static String INTENT_TASK = "task";

    public static final String PREF_DOWNLOADED = "downloaded";
    public static final int MSG_CANCEL = 0;
    public static final int MSG_UNREGISTER_CLIENT = 2;
    public final static int MSG_ADDTASK = 4;

    public static final int NOTIFICATION_PROCESSING = 0;
    public static final int NOTIFICATION_DONE = 1;

    private DownloadAsyncTask asyncExecutor;

    private DownloadHandler handler = new DownloadHandler();
    private final Messenger messenger = new Messenger(handler);

    private NotificationManager nM;
    private RemoteViews contentView;

    private LinkedList<DownloadTask> downloadTasks = new LinkedList<DownloadTask>();
    private DownloadTask currentTask = null;

    public class DownloadHandler extends Handler{

        public void handleMessage(Message msg){
            if(msg.obj != null){
                DownloadPackage pack = (DownloadPackage) msg.obj;
                DownloadTask task = null;
                Messenger replyToMessenger = msg.replyTo;
                for(DownloadTask _task : downloadTasks){
                    if(_task.getPackage().equals(pack)){
                        task = _task;
                        break;
                    }
                }

                switch(msg.what){
                case MSG_ADDTASK:
                    if(task == null){
                        task = new DownloadTask(pack);
                        downloadTasks.add(task);
                    }

                    task.addClient(replyToMessenger);
                    runNextTask();
                    return;
                case MSG_CANCEL:
                    if(task != null && task.getPackage().equals(pack) && task.getStatus() == TASK_STATE.PENDING){
                        downloadTasks.remove(task);
                    }
                    if(currentTask != null && currentTask.getPackage().equals(pack)){//TODO synchronization problem?
                        asyncExecutor.cancel(false);
                    }
                    return;
                case MSG_UNREGISTER_CLIENT:
                    if(task != null){
                        task.removeClient(replyToMessenger);
                    }
                    return;
                }
            }
        }
    }

    public void onCreate(){
        super.onCreate();
        nM = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
    }
    public IBinder onBind(Intent intent) {
        return messenger.getBinder();
    }

    private void runNextTask(){
        if(asyncExecutor == null){//if (task isnt running right now) ...
            currentTask = downloadTasks.poll();
            if(currentTask != null){
                asyncExecutor = new DownloadAsyncTask(currentTask);
                asyncExecutor.execute(currentTask.getPackage());
            }
        }
    }

    public void onDestroy(){
        super.onDestroy();
        asyncExecutor.cancel(false);
    }

    class DownloadTask {
        private final DownloadPackage pack;
        private TASK_STATE status = TASK_STATE.PENDING;
        private Notification progressNotification, doneNotification;

        //I expect little to no removeClient calls that's why we go for a list rather than a map
        private final List<Messenger> clients;

        public DownloadTask(DownloadPackage _pack){
            pack = _pack;
            clients = new LinkedList<Messenger>();
        }

        public void addClient(Messenger messenger){
            clients.add(messenger);
        }
        public void removeClient(Messenger messenger){
            clients.remove(messenger);
        }

        public DownloadPackage getPackage(){
            return pack;
        }

        public TASK_STATE getStatus(){
            return status;
        }

        public void sendMessageToClients(Message msg){
            for(Messenger messenger : clients){
                try {
                    messenger.send(msg);
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
            }
        }

        /*
         * Callbacks called from the async tasks
         */

        //Thread safe method to let clients know the processing is starting and will process int max kbytes
        public void start(int max){
            progressNotification = new Notification(R.drawable.statusbar, getString(R.string.notification_title), System.currentTimeMillis());
            progressNotification.flags |= Notification.FLAG_ONGOING_EVENT;

            contentView = new RemoteViews(getPackageName(), R.layout.notification);
            contentView.setProgressBar(R.id.notification_progress, 100, 34, false);
            progressNotification.contentView = contentView;

            PendingIntent contentIntent = PendingIntent.getActivity(DownloadService.this, 0, new Intent(DownloadService.this, DownloadListActivity.class), Intent.FLAG_ACTIVITY_NEW_TASK);
            progressNotification.contentIntent = contentIntent;

            startForeground(NOTIFICATION_PROCESSING, progressNotification);

            Message msg = Message.obtain(null, DownloadFragment.MSG_START, max, 0);
            sendMessageToClients(msg);
        }

        //periodically gets called by the ASyncTask, we can't tell for sure when it's called
        public void update(int progress, int max, String fileName){
            progress = (progress/1024);

            contentView.setProgressBar(R.id.notification_progress, max, progress, false);
            contentView.setTextViewText(R.id.progressbar_sub, String.format("%dkb/%dkb (Compressed sizes)", progress, max));
            nM.notify(NOTIFICATION_PROCESSING, progressNotification);

            sendMessageToClients(Message.obtain(handler, DownloadFragment.MSG_UPDATE, progress, max, fileName));
        }

        //Call back from the ASync task when the task has either run into an error or finished otherwise
        public void done(int result){
            switch(result){
            case DownloadAsyncTask.EXIT_SUCCESS:    sendMessageToClients(Message.obtain(handler, DownloadFragment.MSG_DONE)); break;
            case DownloadAsyncTask.EXIT_CONNERROR:  sendMessageToClients(Message.obtain(handler, DownloadFragment.MSG_FAILED, DownloadAsyncTask.EXIT_CONNERROR, 0)); break;
            case DownloadAsyncTask.EXIT_FNF:        sendMessageToClients(Message.obtain(handler, DownloadFragment.MSG_FAILED, DownloadAsyncTask.EXIT_FNF, 0)); break;
            case DownloadAsyncTask.EXIT_MD5:        sendMessageToClients(Message.obtain(handler, DownloadFragment.MSG_FAILED, DownloadAsyncTask.EXIT_MD5, 0)); break;
            case DownloadAsyncTask.EXIT_URLFAIL:    sendMessageToClients(Message.obtain(handler, DownloadFragment.MSG_FAILED, DownloadAsyncTask.EXIT_URLFAIL, 0)); break;
            case DownloadAsyncTask.EXIT_CANCELLED:  sendMessageToClients(Message.obtain(handler, DownloadFragment.MSG_DONE)); break;
            }

            stopForeground(true);
            nM.cancel(NOTIFICATION_PROCESSING);

            String title = getString(R.string.notification_title);

            doneNotification = new Notification(R.drawable.icon, title, System.currentTimeMillis());
            doneNotification.flags |= Notification.FLAG_AUTO_CANCEL;
            PendingIntent contentIntent = PendingIntent.getActivity(DownloadService.this, 0, new Intent(DownloadService.this, DownloadListActivity.class), Intent.FLAG_ACTIVITY_NEW_TASK);
            doneNotification.setLatestEventInfo(DownloadService.this, title, getString(R.string.notification_done) + pack, contentIntent);
            nM.notify(pack.getId(), doneNotification);

            asyncExecutor = null;
            runNextTask();//see if there are more tasks
        }

    }

    enum TASK_STATE{
        RUNNING, FINISHED, PENDING;
    }

}
