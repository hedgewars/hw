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

import android.app.AlertDialog;
import android.app.AlertDialog.Builder;
import android.app.Dialog;
import android.content.DialogInterface;
import android.content.DialogInterface.OnClickListener;
import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.DialogFragment;

public class DownloadDialogFragment extends DialogFragment {

    public static final int NUM_ALREADYDOWNLOADED = 0;
    public static final int NUM_AREYOUSURE = 1;

    private final static String BUNDLE_TASK = "task";

    static DownloadDialogFragment newInstance(DownloadPackage task){
        DownloadDialogFragment dialog = new DownloadDialogFragment();

        Bundle args = new Bundle();
        args.putParcelable(DownloadDialogFragment.BUNDLE_TASK, task);
        dialog.setArguments(args);

        return dialog;
    }

    public Dialog onCreateDialog(Bundle savedInstanceState){
        DownloadPackage task = (DownloadPackage)getArguments().getParcelable(DownloadDialogFragment.BUNDLE_TASK);

        Builder builder = new AlertDialog.Builder(getActivity());

        switch(task.getStatus()){
        case CURRENTVERSION:
        case NEWERVERSION:
            builder.setMessage(R.string.download_areyousure);
            break;
        case OLDERVERSION:
            builder.setMessage(R.string.download_alreadydownloaded);
            break;
        }

        DownloadClicker clicker = new DownloadClicker(task);
        builder.setPositiveButton(android.R.string.yes, clicker);
        builder.setNegativeButton(android.R.string.no, clicker);

        return builder.create();
    }

    class DownloadClicker implements OnClickListener{

        DownloadPackage task = null;

        public DownloadClicker(DownloadPackage _task){
            task = _task;
        }

        public void onClick(DialogInterface dialog, int which) {
            if(which == Dialog.BUTTON_POSITIVE){
                Intent i = new Intent(getActivity(), DownloadListActivity.class);
                i.putExtra(DownloadFragment.EXTRA_TASK, task);
                getActivity().startActivity(i);
            }
        }
    }
}
