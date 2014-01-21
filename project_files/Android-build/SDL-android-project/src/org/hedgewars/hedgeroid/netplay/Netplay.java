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

import static org.hedgewars.hedgeroid.netplay.ThreadedNetConnection.ToNetMsgType.*;

import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedList;
import java.util.List;

import org.hedgewars.hedgeroid.RoomStateManager;
import org.hedgewars.hedgeroid.Datastructures.GameConfig;
import org.hedgewars.hedgeroid.Datastructures.MapRecipe;
import org.hedgewars.hedgeroid.Datastructures.Player;
import org.hedgewars.hedgeroid.Datastructures.PlayerInRoom;
import org.hedgewars.hedgeroid.Datastructures.Room;
import org.hedgewars.hedgeroid.Datastructures.Scheme;
import org.hedgewars.hedgeroid.Datastructures.Schemes;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.Datastructures.TeamIngameAttributes;
import org.hedgewars.hedgeroid.Datastructures.Weaponset;
import org.hedgewars.hedgeroid.Datastructures.Weaponsets;
import org.hedgewars.hedgeroid.netplay.ThreadedNetConnection.ToNetMsgType;
import org.hedgewars.hedgeroid.util.ObservableTreeMap;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;
import android.util.Pair;


/**
 * This class manages the application's networking state.
 */
public class Netplay {
    public static enum State { NOT_CONNECTED, CONNECTING, LOBBY, ROOM }

    // Extras in broadcasts
    public static final String EXTRA_PLAYERNAME = "playerName";
    public static final String EXTRA_MESSAGE = "message";
    public static final String EXTRA_HAS_ERROR = "hasError";
    public static final String EXTRA_REASON = "reason";

    private static final String ACTIONPREFIX = "org.hedgewars.hedgeroid.netconn.";
    public static final String ACTION_DISCONNECTED = ACTIONPREFIX+"DISCONNECTED";
    public static final String ACTION_CONNECTED = ACTIONPREFIX+"CONNECTED";
    public static final String ACTION_PASSWORD_REQUESTED = ACTIONPREFIX+"PASSWORD_REQUESTED";
    public static final String ACTION_ENTERED_ROOM_FROM_LOBBY = ACTIONPREFIX+"ENTERED_ROOM";
    public static final String ACTION_LEFT_ROOM = ACTIONPREFIX+"LEFT_ROOM";
    public static final String ACTION_STATE_CHANGED = ACTIONPREFIX+"STATE_CHANGED";

    public static final String DEFAULT_SERVER = "netserver.hedgewars.org";
    public static final int DEFAULT_PORT = 46631;

    private final Context appContext;
    private final LocalBroadcastManager broadcastManager;
    private final FromNetHandler fromNetHandler = new FromNetHandler();
    public final Scheme defaultScheme;
    public final Weaponset defaultWeaponset;

    private State state = State.NOT_CONNECTED;
    private String playerName;

    // null or stale if not in room state
    private final NetRoomState netRoomState = new NetRoomState(this);

    // null if there is no running connection (==state is NOT_CONNECTED)
    private ThreadedNetConnection connection;

    public final ObservableTreeMap<String, Player> lobbyPlayerlist = new ObservableTreeMap<String, Player>();
    public final ObservableTreeMap<String, PlayerInRoom> roomPlayerlist = new ObservableTreeMap<String, PlayerInRoom>();
    public final Roomlist roomList = new Roomlist();
    public final MessageLog lobbyChatlog;
    public final MessageLog roomChatlog;

    private final List<GameMessageListener> gameMessageListeners = new LinkedList<GameMessageListener>();
    private final List<RunGameListener> runGameListeners = new LinkedList<RunGameListener>();

    public Netplay(Context appContext, Scheme defaultScheme, Weaponset defaultWeaponset) {
        this.appContext = appContext;
        broadcastManager = LocalBroadcastManager.getInstance(appContext);
        lobbyChatlog = new MessageLog(appContext);
        roomChatlog = new MessageLog(appContext);
        this.defaultScheme = defaultScheme;
        this.defaultWeaponset = defaultWeaponset;
    }

    public RoomStateManager getRoomStateManager() {
        return netRoomState;
    }

    private void clearLobbyState() {
        lobbyPlayerlist.clear();
        roomList.clear();
        lobbyChatlog.clear();
    }

    private void initRoomState(boolean chief) {
        roomChatlog.clear();
        roomPlayerlist.clear();
        netRoomState.initRoomState(chief);
    }

    public void registerGameMessageListener(GameMessageListener listener) {
        gameMessageListeners.add(listener);
    }

    public void unregisterGameMessageListener(GameMessageListener listener) {
        gameMessageListeners.remove(listener);
    }

    public void registerRunGameListener(RunGameListener listener) {
        runGameListeners.add(listener);
    }

    public void unregisterRunGameListener(RunGameListener listener) {
        runGameListeners.remove(listener);
    }

    public void connectToDefaultServer(String playerName) {
        connect(playerName, DEFAULT_SERVER, DEFAULT_PORT);
    }

    /**
     * Establish a new connection. Only call if the current state is NOT_CONNECTED.
     *
     * The state will switch to CONNECTING immediately. After that, it can asynchronously change to any other state.
     * State changes are indicated by broadcasts. In particular, if an error occurs while trying to connect, the state
     * will change back to NOT_CONNECTED and an ACTION_DISCONNECTED broadcast is sent.
     */
    public void connect(String name, String host, int port) {
        playerName = name;
        if(state != State.NOT_CONNECTED) {
            throw new IllegalStateException("Attempt to start a new connection while the old one was still running.");
        }

        clearLobbyState();
        changeState(State.CONNECTING);
        connection = ThreadedNetConnection.startConnection(appContext, fromNetHandler, name, host, port);
        connection.setFastTickRate(true);
    }

    public void sendNick(String nick) {
        playerName = nick;
        sendToNet(MSG_SEND_NICK, nick);
    }
    public void sendPassword(String password) { sendToNet(MSG_SEND_PASSWORD, password); }
    public void sendQuit(String message) { sendToNet(MSG_SEND_QUIT, message); }
    public void sendRoomlistRequest() { sendToNet(MSG_SEND_ROOMLIST_REQUEST); }
    public void sendPlayerInfoQuery(String name) { sendToNet(MSG_SEND_PLAYER_INFO_REQUEST, name); }
    public void sendChat(String s) { sendToNet(MSG_SEND_CHAT, s); }
    public void sendTeamChat(String s) { sendToNet(MSG_SEND_TEAMCHAT, s); }
    public void sendFollowPlayer(String nick) { sendToNet(MSG_SEND_FOLLOW_PLAYER, nick); }
    public void sendJoinRoom(String name) { sendToNet(MSG_SEND_JOIN_ROOM, name); }
    public void sendCreateRoom(String name) { sendToNet(MSG_SEND_CREATE_ROOM, name); }
    public void sendLeaveRoom(String message) { sendToNet(MSG_SEND_LEAVE_ROOM, message); }
    public void sendKick(String player) { sendToNet(MSG_SEND_KICK, player); }
    public void sendEngineMessage(byte[] engineMessage) { sendToNet(MSG_SEND_ENGINE_MESSAGE, engineMessage); }
    public void sendRoundFinished(boolean withoutError) { sendToNet(MSG_SEND_ROUND_FINISHED, Boolean.valueOf(withoutError)); }
    public void sendToggleReady() { sendToNet(MSG_SEND_TOGGLE_READY); }
    public void sendStartGame() { sendToNet(MSG_SEND_START_GAME); }

    public void disconnect() { sendToNet(MSG_DISCONNECT, "User Quit"); }

    private static Netplay instance;

    /**
     * Retrieve the single app-wide instance of the netplay interface, creating it if it
     * does not exist yet.
     *
     * @param applicationContext
     * @return
     */
    public static Netplay getAppInstance(Context applicationContext) {
        if(instance == null) {
            // We will need some default values for rooms, best load them here
            Scheme defaultScheme = null;
            Weaponset defaultWeaponset = null;
            try {
                List<Scheme> schemes = Schemes.loadBuiltinSchemes(applicationContext);
                for(Scheme scheme : schemes) {
                    if(scheme.name.equals(GameConfig.DEFAULT_SCHEME)) {
                        defaultScheme = scheme;
                    }
                }
                List<Weaponset> weaponsets = Weaponsets.loadBuiltinWeaponsets(applicationContext);
                for(Weaponset weaponset : weaponsets) {
                    if(weaponset.name.equals(GameConfig.DEFAULT_WEAPONSET)) {
                        defaultWeaponset = weaponset;
                    }
                }
            } catch(IOException e) {
                throw new RuntimeException(e);
            }

            if(defaultScheme==null || defaultWeaponset==null) {
                throw new RuntimeException("Unable to load default scheme or weaponset");
            }

            instance = new Netplay(applicationContext, defaultScheme, defaultWeaponset);
        }
        return instance;
    }

    public State getState() {
        return state;
    }

    private void changeState(State newState) {
        if(newState != state) {
            state = newState;
            broadcastManager.sendBroadcastSync(new Intent(ACTION_STATE_CHANGED));
        }
    }

    public boolean isChief() {
        if(netRoomState != null) {
            return netRoomState.getChiefStatus();
        } else {
            return false;
        }
    }

    public String getPlayerName() {
        return playerName;
    }

    boolean sendToNet(ToNetMsgType what) {
        return sendToNet(what, 0, null);
    }

    boolean sendToNet(ToNetMsgType what, Object obj) {
        return sendToNet(what, 0, obj);
    }

    boolean sendToNet(ToNetMsgType what, int arg1, Object obj) {
        if(connection != null) {
            Handler handler = connection.toNetHandler;
            return handler.sendMessage(handler.obtainMessage(what.ordinal(), arg1, 0, obj));
        } else {
            return false;
        }
    }

    private MessageLog getCurrentLog() {
        if(state == State.ROOM) {
            return roomChatlog;
        } else {
            return lobbyChatlog;
        }
    }

    public static enum FromNetMsgType {
        MSG_LOBBY_JOIN,
        MSG_LOBBY_LEAVE,
        MSG_ROOM_JOIN,
        MSG_ROOM_LEAVE,
        MSG_CLIENT_FLAGS,
        MSG_CHAT,
        MSG_MESSAGE,
        MSG_ROOM_ADD,
        MSG_ROOM_UPDATE,
        MSG_ROOM_DELETE,
        MSG_ROOMLIST,
        MSG_CONNECTED,
        MSG_DISCONNECTED,
        MSG_PASSWORD_REQUEST,
        MSG_ENTER_ROOM_FROM_LOBBY,
        MSG_LEAVE_ROOM,
        MSG_TEAM_ADDED,
        MSG_TEAM_DELETED,
        MSG_TEAM_ACCEPTED,
        MSG_TEAM_COLOR_CHANGED,
        MSG_HOG_COUNT_CHANGED,
        MSG_ENGINE_MESSAGE,
        MSG_RUN_GAME,
        MSG_SCHEME_CHANGED,
        MSG_MAP_CHANGED,
        MSG_SCRIPT_CHANGED,
        MSG_WEAPONSET_CHANGED;

        static final List<FromNetMsgType> values = Collections.unmodifiableList(Arrays.asList(FromNetMsgType.values()));
    }

    /**
     * Processes messages from the networking system. Always runs on the main thread.
     */
    @SuppressLint("HandlerLeak")
    final class FromNetHandler extends Handler {
        public FromNetHandler() {
            super(Looper.getMainLooper());
        }

        @SuppressWarnings("unchecked")
        @Override
        public void handleMessage(Message msg) {
            switch(FromNetMsgType.values.get(msg.what)) {
            case MSG_LOBBY_JOIN: {
                String name = (String)msg.obj;
                lobbyPlayerlist.put(name, new Player(name, false, false));
                lobbyChatlog.appendPlayerJoin(name);
                break;
            }
            case MSG_LOBBY_LEAVE: {
                Pair<String, String> args = (Pair<String, String>)msg.obj;
                lobbyPlayerlist.remove(args.first);
                lobbyChatlog.appendPlayerLeave(args.first, args.second);
                break;
            }
            case MSG_ROOM_JOIN: {
                String name = (String)msg.obj;
                Player p = lobbyPlayerlist.get(name);
                if(p==null) {
                    Log.w("Netplay", "Unknown player joined room: "+name);
                    p = new Player(name, false, false);
                }
                roomPlayerlist.put(name, new PlayerInRoom(p, false, false));
                roomChatlog.appendPlayerJoin(name);
                break;
            }
            case MSG_ROOM_LEAVE: {
                Pair<String, String> args = (Pair<String, String>)msg.obj;
                roomPlayerlist.remove(args.first);
                roomChatlog.appendPlayerLeave(args.first, args.second);
                break;
            }
            case MSG_CLIENT_FLAGS: {
                ClientFlagsUpdate upd = (ClientFlagsUpdate)msg.obj;
                PlayerInRoom pir = roomPlayerlist.get(upd.nick);
                if(pir != null) {
                    roomPlayerlist.put(upd.nick, upd.applyTo(pir));
                }
                Player p = lobbyPlayerlist.get(upd.nick);
                if(p != null) {
                    lobbyPlayerlist.put(upd.nick, upd.applyTo(p));
                } else {
                    Log.w("Netplay", "Received client flags for unknown player "+upd.nick);
                }
                if(playerName.equals(upd.nick) && upd.appliesTo(ClientFlagsUpdate.FLAG_CHIEF)) {
                    netRoomState.setChief(upd.newFlagState);
                }
                break;
            }
            case MSG_CHAT: {
                Pair<String, String> args = (Pair<String, String>)msg.obj;
                getCurrentLog().appendChat(args.first, args.second);
                for(GameMessageListener listener : gameMessageListeners) {
                    listener.onChatMessage(args.first, args.second);
                }
                break;
            }
            case MSG_MESSAGE: {
                getCurrentLog().appendMessage(msg.arg1, (String)msg.obj);
                for(GameMessageListener listener : gameMessageListeners) {
                    listener.onMessage(1, (String)msg.obj);
                }
                break;
            }
            case MSG_ROOM_ADD: {
                Room room = (Room)msg.obj;
                roomList.addRoomWithNewId(room);
                break;
            }
            case MSG_ROOM_UPDATE: {
                Pair<String, Room> args = (Pair<String, Room>)msg.obj;
                roomList.updateRoom(args.first, args.second);
                break;
            }
            case MSG_ROOM_DELETE: {
                roomList.remove((String)msg.obj);
                break;
            }
            case MSG_ROOMLIST: {
                Room[] rooms = (Room[])msg.obj;
                roomList.updateList(rooms);
                break;
            }
            case MSG_CONNECTED: {
                playerName = (String)msg.obj;
                changeState(State.LOBBY);
                broadcastManager.sendBroadcast(new Intent(ACTION_CONNECTED));
                break;
            }
            case MSG_DISCONNECTED: {
                Pair<Boolean, String> args = (Pair<Boolean, String>)msg.obj;
                for(GameMessageListener listener : gameMessageListeners) {
                    listener.onNetDisconnected();
                }
                changeState(State.NOT_CONNECTED);
                connection = null;
                Intent intent = new Intent(ACTION_DISCONNECTED);
                intent.putExtra(EXTRA_HAS_ERROR, args.first);
                intent.putExtra(EXTRA_MESSAGE, args.second);
                broadcastManager.sendBroadcastSync(intent);
                break;
            }
            case MSG_PASSWORD_REQUEST: {
                Intent intent = new Intent(ACTION_PASSWORD_REQUESTED);
                intent.putExtra(EXTRA_PLAYERNAME, (String)msg.obj);
                broadcastManager.sendBroadcast(intent);
                break;
            }
            case MSG_ENTER_ROOM_FROM_LOBBY: {
                initRoomState((Boolean)msg.obj);
                changeState(State.ROOM);
                Intent intent = new Intent(ACTION_ENTERED_ROOM_FROM_LOBBY);
                broadcastManager.sendBroadcastSync(intent);
                break;
            }
            case MSG_LEAVE_ROOM: {
                changeState(State.LOBBY);
                Intent intent = new Intent(ACTION_LEFT_ROOM);
                intent.putExtra(EXTRA_MESSAGE, (String)msg.obj);
                intent.putExtra(EXTRA_REASON, msg.arg1);
                broadcastManager.sendBroadcastSync(intent);
                break;
            }
            case MSG_TEAM_ADDED: {
                TeamInGame newTeam = (TeamInGame)msg.obj;
                if(isChief()) {
                    int freeColor = TeamInGame.getUnusedOrRandomColorIndex(netRoomState.getTeams().values());
                    sendToNet(MSG_SEND_TEAM_HOG_COUNT, newTeam.ingameAttribs.hogCount, newTeam.team.name);
                    sendToNet(MSG_SEND_TEAM_COLOR_INDEX, freeColor, newTeam.team.name);
                    newTeam = newTeam.withAttribs(newTeam.ingameAttribs.withColorIndex(freeColor));
                }
                netRoomState.putTeam(newTeam);
                break;
            }
            case MSG_TEAM_DELETED: {
                netRoomState.removeTeam((String)msg.obj);
                break;
            }
            case MSG_TEAM_ACCEPTED: {
                TeamInGame requestedTeam = netRoomState.requestedTeams.remove(msg.obj);
                if(requestedTeam!=null) {
                    netRoomState.putTeam(requestedTeam);
                    if(isChief()) {
                        // Not strictly necessary, but QtFrontend does it...
                        sendToNet(MSG_SEND_TEAM_HOG_COUNT, requestedTeam.ingameAttribs.hogCount, requestedTeam.team.name);
                    }
                } else {
                    Log.e("Netplay", "Got accepted message for team that was never requested.");
                }
                break;
            }
            case MSG_TEAM_COLOR_CHANGED: {
                TeamInGame oldEntry = netRoomState.getTeams().get((String)msg.obj);
                if(oldEntry != null) {
                    /*
                     * If we are chief, we ignore colors from the outside. They only come from the server
                     * when someone adds a team then, and we override that choice anyway.
                     * Worse, that color message arrives *after* we have overridden the color, so it would
                     * re-override it right back.
                     */
                    if(!isChief()) {
                        TeamIngameAttributes newAttribs = oldEntry.ingameAttribs.withColorIndex(msg.arg1);
                        netRoomState.putTeam(oldEntry.withAttribs(newAttribs));
                    }
                } else {
                    Log.e("Netplay", "Color update for unknown team "+msg.obj);
                }
                break;
            }
            case MSG_HOG_COUNT_CHANGED: {
                TeamInGame oldEntry = netRoomState.getTeams().get((String)msg.obj);
                if(oldEntry != null) {
                    TeamIngameAttributes newAttribs = oldEntry.ingameAttribs.withHogCount(msg.arg1);
                    netRoomState.putTeam(oldEntry.withAttribs(newAttribs));
                } else {
                    Log.e("Netplay", "Hog count update for unknown team "+msg.obj);
                }
                break;
            }
            case MSG_ENGINE_MESSAGE: {
                byte[] em = (byte[])msg.obj;
                for(GameMessageListener listener : gameMessageListeners) {
                    listener.onEngineMessage(em);
                }
                break;
            }
            case MSG_RUN_GAME: {
                GameConfig config = (GameConfig)msg.obj;
                for(RunGameListener listener : runGameListeners) {
                    listener.runGame(config);
                }
                break;
            }
            case MSG_MAP_CHANGED: {
                netRoomState.setMapRecipe((MapRecipe)msg.obj);
                break;
            }
            case MSG_SCHEME_CHANGED: {
                netRoomState.setScheme((Scheme)msg.obj);
                break;
            }
            case MSG_SCRIPT_CHANGED: {
                netRoomState.setGameStyle((String)msg.obj);
                break;
            }
            case MSG_WEAPONSET_CHANGED: {
                netRoomState.setWeaponset((Weaponset)msg.obj);
                break;
            }
            default: {
                Log.e("FromNetHandler", "Unknown message type: "+msg.what);
                break;
            }
            }
        }
    }
}
