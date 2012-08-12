package org.hedgewars.hedgeroid.netplay;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.Map;
import java.util.TreeMap;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Utils;
import org.hedgewars.hedgeroid.Datastructures.RoomlistRoom;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.Datastructures.TeamIngameAttributes;
import org.hedgewars.hedgeroid.frontlib.Flib;
import org.hedgewars.hedgeroid.frontlib.Frontlib;
import org.hedgewars.hedgeroid.frontlib.Frontlib.BoolCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.IntStrCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.MetaschemePtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.NetconnPtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.RoomArrayPtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.RoomCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.RoomListCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.RoomPtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.StrBoolCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.StrCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.StrIntCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.StrRoomCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.StrStrCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.TeamCallback;
import org.hedgewars.hedgeroid.frontlib.Frontlib.TeamPtr;
import org.hedgewars.hedgeroid.frontlib.Frontlib.VoidCallback;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.content.res.Resources;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;
import android.os.Message;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;
import android.util.Pair;

import com.sun.jna.Pointer;

/**
 * This class manages the application's networking state.
 */
public class Netplay {
	public static enum State { NOT_CONNECTED, CONNECTING, LOBBY, ROOM, INGAME }
	
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
	
	private State state = State.NOT_CONNECTED;
	private int foregroundUsers = 0;	// Reference counter of clients requesting foreground tick speed (fast ticks)
	private boolean chief;				// Do we control the current room?
	private String playerName;
	
	// null if there is no running connection (==state is NOT_CONNECTED)
	private ThreadedNetConnection connection;
	
	public final LobbyPlayerlist lobbyPlayerlist = new LobbyPlayerlist();
	public final RoomPlayerlist roomPlayerlist = new RoomPlayerlist();
	public final Roomlist roomList = new Roomlist();
	public final MessageLog lobbyChatlog;
	public final MessageLog roomChatlog;
	public final Teamlist roomTeamlist = new Teamlist();
	private final Map<String, Team> roomRequestedTeams = new TreeMap<String, Team>();
	
	public Netplay(Context appContext) {
		this.appContext = appContext;
		broadcastManager = LocalBroadcastManager.getInstance(appContext);
		lobbyChatlog = new MessageLog(appContext);
		roomChatlog = new MessageLog(appContext);
	}
	
	private void clearState() {
		lobbyPlayerlist.clear();
		roomList.clear();
		lobbyChatlog.clear();
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
		
		clearState();
		changeState(State.CONNECTING);
		connection = ThreadedNetConnection.startConnection(appContext, fromNetHandler, name, host, port);
		connection.setFastTickRate(foregroundUsers > 0);
	}
	
	public void sendNick(String nick) {
		playerName = nick;
		sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_NICK, nick);
	}
	public void sendPassword(String password) { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_PASSWORD, password); }
	public void sendQuit(String message) { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_QUIT, message); }
	public void sendRoomlistRequest() { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_ROOMLIST_REQUEST); }
	public void sendPlayerInfoQuery(String name) { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_PLAYER_INFO_REQUEST, name); }
	public void sendChat(String s) { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_CHAT, s); }
	public void sendFollowPlayer(String nick) { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_FOLLOW_PLAYER, nick); }
	public void sendJoinRoom(String name) { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_JOIN_ROOM, name); }
	public void sendCreateRoom(String name) { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_CREATE_ROOM, name); }
	public void sendLeaveRoom(String message) { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_LEAVE_ROOM, message); }
	public void sendKick(String player) { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_KICK, player); }
	public void sendAddTeam(Team newTeam) {
		roomRequestedTeams.put(newTeam.name, newTeam);
		sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_ADD_TEAM, newTeam);
	}
	public void sendRemoveTeam(String teamName) { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_REMOVE_TEAM, teamName); }
	public void sendTeamColorIndex(String teamName, int colorIndex) { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_TEAM_COLOR_INDEX, colorIndex, teamName); }
	public void sendTeamHogCount(String teamName, int hogCount) { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_TEAM_HOG_COUNT, hogCount, teamName); }
	
	public void disconnect() { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_DISCONNECT, "User Quit"); }
	
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
			// We'll just do it here and never quit it again...
			if(Flib.INSTANCE.flib_init() != 0) {
				throw new RuntimeException("Unable to start frontlib");
			}
			instance = new Netplay(applicationContext);
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
		return chief;
	}
	
	public String getPlayerName() {
		return playerName;
	}
	
	/**
	 * Indicate that you want network messages to be checked regularly (several times per second).
	 * As long as nobody requests fast ticks, the network is only checked once every few seconds
	 * to conserve battery power.
	 * Once you no longer need fast updates, call unrequestFastTicks.
	 */
	public void requestFastTicks() {
		if(foregroundUsers == Integer.MAX_VALUE) {
			throw new RuntimeException("Reference counter overflow");
		}
		if(foregroundUsers == 0 && connection != null) {
			connection.setFastTickRate(true);
		}
		foregroundUsers++;
	}
	
	public void unrequestFastTicks() {
		if(foregroundUsers == 0) {
			throw new RuntimeException("Reference counter underflow");
		}
		foregroundUsers--;
		if(foregroundUsers == 0 && connection != null) {
			connection.setFastTickRate(false);
		}
	}
	
	private boolean sendToNet(int what) {
		return sendToNet(what, 0, null);
	}
	
	private boolean sendToNet(int what, Object obj) {
		return sendToNet(what, 0, obj);
	}
	
	private boolean sendToNet(int what, int arg1, Object obj) {
		if(connection != null) {
			Handler handler = connection.toNetHandler;
			return handler.sendMessage(handler.obtainMessage(what, arg1, 0, obj));
		} else {
			return false;
		}
	}
	
	private MessageLog getCurrentLog() {
		if(state == State.ROOM || state == State.INGAME) {
			return roomChatlog;
		} else {
			return lobbyChatlog;
		}
	}
	
	/**
	 * Processes messages from the networking system. Always runs on the main thread.
	 */
	@SuppressLint("HandlerLeak")
	final class FromNetHandler extends Handler {
		public static final int MSG_LOBBY_JOIN = 0;
		public static final int MSG_LOBBY_LEAVE = 1;
		public static final int MSG_ROOM_JOIN = 2;
		public static final int MSG_ROOM_LEAVE = 3;
		public static final int MSG_CHAT = 4;
		public static final int MSG_MESSAGE = 5;
		public static final int MSG_ROOM_ADD = 6;
		public static final int MSG_ROOM_UPDATE = 7;
		public static final int MSG_ROOM_DELETE = 8;
		public static final int MSG_ROOMLIST = 9;
		public static final int MSG_CONNECTED = 10;
		public static final int MSG_DISCONNECTED = 11;
		public static final int MSG_PASSWORD_REQUEST = 12;
		public static final int MSG_ENTER_ROOM_FROM_LOBBY = 13;
		public static final int MSG_LEAVE_ROOM = 14;
		public static final int MSG_READYSTATE = 15;
		public static final int MSG_TEAM_ADDED = 16;
		public static final int MSG_TEAM_DELETED = 17;
		public static final int MSG_TEAM_ACCEPTED = 18;
		public static final int MSG_TEAM_COLOR_CHANGED = 19;
		public static final int MSG_HOG_COUNT_CHANGED = 20;
		
		public FromNetHandler() {
			super(Looper.getMainLooper());
		}
		
		@SuppressWarnings("unchecked")
		@Override
		public void handleMessage(Message msg) {
			switch(msg.what) {
			case MSG_LOBBY_JOIN: {
				String name = (String)msg.obj;
				lobbyPlayerlist.addPlayerWithNewId(name);
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
				roomPlayerlist.addPlayerWithNewId(name);
				roomChatlog.appendPlayerJoin(name);
				break;
			}
			case MSG_ROOM_LEAVE: {
				Pair<String, String> args = (Pair<String, String>)msg.obj;
				roomPlayerlist.remove(args.first);
				roomChatlog.appendPlayerLeave(args.first, args.second);
				break;
			}
			case MSG_CHAT: {
				Pair<String, String> args = (Pair<String, String>)msg.obj;
				getCurrentLog().appendChat(args.first, args.second);
				break;
			}
			case MSG_MESSAGE: {
				getCurrentLog().appendMessage(msg.arg1, (String)msg.obj);
				break;
			}
			case MSG_ROOM_ADD: {
				roomList.addRoomWithNewId((RoomlistRoom)msg.obj);
				break;
			}
			case MSG_ROOM_UPDATE: {
				Pair<String, RoomlistRoom> args = (Pair<String, RoomlistRoom>)msg.obj;
				roomList.updateRoom(args.first, args.second);
				break;
			}
			case MSG_ROOM_DELETE: {
				roomList.remove((String)msg.obj);
				break;
			}
			case MSG_ROOMLIST: {
				roomList.updateList((RoomlistRoom[])msg.obj);
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
				roomChatlog.clear();
				roomPlayerlist.clear();
				roomTeamlist.clear();
				roomRequestedTeams.clear();
				changeState(State.ROOM);
				chief = (Boolean)msg.obj;
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
			case MSG_READYSTATE: {
				Pair<String, Boolean> args = (Pair<String, Boolean>)msg.obj;
				roomPlayerlist.setReady(args.first, args.second);
				break;
			}
			case MSG_TEAM_ADDED: {
				Team newTeam = (Team)msg.obj;
				TeamIngameAttributes attrs = new TeamIngameAttributes(playerName, roomTeamlist.getUnusedOrRandomColorIndex(), TeamIngameAttributes.DEFAULT_HOG_COUNT, false);
				TeamInGame tig = new TeamInGame(newTeam, attrs);
				roomTeamlist.addTeamWithNewId(tig);
				if(chief) {
					sendTeamColorIndex(newTeam.name, attrs.colorIndex);
					sendTeamHogCount(newTeam.name, attrs.hogCount);
				}
				break;
			}
			case MSG_TEAM_DELETED: {
				roomTeamlist.remove((String)msg.obj);
				break;
			}
			case MSG_TEAM_ACCEPTED: {
				Team requestedTeam = roomRequestedTeams.remove(msg.obj);
				if(requestedTeam!=null) {
					TeamIngameAttributes attrs = new TeamIngameAttributes(playerName, roomTeamlist.getUnusedOrRandomColorIndex(), TeamIngameAttributes.DEFAULT_HOG_COUNT, false);
					TeamInGame tig = new TeamInGame(requestedTeam, attrs);
					roomTeamlist.addTeamWithNewId(tig);
					if(chief) {
						sendTeamColorIndex(requestedTeam.name, attrs.colorIndex);
						sendTeamHogCount(requestedTeam.name, attrs.hogCount);
					}
				} else {
					Log.e("Netplay", "Got accepted message for team that was never requested.");
				}
				break;
			}
			case MSG_TEAM_COLOR_CHANGED: {
				Pair<TeamInGame, Long> oldEntry = roomTeamlist.get((String)msg.obj);
				if(oldEntry != null) {
					TeamInGame tig = oldEntry.first;
					TeamIngameAttributes tiga = tig.ingameAttribs.withColorIndex(msg.arg1);
					roomTeamlist.put(tig.team.name, Pair.create(tig.withAttribs(tiga), oldEntry.second));
				} else {
					Log.e("Netplay", "Color update for unknown team "+msg.obj);
				}
				break;
			}
			case MSG_HOG_COUNT_CHANGED: {
				Pair<TeamInGame, Long> oldEntry = roomTeamlist.get((String)msg.obj);
				if(oldEntry != null) {
					TeamInGame tig = oldEntry.first;
					TeamIngameAttributes tiga = tig.ingameAttribs.withHogCount(msg.arg1);
					roomTeamlist.put(tig.team.name, Pair.create(tig.withAttribs(tiga), oldEntry.second));
				} else {
					Log.e("Netplay", "Hog count update for unknown team "+msg.obj);
				}
				break;
			}
			default: {
				Log.e("FromNetHandler", "Unknown message type: "+msg.what);
				break;
			}
			}
		}
	}
	
	/**
	 * This class handles the actual communication with the networking library, on a separate thread.
	 */
	private static class ThreadedNetConnection {
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
					MetaschemePtr meta = null;
					File dataPath;
					try {
						dataPath = Utils.getDataPathFile(appContext);
					} catch (FileNotFoundException e) {
						shutdown(true, appContext.getString(R.string.sdcard_not_mounted));
						return;
					}
					String metaschemePath = new File(dataPath, "metasettings.ini").getAbsolutePath();
					meta = FLIB.flib_metascheme_from_ini(metaschemePath);
					if(meta == null) {
						shutdown(true, appContext.getString(R.string.error_unexpected, "Missing metasettings.ini"));
						return;
					}
					conn = FLIB.flib_netconn_create(playerName, meta, dataPath.getAbsolutePath(), host, port);
					if(conn == null) {
						shutdown(true, appContext.getString(R.string.error_connection_failed));
						return;
					}
					FLIB.flib_netconn_onLobbyJoin(conn, lobbyJoinCb, null);
					FLIB.flib_netconn_onLobbyLeave(conn, lobbyLeaveCb, null);
					FLIB.flib_netconn_onRoomJoin(conn, roomJoinCb, null);
					FLIB.flib_netconn_onRoomLeave(conn, roomLeaveCb, null);
					FLIB.flib_netconn_onChat(conn, chatCb, null);
					FLIB.flib_netconn_onMessage(conn, messageCb, null);
					FLIB.flib_netconn_onRoomAdd(conn, roomAddCb, null);
					FLIB.flib_netconn_onRoomUpdate(conn, roomUpdateCb, null);
					FLIB.flib_netconn_onRoomDelete(conn, roomDeleteCb, null);
					FLIB.flib_netconn_onConnected(conn, connectedCb, null);
					FLIB.flib_netconn_onRoomlist(conn, roomlistCb, null);
					FLIB.flib_netconn_onDisconnected(conn, disconnectCb, null);
					FLIB.flib_netconn_onPasswordRequest(conn, passwordRequestCb, null);
					FLIB.flib_netconn_onEnterRoom(conn, enterRoomCb, null);
					FLIB.flib_netconn_onLeaveRoom(conn, leaveRoomCb, null);
					FLIB.flib_netconn_onReadyState(conn, readyStateCb, null);
					FLIB.flib_netconn_onTeamAdd(conn, teamAddedCb, null);
					FLIB.flib_netconn_onTeamDelete(conn, teamDeletedCb, null);
					FLIB.flib_netconn_onTeamAccepted(conn, teamAcceptedCb, null);
					FLIB.flib_netconn_onTeamColorChanged(conn, teamColorChangedCb, null);
					FLIB.flib_netconn_onHogCountChanged(conn, hogCountChangedCb, null);
					
					FLIB.flib_metascheme_release(meta);
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
		
		private final StrCallback lobbyJoinCb = new StrCallback() {
			public void callback(Pointer context, String name) {
				sendFromNet(FromNetHandler.MSG_LOBBY_JOIN, name);
			}
		};
		
		private final StrStrCallback lobbyLeaveCb = new StrStrCallback() {
			public void callback(Pointer context, String name, String msg) {
				sendFromNet(FromNetHandler.MSG_LOBBY_LEAVE, Pair.create(name, msg));
			}
		};
		
		private final StrCallback roomJoinCb = new StrCallback() {
			public void callback(Pointer context, String name) {
				sendFromNet(FromNetHandler.MSG_ROOM_JOIN, name);
			}
		};
		private final StrStrCallback roomLeaveCb = new StrStrCallback() {
			public void callback(Pointer context, String name, String message) {
				sendFromNet(FromNetHandler.MSG_ROOM_LEAVE, Pair.create(name, message));
			}
		};
		private final StrStrCallback chatCb = new StrStrCallback() {
			public void callback(Pointer context, String name, String msg) {
				sendFromNet(FromNetHandler.MSG_CHAT, Pair.create(name, msg));
			}
		};
		
		private final IntStrCallback messageCb = new IntStrCallback() {
			public void callback(Pointer context, int type, String msg) {
				sendFromNet(FromNetHandler.MSG_MESSAGE, type, msg);
			}
		};
		
		private final RoomCallback roomAddCb = new RoomCallback() {
			public void callback(Pointer context, RoomPtr roomPtr) {
				sendFromNet(FromNetHandler.MSG_ROOM_ADD, roomPtr.deref());
			}
		};
		
		private final StrRoomCallback roomUpdateCb = new StrRoomCallback() {
			public void callback(Pointer context, String name, RoomPtr roomPtr) {
				sendFromNet(FromNetHandler.MSG_ROOM_UPDATE, Pair.create(name, roomPtr.deref()));
			}
		};
		
		private final StrCallback roomDeleteCb = new StrCallback() {
			public void callback(Pointer context, final String name) {
				sendFromNet(FromNetHandler.MSG_ROOM_DELETE, name);
			}
		};
		
		private final RoomListCallback roomlistCb = new RoomListCallback() {
			public void callback(Pointer context, RoomArrayPtr arg1, int count) {
				sendFromNet(FromNetHandler.MSG_ROOMLIST, arg1.getRooms(count));
			}
		};
		
		private final VoidCallback connectedCb = new VoidCallback() {
			public void callback(Pointer context) {
				FLIB.flib_netconn_send_request_roomlist(conn);
				playerName = FLIB.flib_netconn_get_playername(conn);
				sendFromNet(FromNetHandler.MSG_CONNECTED, playerName);
			}
		};
		
		private final StrCallback passwordRequestCb = new StrCallback() {
			public void callback(Pointer context, String nickname) {
				sendFromNet(FromNetHandler.MSG_PASSWORD_REQUEST, playerName);
			}
		};
		
		private final BoolCallback enterRoomCb = new BoolCallback() {
			public void callback(Pointer context, boolean isChief) {
				sendFromNet(FromNetHandler.MSG_ENTER_ROOM_FROM_LOBBY, isChief);
			}
		};
		
		private final IntStrCallback leaveRoomCb = new IntStrCallback() {
			public void callback(Pointer context, int reason, String message) {
				sendFromNet(FromNetHandler.MSG_LEAVE_ROOM, reason, message);
			}
		};
		
		private final StrBoolCallback readyStateCb = new StrBoolCallback() {
			public void callback(Pointer context, String player, boolean ready) {
				sendFromNet(FromNetHandler.MSG_READYSTATE, Pair.create(player, ready));
			}
		};
		
		private final TeamCallback teamAddedCb = new TeamCallback() {
			public void callback(Pointer context, TeamPtr team) {
				sendFromNet(FromNetHandler.MSG_TEAM_ADDED, team.deref().team);
			}
		};
		
		private final StrCallback teamDeletedCb = new StrCallback() {
			public void callback(Pointer context, String teamName) {
				sendFromNet(FromNetHandler.MSG_TEAM_DELETED, teamName);
			}
		};
		
		private final StrCallback teamAcceptedCb = new StrCallback() {
			public void callback(Pointer context, String teamName) {
				sendFromNet(FromNetHandler.MSG_TEAM_ACCEPTED, teamName);
			}
		};
		
		private final StrIntCallback teamColorChangedCb = new StrIntCallback() {
			public void callback(Pointer context, String teamName, int colorIndex) {
				sendFromNet(FromNetHandler.MSG_TEAM_COLOR_CHANGED, colorIndex, teamName);
			}
		};
		
		private final StrIntCallback hogCountChangedCb = new StrIntCallback() {
			public void callback(Pointer context, String teamName, int hogCount) {
				sendFromNet(FromNetHandler.MSG_HOG_COUNT_CHANGED, hogCount, teamName);
			}
		};
		
		private void shutdown(boolean error, String message) {
			if(conn != null) {
				FLIB.flib_netconn_destroy(conn);
				conn = null;
			}
			tickHandler.stop();
			toNetHandler.getLooper().quit();
			sendFromNet(FromNetHandler.MSG_DISCONNECTED, Pair.create(error, message));
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
		
		private boolean sendFromNet(int what, Object obj) {
			return fromNetHandler.sendMessage(fromNetHandler.obtainMessage(what, obj));
		}
		
		private boolean sendFromNet(int what, int arg1, Object obj) {
			return fromNetHandler.sendMessage(fromNetHandler.obtainMessage(what, arg1, 0, obj));
		}
		
		/**
		 * Processes messages to the networking system. Runs on a non-main thread.
		 */
		@SuppressLint("HandlerLeak")
		public final class ToNetHandler extends Handler {
			public static final int MSG_SEND_NICK = 0;
			public static final int MSG_SEND_PASSWORD = 1;
			public static final int MSG_SEND_QUIT = 2;
			public static final int MSG_SEND_ROOMLIST_REQUEST = 3;
			public static final int MSG_SEND_PLAYER_INFO_REQUEST = 4;
			public static final int MSG_SEND_CHAT = 5;
			public static final int MSG_SEND_FOLLOW_PLAYER = 6;
			public static final int MSG_SEND_JOIN_ROOM = 7;
			public static final int MSG_SEND_CREATE_ROOM = 8;
			public static final int MSG_SEND_LEAVE_ROOM = 9;
			public static final int MSG_SEND_KICK = 10;
			public static final int MSG_SEND_ADD_TEAM = 11;
			public static final int MSG_SEND_REMOVE_TEAM = 12;
			public static final int MSG_DISCONNECT = 13;
			public static final int MSG_SEND_TEAM_COLOR_INDEX = 14;
			public static final int MSG_SEND_TEAM_HOG_COUNT = 15;
			
			public ToNetHandler(Looper looper) {
				super(looper);
			}
			
			@Override
			public void handleMessage(Message msg) {
				switch(msg.what) {
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
						sendFromNet(FromNetHandler.MSG_CHAT, Pair.create(playerName, (String)msg.obj));
					}
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
						sendFromNet(FromNetHandler.MSG_LEAVE_ROOM, -1, "");
					}
					break;
				}
				case MSG_SEND_KICK: {
					FLIB.flib_netconn_send_kick(conn, (String)msg.obj);
					break;
				}
				case MSG_SEND_ADD_TEAM: {
					FLIB.flib_netconn_send_addTeam(conn, TeamPtr.createJavaOwned((Team)msg.obj));
					break;
				}
				case MSG_SEND_REMOVE_TEAM: {
					if(FLIB.flib_netconn_send_removeTeam(conn, (String)msg.obj)==0) {
						sendFromNet(FromNetHandler.MSG_TEAM_DELETED, msg.obj);
					}
					break;
				}
				case MSG_DISCONNECT: {
					FLIB.flib_netconn_send_quit(conn, (String)msg.obj);
					shutdown(false, "User quit");
					break;
				}
				case MSG_SEND_TEAM_COLOR_INDEX: {
					if(FLIB.flib_netconn_send_teamColor(conn, (String)msg.obj, msg.arg1)==0) {
						sendFromNet(FromNetHandler.MSG_TEAM_COLOR_CHANGED, msg.arg1, msg.obj);
					}
					break;
				}
				case MSG_SEND_TEAM_HOG_COUNT: {
					if(FLIB.flib_netconn_send_teamHogCount(conn, (String)msg.obj, msg.arg1)==0) {
						sendFromNet(FromNetHandler.MSG_HOG_COUNT_CHANGED, msg.arg1, msg.obj);
					}
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
}
