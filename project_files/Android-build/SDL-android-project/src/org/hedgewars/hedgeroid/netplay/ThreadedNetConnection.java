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

package org.hedgewars.hedgeroid.netplay;

import static org.hedgewars.hedgeroid.netplay.Netplay.FromNetMsgType.*;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Datastructures.MapRecipe;
import org.hedgewars.hedgeroid.Datastructures.Scheme;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.Datastructures.Weaponset;
import org.hedgewars.hedgeroid.frontlib.Flib;
import org.hedgewars.hedgeroid.frontlib.Frontlib;
import org.hedgewars.hedgeroid.frontlib.Frontlib.BoolCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.ByteArrayPtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.BytesCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.GameSetupPtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.IntStrCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.MapIntCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.MapRecipePtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.NetconnPtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.RoomArrayPtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.RoomCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.RoomListCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.RoomPtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.SchemeCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.SchemePtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.StrCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.StrIntCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.StrRoomCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.StrStrBoolCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.StrStrCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.TeamCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.TeamPtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.VoidCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.WeaponsetCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.WeaponsetPtr;
import org.hedgewars.hedgeroid.frontlib.NativeSizeT;
import org.hedgewars.hedgeroid.netplay.Netplay.FromNetHandler;
import org.hedgewars.hedgeroid.netplay.Netplay.FromNetMsgType;
import org.hedgewars.hedgeroid.util.FileUtils;
import org.hedgewars.hedgeroid.util.TickHandler;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.res.Resources;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;
import android.os.Message;
import android.util.Log;
import android.util.Pair;

import com.sun.jna.Pointer;

/**
 * This class handles the actual communication with the networking library, running on a separate thread.
 *
 * In order to process net messages, this class regularly runs a tick() function on the frontlib. This
 * usually happens several times per second, but it can be slowed down a lot if no fast reaction to
 * events is required (e.g. to conserve battery if the application is in the background).
 */
class ThreadedNetConnection {
    private static final long TICK_INTERVAL_FAST = 100;
    private static final long TICK_INTERVAL_SLOW = 5000;
    private static final Frontlib FLIB = Flib.INSTANCE;

    public final ToNetHandler toNetHandler;

    private final Context appContext;
    private final FromNetHandler fromNetHandler;
    private final TickHandler tickHandler;

    /**
     * conn can only be null while connecting (the first thing in the thread), and directly after disconnecting,
     * in the same message (the looper is shut down on disconnect, so there will be no messages after that).
     */
    private NetconnPtr conn;
    private String playerName;

    private ThreadedNetConnection(Context appContext, FromNetHandler fromNetHandler) {
        this.appContext = appContext;
        this.fromNetHandler = fromNetHandler;

        HandlerThread thread = new HandlerThread("NetThread");
        thread.start();
        toNetHandler = new ToNetHandler(thread.getLooper());
        tickHandler = new TickHandler(thread.getLooper(), TICK_INTERVAL_FAST, tickCb);
    }

    private void connect(final String name, final String host, final int port) {
        toNetHandler.post(new Runnable() {
            public void run() {
                playerName = name == null ? "Player" : name;
                File dataPath;
                try {
                    dataPath = FileUtils.getDataPathFile(appContext);
                } catch (FileNotFoundException e) {
                    shutdown(true, appContext.getString(R.string.sdcard_not_mounted));
                    return;
                }
                conn = FLIB.flib_netconn_create(playerName, dataPath.getAbsolutePath()+"/", host, port);
                if(conn == null) {
                    shutdown(true, appContext.getString(R.string.error_connection_failed));
                    return;
                }

                FLIB.flib_netconn_onSchemeChanged(conn, cfgSchemeCb, null);
                FLIB.flib_netconn_onClientFlags(conn, clientFlagsCb, null);
                FLIB.flib_netconn_onChat(conn, chatCb, null);
                FLIB.flib_netconn_onConnected(conn, connectedCb, null);
                FLIB.flib_netconn_onDisconnected(conn, disconnectCb, null);
                FLIB.flib_netconn_onEngineMessage(conn, engineMessageCb, null);
                FLIB.flib_netconn_onEnterRoom(conn, enterRoomCb, null);
                FLIB.flib_netconn_onHogCountChanged(conn, hogCountChangedCb, null);
                FLIB.flib_netconn_onLeaveRoom(conn, leaveRoomCb, null);
                FLIB.flib_netconn_onLobbyJoin(conn, lobbyJoinCb, null);
                FLIB.flib_netconn_onLobbyLeave(conn, lobbyLeaveCb, null);
                FLIB.flib_netconn_onMapChanged(conn, mapChangedCb, null);
                FLIB.flib_netconn_onMessage(conn, messageCb, null);
                FLIB.flib_netconn_onPasswordRequest(conn, passwordRequestCb, null);
                FLIB.flib_netconn_onRoomAdd(conn, roomAddCb, null);
                FLIB.flib_netconn_onRoomDelete(conn, roomDeleteCb, null);
                FLIB.flib_netconn_onRoomJoin(conn, roomJoinCb, null);
                FLIB.flib_netconn_onRoomLeave(conn, roomLeaveCb, null);
                FLIB.flib_netconn_onRoomlist(conn, roomlistCb, null);
                FLIB.flib_netconn_onRoomUpdate(conn, roomUpdateCb, null);
                FLIB.flib_netconn_onRunGame(conn, runGameCb, null);
                FLIB.flib_netconn_onScriptChanged(conn, scriptChangedCb, null);
                // FLIB.flib_netconn_onServerVar(conn, serverVarCb, null);
                FLIB.flib_netconn_onTeamAccepted(conn, teamAcceptedCb, null);
                FLIB.flib_netconn_onTeamAdd(conn, teamAddedCb, null);
                FLIB.flib_netconn_onTeamColorChanged(conn, teamColorChangedCb, null);
                FLIB.flib_netconn_onTeamDelete(conn, teamDeletedCb, null);
                FLIB.flib_netconn_onWeaponsetChanged(conn, weaponsetChangedCb, null);

                tickHandler.start();
            }
        });
    }

    public static ThreadedNetConnection startConnection(Context appContext, FromNetHandler fromNetHandler, String playerName, String host, int port) {
        ThreadedNetConnection result = new ThreadedNetConnection(appContext, fromNetHandler);
        result.connect(playerName, host, port);
        return result;
    }

    public void setFastTickRate(boolean fastTickRate) {
        tickHandler.setInterval(fastTickRate ? TICK_INTERVAL_FAST : TICK_INTERVAL_SLOW);
    }

    private final Runnable tickCb = new Runnable() {
        public void run() {
            FLIB.flib_netconn_tick(conn);
        }
    };

    private final SchemeCallback cfgSchemeCb = new SchemeCallback() {
        public void callback(Pointer context, SchemePtr schemePtr) {
            sendFromNet(MSG_SCHEME_CHANGED, schemePtr.deref());
        }
    };

    private final MapIntCallback mapChangedCb = new MapIntCallback() {
        public void callback(Pointer context, MapRecipePtr mapPtr, int updateType) {
            sendFromNet(MSG_MAP_CHANGED, updateType, mapPtr.deref());
        }
    };

    private final StrCallback scriptChangedCb = new StrCallback() {
        public void callback(Pointer context, String script) {
            sendFromNet(MSG_SCRIPT_CHANGED, script);
        }
    };

    private final WeaponsetCallback weaponsetChangedCb = new WeaponsetCallback() {
        public void callback(Pointer context, WeaponsetPtr weaponsetPtr) {
            sendFromNet(MSG_WEAPONSET_CHANGED, weaponsetPtr.deref());
        }
    };

    private final StrCallback lobbyJoinCb = new StrCallback() {
        public void callback(Pointer context, String name) {
            sendFromNet(MSG_LOBBY_JOIN, name);
        }
    };

    private final StrStrCallback lobbyLeaveCb = new StrStrCallback() {
        public void callback(Pointer context, String name, String msg) {
            sendFromNet(MSG_LOBBY_LEAVE, Pair.create(name, msg));
        }
    };

    private final StrCallback roomJoinCb = new StrCallback() {
        public void callback(Pointer context, String name) {
            sendFromNet(MSG_ROOM_JOIN, name);
        }
    };

    private final StrStrCallback roomLeaveCb = new StrStrCallback() {
        public void callback(Pointer context, String name, String message) {
            sendFromNet(MSG_ROOM_LEAVE, Pair.create(name, message));
        }
    };

    private final StrStrBoolCallback clientFlagsCb = new StrStrBoolCallback() {
        public void callback(Pointer context, String nick, String flags, boolean newFlagsState) {
            sendFromNet(MSG_CLIENT_FLAGS, new ClientFlagsUpdate(nick, flags, newFlagsState));
        }
    };

    private final StrStrCallback chatCb = new StrStrCallback() {
        public void callback(Pointer context, String name, String msg) {
            sendFromNet(MSG_CHAT, Pair.create(name, msg));
        }
    };

    private final IntStrCallback messageCb = new IntStrCallback() {
        public void callback(Pointer context, int type, String msg) {
            sendFromNet(MSG_MESSAGE, type, msg);
        }
    };

    private final RoomCallback roomAddCb = new RoomCallback() {
        public void callback(Pointer context, RoomPtr roomPtr) {
            sendFromNet(MSG_ROOM_ADD, roomPtr.deref());
        }
    };

    private final StrRoomCallback roomUpdateCb = new StrRoomCallback() {
        public void callback(Pointer context, String name, RoomPtr roomPtr) {
            sendFromNet(MSG_ROOM_UPDATE, Pair.create(name, roomPtr.deref()));
        }
    };

    private final StrCallback roomDeleteCb = new StrCallback() {
        public void callback(Pointer context, final String name) {
            sendFromNet(MSG_ROOM_DELETE, name);
        }
    };

    private final RoomListCallback roomlistCb = new RoomListCallback() {
        public void callback(Pointer context, RoomArrayPtr arg1, int count) {
            sendFromNet(MSG_ROOMLIST, arg1.getRooms(count));
        }
    };

    private final VoidCallback connectedCb = new VoidCallback() {
        public void callback(Pointer context) {
            FLIB.flib_netconn_send_request_roomlist(conn);
            playerName = FLIB.flib_netconn_get_playername(conn);
            sendFromNet(MSG_CONNECTED, playerName);
        }
    };

    private final StrCallback passwordRequestCb = new StrCallback() {
        public void callback(Pointer context, String nickname) {
            sendFromNet(MSG_PASSWORD_REQUEST, playerName);
        }
    };

    private final BoolCallback enterRoomCb = new BoolCallback() {
        public void callback(Pointer context, boolean isChief) {
            sendFromNet(MSG_ENTER_ROOM_FROM_LOBBY, isChief);
        }
    };

    private final IntStrCallback leaveRoomCb = new IntStrCallback() {
        public void callback(Pointer context, int reason, String message) {
            sendFromNet(MSG_LEAVE_ROOM, reason, message);
        }
    };

    private final TeamCallback teamAddedCb = new TeamCallback() {
        public void callback(Pointer context, TeamPtr team) {
            sendFromNet(MSG_TEAM_ADDED, team.deref());
        }
    };

    private final StrCallback teamDeletedCb = new StrCallback() {
        public void callback(Pointer context, String teamName) {
            sendFromNet(MSG_TEAM_DELETED, teamName);
        }
    };

    private final StrCallback teamAcceptedCb = new StrCallback() {
        public void callback(Pointer context, String teamName) {
            sendFromNet(MSG_TEAM_ACCEPTED, teamName);
        }
    };

    private final StrIntCallback teamColorChangedCb = new StrIntCallback() {
        public void callback(Pointer context, String teamName, int colorIndex) {
            sendFromNet(MSG_TEAM_COLOR_CHANGED, colorIndex, teamName);
        }
    };

    private final StrIntCallback hogCountChangedCb = new StrIntCallback() {
        public void callback(Pointer context, String teamName, int hogCount) {
            sendFromNet(MSG_HOG_COUNT_CHANGED, hogCount, teamName);
        }
    };

    private final BytesCallback engineMessageCb = new BytesCallback() {
        public void callback(Pointer context, ByteArrayPtr buffer, NativeSizeT size) {
            sendFromNet(MSG_ENGINE_MESSAGE, buffer.deref(size.intValue()));
        }
    };

    private final VoidCallback runGameCb = new VoidCallback() {
        public void callback(Pointer context) {
            GameSetupPtr configPtr = FLIB.flib_netconn_create_gamesetup(conn);
            sendFromNet(MSG_RUN_GAME, configPtr.deref());
            FLIB.flib_gamesetup_destroy(configPtr);
        }
    };

    private void shutdown(boolean error, String message) {
        if(conn != null) {
            FLIB.flib_netconn_destroy(conn);
            conn = null;
        }
        tickHandler.stop();
        toNetHandler.getLooper().quit();
        sendFromNet(MSG_DISCONNECTED, Pair.create(error, message));
    }

    private final IntStrCallback disconnectCb = new IntStrCallback() {
        public void callback(Pointer context, int reason, String message) {
            Boolean error = reason != Frontlib.NETCONN_DISCONNECT_NORMAL;
            String messageForUser = createDisconnectUserMessage(appContext.getResources(), reason, message);
            shutdown(error, messageForUser);
        }
    };

    private static String createDisconnectUserMessage(Resources res, int reason, String message) {
        switch(reason) {
        case Frontlib.NETCONN_DISCONNECT_AUTH_FAILED:
            return res.getString(R.string.error_auth_failed);
        case Frontlib.NETCONN_DISCONNECT_CONNLOST:
            return res.getString(R.string.error_connection_lost);
        case Frontlib.NETCONN_DISCONNECT_INTERNAL_ERROR:
            return res.getString(R.string.error_unexpected, message);
        case Frontlib.NETCONN_DISCONNECT_SERVER_TOO_OLD:
            return res.getString(R.string.error_server_too_old);
        default:
            return message;
        }
    }

    private boolean sendFromNet(FromNetMsgType what, Object obj) {
        return fromNetHandler.sendMessage(fromNetHandler.obtainMessage(what.ordinal(), obj));
    }

    private boolean sendFromNet(FromNetMsgType what, int arg1, Object obj) {
        return fromNetHandler.sendMessage(fromNetHandler.obtainMessage(what.ordinal(), arg1, 0, obj));
    }

    static enum ToNetMsgType {
        MSG_SEND_NICK,
        MSG_SEND_PASSWORD,
        MSG_SEND_QUIT,
        MSG_SEND_ROOMLIST_REQUEST,
        MSG_SEND_PLAYER_INFO_REQUEST,
        MSG_SEND_CHAT,
        MSG_SEND_TEAMCHAT,
        MSG_SEND_FOLLOW_PLAYER,
        MSG_SEND_JOIN_ROOM,
        MSG_SEND_CREATE_ROOM,
        MSG_SEND_LEAVE_ROOM,
        MSG_SEND_KICK,
        MSG_SEND_ADD_TEAM,
        MSG_SEND_REMOVE_TEAM,
        MSG_DISCONNECT,
        MSG_SEND_TEAM_COLOR_INDEX,
        MSG_SEND_TEAM_HOG_COUNT,
        MSG_SEND_ENGINE_MESSAGE,
        MSG_SEND_ROUND_FINISHED,
        MSG_SEND_TOGGLE_READY,
        MSG_SEND_START_GAME,
        MSG_SEND_WEAPONSET,
        MSG_SEND_MAP,
        MSG_SEND_MAP_NAME,
        MSG_SEND_MAP_GENERATOR,
        MSG_SEND_MAP_TEMPLATE,
        MSG_SEND_MAZE_SIZE,
        MSG_SEND_MAP_SEED,
        MSG_SEND_MAP_THEME,
        MSG_SEND_MAP_DRAWDATA,
        MSG_SEND_GAMESTYLE,
        MSG_SEND_SCHEME;

        static final List<ThreadedNetConnection.ToNetMsgType> values = Collections.unmodifiableList(Arrays.asList(ToNetMsgType.values()));
    }

    /**
     * Processes messages to the networking system. Runs on a non-main thread.
     */
    @SuppressLint("HandlerLeak")
    public final class ToNetHandler extends Handler {

        public ToNetHandler(Looper looper) {
            super(looper);
        }

        @Override
        public void handleMessage(Message msg) {
            switch(ToNetMsgType.values.get(msg.what)) {
            case MSG_SEND_NICK: {
                FLIB.flib_netconn_send_nick(conn, (String)msg.obj);
                break;
            }
            case MSG_SEND_PASSWORD: {
                FLIB.flib_netconn_send_password(conn, (String)msg.obj);
                break;
            }
            case MSG_SEND_QUIT: {
                FLIB.flib_netconn_send_quit(conn, (String)msg.obj);
                break;
            }
            case MSG_SEND_ROOMLIST_REQUEST: {
                FLIB.flib_netconn_send_request_roomlist(conn);
                break;
            }
            case MSG_SEND_PLAYER_INFO_REQUEST: {
                FLIB.flib_netconn_send_playerInfo(conn, (String)msg.obj);
                break;
            }
            case MSG_SEND_CHAT: {
                if(FLIB.flib_netconn_send_chat(conn, (String)msg.obj) == 0) {
                    sendFromNet(MSG_CHAT, Pair.create(playerName, (String)msg.obj));
                }
                break;
            }
            case MSG_SEND_TEAMCHAT: {
                FLIB.flib_netconn_send_teamchat(conn, (String)msg.obj);
                break;
            }
            case MSG_SEND_FOLLOW_PLAYER: {
                FLIB.flib_netconn_send_playerFollow(conn, (String)msg.obj);
                break;
            }
            case MSG_SEND_JOIN_ROOM: {
                FLIB.flib_netconn_send_joinRoom(conn, (String)msg.obj);
                break;
            }
            case MSG_SEND_CREATE_ROOM: {
                FLIB.flib_netconn_send_createRoom(conn, (String)msg.obj);
                break;
            }
            case MSG_SEND_LEAVE_ROOM: {
                if(FLIB.flib_netconn_send_leaveRoom(conn, (String)msg.obj) == 0) {
                    sendFromNet(MSG_LEAVE_ROOM, -1, "");
                }
                break;
            }
            case MSG_SEND_KICK: {
                FLIB.flib_netconn_send_kick(conn, (String)msg.obj);
                break;
            }
            case MSG_SEND_ADD_TEAM: {
                FLIB.flib_netconn_send_addTeam(conn, TeamPtr.createJavaOwned((TeamInGame)msg.obj));
                break;
            }
            case MSG_SEND_REMOVE_TEAM: {
                if(FLIB.flib_netconn_send_removeTeam(conn, (String)msg.obj)==0) {
                    sendFromNet(MSG_TEAM_DELETED, msg.obj);
                }
                break;
            }
            case MSG_DISCONNECT: {
                FLIB.flib_netconn_send_quit(conn, (String)msg.obj);
                shutdown(false, "User quit");
                break;
            }
            case MSG_SEND_TEAM_COLOR_INDEX: {
                FLIB.flib_netconn_send_teamColor(conn, (String)msg.obj, msg.arg1);
                break;
            }
            case MSG_SEND_TEAM_HOG_COUNT: {
                FLIB.flib_netconn_send_teamHogCount(conn, (String)msg.obj, msg.arg1);
                break;
            }
            case MSG_SEND_ENGINE_MESSAGE: {
                byte[] message = (byte[])msg.obj;
                ByteArrayPtr ptr = ByteArrayPtr.createJavaOwned(message);
                FLIB.flib_netconn_send_engineMessage(conn, ptr, NativeSizeT.valueOf(message.length));
                break;
            }
            case MSG_SEND_ROUND_FINISHED: {
                FLIB.flib_netconn_send_roundfinished(conn, (Boolean)msg.obj);
                break;
            }
            case MSG_SEND_TOGGLE_READY: {
                FLIB.flib_netconn_send_toggleReady(conn);
                break;
            }
            case MSG_SEND_START_GAME: {
                FLIB.flib_netconn_send_startGame(conn);
                break;
            }
            case MSG_SEND_WEAPONSET: {
                FLIB.flib_netconn_send_weaponset(conn, WeaponsetPtr.createJavaOwned((Weaponset)msg.obj));
                break;
            }
            case MSG_SEND_MAP: {
                FLIB.flib_netconn_send_map(conn, MapRecipePtr.createJavaOwned((MapRecipe)msg.obj));
                break;
            }
            case MSG_SEND_MAP_NAME: {
                FLIB.flib_netconn_send_mapName(conn, (String)msg.obj);
                break;
            }
            case MSG_SEND_MAP_GENERATOR: {
                FLIB.flib_netconn_send_mapGen(conn, msg.arg1);
                break;
            }
            case MSG_SEND_MAP_TEMPLATE: {
                FLIB.flib_netconn_send_mapTemplate(conn, msg.arg1);
                break;
            }
            case MSG_SEND_MAZE_SIZE: {
                FLIB.flib_netconn_send_mapMazeSize(conn, msg.arg1);
                break;
            }
            case MSG_SEND_MAP_SEED: {
                FLIB.flib_netconn_send_mapSeed(conn, (String) msg.obj);
                break;
            }
            case MSG_SEND_MAP_THEME: {
                FLIB.flib_netconn_send_mapTheme(conn, (String) msg.obj);
                break;
            }
            case MSG_SEND_MAP_DRAWDATA: {
                byte[] message = (byte[])msg.obj;
                ByteArrayPtr ptr = ByteArrayPtr.createJavaOwned(message);
                FLIB.flib_netconn_send_mapDrawdata(conn, ptr, NativeSizeT.valueOf(message.length));
                break;
            }
            case MSG_SEND_GAMESTYLE: {
                FLIB.flib_netconn_send_script(conn, (String) msg.obj);
                break;
            }
            case MSG_SEND_SCHEME: {
                FLIB.flib_netconn_send_scheme(conn, SchemePtr.createJavaOwned((Scheme) msg.obj));
                break;
            }
            default: {
                Log.e("ToNetHandler", "Unknown message type: "+msg.what);
                break;
            }
            }
        }
    }
}