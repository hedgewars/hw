package org.hedgewars.hedgeroid.netplay;

import java.io.File;
import java.io.FileNotFoundException;

import org.hedgewars.hedgeroid.R;
import org.hedgewars.hedgeroid.Utils;
import org.hedgewars.hedgeroid.netplay.JnaFrontlib.IntStrCallback;
import org.hedgewars.hedgeroid.netplay.JnaFrontlib.MetaschemePtr;
import org.hedgewars.hedgeroid.netplay.JnaFrontlib.NetconnPtr;
import org.hedgewars.hedgeroid.netplay.JnaFrontlib.RoomArrayPtr;
import org.hedgewars.hedgeroid.netplay.JnaFrontlib.RoomCallback;
import org.hedgewars.hedgeroid.netplay.JnaFrontlib.RoomListCallback;
import org.hedgewars.hedgeroid.netplay.JnaFrontlib.RoomPtr;
import org.hedgewars.hedgeroid.netplay.JnaFrontlib.StrCallback;
import org.hedgewars.hedgeroid.netplay.JnaFrontlib.StrRoomCallback;
import org.hedgewars.hedgeroid.netplay.JnaFrontlib.StrStrCallback;
import org.hedgewars.hedgeroid.netplay.JnaFrontlib.VoidCallback;

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
	
	private static final String ACTIONPREFIX = "org.hedgewars.hedgeroid.netconn.";
	public static final String ACTION_DISCONNECTED = ACTIONPREFIX+"DISCONNECTED";
	public static final String ACTION_CONNECTED = ACTIONPREFIX+"CONNECTED";
	public static final String ACTION_PASSWORD_REQUESTED = ACTIONPREFIX+"PASSWORD_REQUESTED";
	
	public static final String DEFAULT_SERVER = "netserver.hedgewars.org";
	public static final int DEFAULT_PORT = 46631;
		
	private final Context appContext;
	private final LocalBroadcastManager broadcastManager;
	private final FromNetHandler fromNetHandler = new FromNetHandler();
	
	private State state;
	private int foregroundUsers = 0;
	
	// null if there is no running connection (==state is NOT_CONNECTED)
	private ThreadedNetConnection connection;
	
	public final PlayerList playerList = new PlayerList();
	public final RoomList roomList = new RoomList();
	public final MessageLog lobbyChatlog;
	public final MessageLog roomChatlog;
	
	public Netplay(Context appContext) {
		this.appContext = appContext;
		broadcastManager = LocalBroadcastManager.getInstance(appContext);
		lobbyChatlog = new MessageLog(appContext);
		roomChatlog = new MessageLog(appContext);
		state = State.NOT_CONNECTED;
	}
	
	private void clearState() {
		playerList.clear();
		roomList.clear();
		lobbyChatlog.clear();
		roomChatlog.clear();
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
		if(state != State.NOT_CONNECTED) {
			throw new IllegalStateException("Attempt to start a new connection while the old one was still running.");
		}
		
		clearState();
		state = State.CONNECTING;
		connection = ThreadedNetConnection.startConnection(appContext, fromNetHandler, name, host, port);
		connection.setFastTickRate(foregroundUsers > 0);
	}
	
	public void sendNick(String nick) { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_NICK, nick); }
	public void sendPassword(String password) { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_PASSWORD, password); }
	public void sendQuit(String message) { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_QUIT, message); }
	public void sendRoomlistRequest() { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_ROOMLIST_REQUEST); }
	public void sendPlayerInfoQuery(String name) { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_PLAYER_INFO_REQUEST, name); }
	public void sendChat(final String s) { sendToNet(ThreadedNetConnection.ToNetHandler.MSG_SEND_CHAT, s); }
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
		if(connection != null) {
			Handler handler = connection.toNetHandler;
			return handler.sendMessage(handler.obtainMessage(what));
		} else {
			return false;
		}
	}
	
	private boolean sendToNet(int what, Object obj) {
		if(connection != null) {
			Handler handler = connection.toNetHandler;
			return handler.sendMessage(handler.obtainMessage(what, obj));
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
	final class FromNetHandler extends Handler {
		public static final int MSG_LOBBY_JOIN = 0;
		public static final int MSG_LOBBY_LEAVE = 1;
		public static final int MSG_CHAT = 2;
		public static final int MSG_MESSAGE = 3;
		public static final int MSG_ROOM_ADD = 4;
		public static final int MSG_ROOM_UPDATE = 5;
		public static final int MSG_ROOM_DELETE = 6;
		public static final int MSG_ROOMLIST = 7;
		public static final int MSG_CONNECTED = 8;
		public static final int MSG_DISCONNECTED = 9;
		public static final int MSG_PASSWORD_REQUEST = 10;
		
		public FromNetHandler() {
			super(Looper.getMainLooper());
		}
		
		@SuppressWarnings("unchecked")
		@Override
		public void handleMessage(Message msg) {
			switch(msg.what) {
			case MSG_LOBBY_JOIN: {
				String name = (String)msg.obj;
				playerList.addPlayerWithNewId(name);
				lobbyChatlog.appendPlayerJoin(name);
				break;
			}
			case MSG_LOBBY_LEAVE: {
				Pair<String, String> args = (Pair<String, String>)msg.obj;
				playerList.removePlayer(args.first);
				lobbyChatlog.appendPlayerLeave(args.first, args.second);
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
				roomList.addRoomWithNewId((Room)msg.obj);
				break;
			}
			case MSG_ROOM_UPDATE: {
				Pair<String, Room> args = (Pair<String, Room>)msg.obj;
				roomList.updateRoom(args.first, args.second);
				break;
			}
			case MSG_ROOM_DELETE: {
				roomList.removeRoom((String)msg.obj);
				break;
			}
			case MSG_ROOMLIST: {
				roomList.updateList((Room[])msg.obj);
				break;
			}
			case MSG_CONNECTED: {
				state = State.LOBBY;
				broadcastManager.sendBroadcast(new Intent(ACTION_CONNECTED));
				break;
			}
			case MSG_DISCONNECTED: {
				Pair<Boolean, String> args = (Pair<Boolean, String>)msg.obj;
				state = State.NOT_CONNECTED;
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
		private static final JnaFrontlib FLIB = Flib.INSTANCE;
		
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
					FLIB.flib_netconn_onChat(conn, chatCb, null);
					FLIB.flib_netconn_onMessage(conn, messageCb, null);
					FLIB.flib_netconn_onRoomAdd(conn, roomAddCb, null);
					FLIB.flib_netconn_onRoomUpdate(conn, roomUpdateCb, null);
					FLIB.flib_netconn_onRoomDelete(conn, roomDeleteCb, null);
					FLIB.flib_netconn_onConnected(conn, connectedCb, null);
					FLIB.flib_netconn_onRoomlist(conn, roomlistCb, null);
					FLIB.flib_netconn_onDisconnected(conn, disconnectCb, null);
					FLIB.flib_netconn_onPasswordRequest(conn, passwordRequestCb, null);
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
				Boolean error = reason != JnaFrontlib.NETCONN_DISCONNECT_NORMAL;
				String messageForUser = createDisconnectUserMessage(appContext.getResources(), reason, message);
				shutdown(error, messageForUser);
			}
		};
		
		private static String createDisconnectUserMessage(Resources res, int reason, String message) {
			switch(reason) {
			case JnaFrontlib.NETCONN_DISCONNECT_AUTH_FAILED:
				return res.getString(R.string.error_auth_failed);
			case JnaFrontlib.NETCONN_DISCONNECT_CONNLOST:
				return res.getString(R.string.error_connection_lost, message);
			case JnaFrontlib.NETCONN_DISCONNECT_INTERNAL_ERROR:
				return res.getString(R.string.error_unexpected, message);
			case JnaFrontlib.NETCONN_DISCONNECT_SERVER_TOO_OLD:
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
		public final class ToNetHandler extends Handler {
			public static final int MSG_SEND_NICK = 0;
			public static final int MSG_SEND_PASSWORD = 1;
			public static final int MSG_SEND_QUIT = 2;
			public static final int MSG_SEND_ROOMLIST_REQUEST = 3;
			public static final int MSG_SEND_PLAYER_INFO_REQUEST = 4;
			public static final int MSG_SEND_CHAT = 5;
			public static final int MSG_DISCONNECT = 6;
			
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
					FLIB.flib_netconn_send_request_roomlist(conn); // TODO restrict to lobby state?
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
				case MSG_DISCONNECT: {
					FLIB.flib_netconn_send_quit(conn, (String)msg.obj);
					shutdown(false, "User quit");
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
