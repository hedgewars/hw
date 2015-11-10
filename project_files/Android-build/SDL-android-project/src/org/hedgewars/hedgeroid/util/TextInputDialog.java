/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (C) 2012 Simeon Maxein <smaxein@googlemail.com>
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

package org.hedgewars.hedgeroid.util;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.support.v4.app.DialogFragment;
import android.view.KeyEvent;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;

/**
 * A generic text input dialog with configurable text. The Activity must implement the callback
 * interface TextInputDialogListener, which will be called by the dialog if it is submitted or cancelled.
 */
public class TextInputDialog extends DialogFragment {
    private static final String BUNDLE_DIALOG_ID = "dialogId";
    private static final String BUNDLE_TITLE_TEXT = "title";
    private static final String BUNDLE_MESSAGE_TEXT = "message";
    private static final String BUNDLE_HINT_TEXT = "hint";

    private int dialogId, titleText, messageText, hintText;
    private TextInputDialogListener listener;

    public interface TextInputDialogListener {
        void onTextInputDialogSubmitted(int dialogId, String text);
        void onTextInputDialogCancelled(int dialogId);
    }

    /**
     * The dialogId is only used for passing back to the callback on the activity, the
     * other parameters are text resource IDs. Pass 0 for any of them to not use this
     * text.
     */
    public TextInputDialog(int dialogId, int titleText, int messageText, int hintText) {
        this.dialogId = dialogId;
        this.titleText = titleText;
        this.messageText = messageText;
        this.hintText = hintText;
    }

    public TextInputDialog() {
        // Only for reflection-based instantiation by the framework
    }

    @Override
    public void onAttach(Activity activity) {
        super.onAttach(activity);
        try {
            listener = (TextInputDialogListener) activity;
        } catch(ClassCastException e) {
            throw new ClassCastException("Activity " + activity + " must implement TextInputDialogListener to use TextInputDialog.");
        }
    }

    @Override
    public void onDetach() {
        super.onDetach();
        listener = null;
    }

    @Override
    public Dialog onCreateDialog(Bundle savedInstanceState) {
        if(savedInstanceState != null) {
            dialogId = savedInstanceState.getInt(BUNDLE_DIALOG_ID, dialogId);
            titleText = savedInstanceState.getInt(BUNDLE_TITLE_TEXT, titleText);
            messageText = savedInstanceState.getInt(BUNDLE_MESSAGE_TEXT, messageText);
            hintText = savedInstanceState.getInt(BUNDLE_HINT_TEXT, hintText);
        }

        final EditText editText = new EditText(getActivity());
        AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());

        if(titleText != 0) {
            builder.setTitle(titleText);
        }
        if(messageText != 0) {
            builder.setTitle(messageText);
        }
        if(hintText != 0) {
            editText.setHint(hintText);
        }

        editText.setId(android.R.id.text1);
        editText.setImeOptions(EditorInfo.IME_ACTION_DONE);
        editText.setSingleLine();

        builder.setView(editText);
        builder.setNegativeButton(android.R.string.cancel, new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int which) {
                dialog.cancel();
            }
        });

        editText.setOnEditorActionListener(new OnEditorActionListener() {
            public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
                listener.onTextInputDialogSubmitted(dialogId, v.getText().toString());
                dismiss();
                return true;
            }
        });

        builder.setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int which) {
                listener.onTextInputDialogSubmitted(dialogId, editText.getText().toString());
            }
        });

        return builder.create();
    }

    @Override
    public void onSaveInstanceState(Bundle icicle) {
        super.onSaveInstanceState(icicle);
        icicle.putInt(BUNDLE_DIALOG_ID, dialogId);
        icicle.putInt(BUNDLE_TITLE_TEXT, titleText);
        icicle.putInt(BUNDLE_MESSAGE_TEXT, messageText);
        icicle.putInt(BUNDLE_HINT_TEXT, hintText);
    }

    @Override
    public void onCancel(DialogInterface dialog) {
        super.onCancel(dialog);
        listener.onTextInputDialogCancelled(dialogId);
    }
}
