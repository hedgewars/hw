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

import org.hedgewars.hedgeroid.R;

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
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.TextView;

public class DownloadFragment extends Fragment{
    public static final String EXTRA_TASK = "task";

    public static final int MSG_START = 0;
    public static final int MSG_UPDATE = 1;
    public static final int MSG_DONE = 2;
    public static final int MSG_FAILED = 3;

    private boolean boundToService = false;

    private TextView progress_sub;
    private ProgressBar progress;
    private Button /*positive,*/ negative;

    private DownloadPackage pack;

    private Handler messageHandler;
    private Messenger messenger, messengerService;

    public static DownloadFragment getInstance(DownloadPackage task){
        DownloadFragment df = new DownloadFragment();
        Bundle args = new Bundle();
        args.putParcelable(DownloadFragment.EXTRA_TASK, task);

        df.setArguments(args);

        return df;
    }

    public void onActivityCreated(Bundle savedInstanceState){
        super.onActivityCreated(savedInstanceState);

        messageHandler = new Handler(messageCallback);
        messenger = new Messenger(messageHandler);
        Intent i = new Intent(getActivity().getApplicationContext(), DownloadService.class);
        getActivity().startService(i);
        getActivity().bindService(new Intent(getActivity().getApplicationContext(), DownloadService.class), connection, Context.BIND_AUTO_CREATE);
    }

    public View onCreateView(LayoutInflater inflater, ViewGroup viewgroup, Bundle savedInstanceState){
        View v = inflater.inflate(R.layout.download_progress, viewgroup, false);
        progress_sub = (TextView)v.findViewById(R.id.progressbar_sub);
        progress = (ProgressBar)v.findViewById(R.id.progressbar);

        //positive = (Button) v.findViewById(R.id.background);
        negative = (Button) v.findViewById(R.id.cancelDownload);
        //positive.setOnClickListener(backgroundClicker);
        negative.setOnClickListener(cancelClicker);

        pack = getArguments().getParcelable(DownloadFragment.EXTRA_TASK);

        return v;
    }

    private OnClickListener backgroundClicker = new OnClickListener(){
        public void onClick(View v){
            getActivity().finish();
        }
    };
    private OnClickListener cancelClicker = new OnClickListener(){
        public void onClick(View v){
            if(messengerService != null){
                Message message = Message.obtain(messageHandler, DownloadService.MSG_CANCEL, pack);
                try {
                    messengerService.send(message);
                } catch (RemoteException e) {}
            }
            //getActivity().finish();
        }
    };
    private OnClickListener doneClicker = new OnClickListener(){
        public void onClick(View v){
            getActivity().finish();
        }
    };

    private OnClickListener tryAgainClicker = new OnClickListener(){
        public void onClick(View v){
            if(messengerService != null){
                Message message = Message.obtain(messageHandler, DownloadService.MSG_ADDTASK, pack);
                message.replyTo = messenger;
                try {
                    messengerService.send(message);
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
            }
        }
    };

    public void onDestroy(){
        unBindFromService();
        super.onDestroy();
    }

    private ServiceConnection connection = new ServiceConnection(){

        public void onServiceConnected(ComponentName name, IBinder service) {
            messengerService = new Messenger(service);

            try{
                //give the service a task
                if(messengerService != null){
                    Message message = Message.obtain(messageHandler, DownloadService.MSG_ADDTASK, pack);
                    message.replyTo = messenger;
                    messengerService.send(message);
                }

            }catch (RemoteException e){}
        }

        public void onServiceDisconnected(ComponentName name) {
            messengerService = null;
        }

    };

    public void unBindFromService(){
        if(messengerService != null){
            try {
                Message message = Message.obtain(messageHandler, DownloadService.MSG_UNREGISTER_CLIENT, pack);
                message.replyTo = messenger;
                messengerService.send(message);
            } catch (RemoteException e) {
                e.printStackTrace();
            }
        }

        getActivity().unbindService(connection);
    }

    private Handler.Callback messageCallback = new Handler.Callback() {

        public boolean handleMessage(Message msg) {
            switch(msg.what){
            case MSG_START:
                progress.setMax(msg.arg1);
                progress_sub.setText(String.format("%dkb/%dkb\n%s", 0, msg.arg1, ""));
                //positive.setText(R.string.download_background);
                //positive.setOnClickListener(backgroundClicker);
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

                //  positive.setText(R.string.download_back);
                //  positive.setOnClickListener(doneClicker);

                negative.setVisibility(View.INVISIBLE);
                break;
            case MSG_FAILED:
                progress.setProgress(progress.getMax());

                String errorMsg = getString(R.string.download_failed);
                switch(msg.arg1){
                case DownloadAsyncTask.EXIT_CONNERROR: progress_sub.setText(errorMsg + " " + "Connection error"); break;
                case DownloadAsyncTask.EXIT_FNF: progress_sub.setText(errorMsg + " " + "File not found"); break;
                case DownloadAsyncTask.EXIT_MD5: progress_sub.setText(errorMsg + " " + "MD5 check failed"); break;
                case DownloadAsyncTask.EXIT_URLFAIL: progress_sub.setText(errorMsg + " " + "Invalid url"); break;
                }
                negative.setText(R.string.download_tryagain);
                negative.setOnClickListener(tryAgainClicker);
                break;
            }
            return false;
        }
    };

}
