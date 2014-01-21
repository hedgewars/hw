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

package org.hedgewars.hedgeroid;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.netplay.MessageLog;
import org.hedgewars.hedgeroid.netplay.Netplay;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;

/**
 * This fragment displays a chatlog and text input field for chatting in either
 * the lobby or a room.
 */
public class ChatFragment extends Fragment {
    private ChatlogAdapter adapter;
    private Netplay netplay;
    private MessageLog messageLog;
    private boolean inRoom;

    public void setInRoom(boolean inRoom) {
        this.inRoom = inRoom;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        netplay = Netplay.getAppInstance(getActivity().getApplicationContext());
        adapter = new ChatlogAdapter(getActivity());
    }

    @Override
    public void onStart() {
        super.onStart();
        messageLog = inRoom ? netplay.roomChatlog : netplay.lobbyChatlog;
        adapter.setLog(messageLog.getLog());
        messageLog.addListener(adapter);
    }

    @Override
    public void onStop() {
        super.onStop();
        messageLog.removeListener(adapter);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
            Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_chat, container, false);

        ListView listView = (ListView) view.findViewById(R.id.chatConsole);
        listView.setAdapter(adapter);
        listView.setDivider(null);
        listView.setDividerHeight(0);
        listView.setVerticalFadingEdgeEnabled(true);

        EditText editText = (EditText) view.findViewById(R.id.chatInput);
        editText.setOnEditorActionListener(new ChatSendListener());

        return view;
    }

    private final class ChatSendListener implements OnEditorActionListener {
        public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
            String text = v.getText().toString();
            if(text.length()>0) {
                v.setText("");
                netplay.sendChat(text);
            }
            return true;
        }
    }
}
