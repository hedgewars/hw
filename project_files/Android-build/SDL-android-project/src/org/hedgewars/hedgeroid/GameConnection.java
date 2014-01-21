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

import java.net.ConnectException;

import org.hedgewars.hedgeroid.Datastructures.GameConfig;
import org.hedgewars.hedgeroid.frontlib.Flib;
import org.hedgewars.hedgeroid.frontlib.Frontlib;
import org.hedgewars.hedgeroid.frontlib.Frontlib.ByteArrayPtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.BytesCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.GameSetupPtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.GameconnPtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.IntCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.StrBoolCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.StrCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.VoidCallback;
import org.hedgewars.hedgeroid.frontlib.NativeSizeT;
import org.hedgewars.hedgeroid.netplay.GameMessageListener;
import org.hedgewars.hedgeroid.netplay.Netplay;
import org.hedgewars.hedgeroid.util.TickHandler;

import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;
import android.util.Log;

import com.sun.jna.Pointer;

/**
 * This class handles both talking to the engine (IPC) for running a game, and
 * coordinating with the netconn if it is a netgame, using the frontlib for the
 * actual IPC networking communication.
 *
 * After creating the GameConnection object, it will communicate with the engine
 * on its own thread. It shuts itself down as soon as the connection to the engine
 * is lost.
 */
public final class GameConnection {
    private static final Handler mainHandler = new Handler(Looper.getMainLooper());

    public final int port;
    private final HandlerThread thread;
    private final Handler handler;
    private TickHandler tickHandler;
    private final Netplay netplay; // ==null if not a netgame
    private GameconnPtr conn;

    private GameConnection(GameconnPtr conn, Netplay netplay) {
        this.conn = conn;
        this.port = Flib.INSTANCE.flib_gameconn_getport(conn);
        this.netplay = netplay;
        this.thread = new HandlerThread("IPCThread");
        thread.start();
        this.handler = new Handler(thread.getLooper());
    }

    private void setupConnection() {
        tickHandler = new TickHandler(thread.getLooper(), 50, tickCb);
        tickHandler.start();

        if(netplay != null) {
            mainHandler.post(new Runnable() {
                public void run() {
                    netplay.registerGameMessageListener(gameMessageListener);
                }
            });
            Flib.INSTANCE.flib_gameconn_onChat(conn, chatCb, null);
            Flib.INSTANCE.flib_gameconn_onEngineMessage(conn, engineMessageCb, null);
        }
        Flib.INSTANCE.flib_gameconn_onConnect(conn, connectCb, null);
        Flib.INSTANCE.flib_gameconn_onDisconnect(conn, disconnectCb, null);
        Flib.INSTANCE.flib_gameconn_onErrorMessage(conn, errorMessageCb, null);
    }

    /**
     * Start a new IPC server to communicate with the engine.
     * Performs networking operations, don't run on the UI thread.
     * @throws ConnectException if we can't set up the IPC server
     */
    public static GameConnection forNetgame(final GameConfig config, Netplay netplay) throws ConnectException {
        final String playerName = netplay.getPlayerName();
        GameconnPtr conn = Flib.INSTANCE.flib_gameconn_create(playerName, GameSetupPtr.createJavaOwned(config), true);
        if(conn == null) {
            throw new ConnectException();
        }
        GameConnection result = new GameConnection(conn, netplay);
        result.setupConnection();
        return result;
    }

    /**
     * Start a new IPC server to communicate with the engine.
     * Performs networking operations, don't run on the UI thread.
     * @throws ConnectException if we can't set up the IPC server
     */
    public static GameConnection forLocalGame(final GameConfig config) throws ConnectException {
        GameconnPtr conn = Flib.INSTANCE.flib_gameconn_create("Player", GameSetupPtr.createJavaOwned(config), false);
        if(conn == null) {
            throw new ConnectException();
        }
        GameConnection result = new GameConnection(conn, null);
        result.setupConnection();
        return result;
    }

    private final Runnable tickCb = new Runnable() {
        public void run() {
            Flib.INSTANCE.flib_gameconn_tick(conn);
        }
    };

    // runs on the IPCThread
    private void shutdown() {
        tickHandler.stop();
        thread.quit();
        Flib.INSTANCE.flib_gameconn_destroy(conn);
        conn = null;
        if(netplay != null) {
            mainHandler.post(new Runnable() {
                public void run() {
                    netplay.unregisterGameMessageListener(gameMessageListener);
                }
            });
        }
    }

    // runs on the IPCThread
    private final StrBoolCallback chatCb = new StrBoolCallback() {
        public void callback(Pointer context, String message, boolean teamChat) {
            if(teamChat) {
                netplay.sendTeamChat(message);
            } else {
                netplay.sendChat(message);
            }
        }
    };

    // runs on the IPCThread
    private final VoidCallback connectCb = new VoidCallback() {
        public void callback(Pointer context) {
            Log.i("GameConnection", "Connected");
        }
    };

    // runs on the IPCThread
    private final IntCallback disconnectCb = new IntCallback() {
        public void callback(Pointer context, int reason) {
            if(netplay != null) {
                netplay.sendRoundFinished(reason==Frontlib.GAME_END_FINISHED);
            }
            shutdown();
        }
    };

    // runs on the IPCThread
    private final BytesCallback engineMessageCb = new BytesCallback() {
        public void callback(Pointer context, ByteArrayPtr buffer, NativeSizeT size) {
            netplay.sendEngineMessage(buffer.deref(size.intValue()));
        }
    };

    // runs on the IPCThread
    private final StrCallback errorMessageCb = new StrCallback() {
        public void callback(Pointer context, String message) {
            Log.e("GameConnection", message);
        }
    };

    // runs on any thread
    private final GameMessageListener gameMessageListener = new GameMessageListener() {
        public void onNetDisconnected() {
            handler.post(new Runnable() {
                public void run() {
                    Flib.INSTANCE.flib_gameconn_send_quit(conn);
                }
            });
        }

        public void onMessage(final int type, final String message) {
            handler.post(new Runnable() {
                public void run() {
                    Flib.INSTANCE.flib_gameconn_send_textmsg(conn, type, message);
                }
            });
        }

        public void onEngineMessage(final byte[] em) {
            handler.post(new Runnable() {
                public void run() {
                    ByteArrayPtr ptr = ByteArrayPtr.createJavaOwned(em);
                    Flib.INSTANCE.flib_gameconn_send_enginemsg(conn, ptr, NativeSizeT.valueOf(em.length));
                }
            });
        }

        public void onChatMessage(final String nick, final String message) {
            handler.post(new Runnable() {
                public void run() {
                    Flib.INSTANCE.flib_gameconn_send_chatmsg(conn, nick, message);
                }
            });
        }
    };
}
