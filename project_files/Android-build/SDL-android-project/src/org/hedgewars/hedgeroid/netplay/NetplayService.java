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

import com.sun.jna.Pointer;

import android.app.Service;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;

public class NetplayService extends Service {
	// Parameter extras for starting the service
	public static final String EXTRA_PLAYERNAME = "playername";
	public static final String EXTRA_PORT = "port";
	public static final String EXTRA_HOST = "host";
	
	// Extras in broadcasts
	public static final String EXTRA_MESSAGE = "message";
	public static final String EXTRA_HAS_ERROR = "hasError";
	
	
	private static final String ACTIONPREFIX = "org.hedgewars.hedgeroid.netconn.";
	public static final String ACTION_DISCONNECTED = ACTIONPREFIX+"DISCONNECTED";
	public static final String ACTION_CONNECTED = ACTIONPREFIX+"CONNECTED";
	
	private static final JnaFrontlib FLIB = Flib.INSTANCE;
	public static final String DEFAULT_SERVER = "netserver.hedgewars.org";
	public static final int DEFAULT_PORT = 46631;
	
	private static final long TICK_INTERVAL_MS_BOUND = 100;
	private static final long TICK_INTERVAL_MS_UNBOUND = 2000;
	
	// null if the service is not active. Only updated from the main thread.
	public static NetplayService instance;
	
	private final NetplayBinder binder = new NetplayBinder();
	private TickHandler tickHandler;
	private LocalBroadcastManager broadcastManager;
	
	private String playerName;
	private NetconnPtr conn;
	private boolean joined; // True once we have been admitted to the lobby
	
	public final PlayerList playerList = new PlayerList();
	public final RoomList roomList = new RoomList();
	public MessageLog lobbyChatlog;
	public MessageLog roomChatlog;
	
	@Override
	public IBinder onBind(Intent intent) {
		Log.d("NetplayService", "onBind");
		tickHandler.setInterval(TICK_INTERVAL_MS_BOUND);
		return binder;
	}
	
	@Override
	public void onRebind(Intent intent) {
		Log.d("NetplayService", "onRebind");
		tickHandler.setInterval(TICK_INTERVAL_MS_BOUND);
	}
	
	@Override
	public boolean onUnbind(Intent intent) {
		Log.d("NetplayService", "onUnbind");
		tickHandler.setInterval(TICK_INTERVAL_MS_UNBOUND);
		return true;
	}
	
	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		Log.d("NetplayService", "onStartCommand");
		if(conn != null) {
			Log.e("NetplayService", "Attempt to start while running");
			return START_NOT_STICKY;
		}
		joined = false;
		playerList.clear();
		roomList.clear();
		lobbyChatlog.clear();
		roomChatlog.clear();
		
		playerName = intent.getStringExtra(EXTRA_PLAYERNAME);
		if(playerName == null) playerName = "Player";
		int port = intent.getIntExtra(EXTRA_PORT, DEFAULT_PORT);
		String host = intent.getStringExtra(EXTRA_HOST);
		if(host==null) host = DEFAULT_SERVER;
		
		MetaschemePtr meta = null;
		File dataPath;
		try {
			dataPath = Utils.getDataPathFile(getApplicationContext());
		} catch (FileNotFoundException e) {
			stopWithError(getString(R.string.sdcard_not_mounted));
			return START_NOT_STICKY;
		}
		String metaschemePath = new File(dataPath, "metasettings.ini").getAbsolutePath();
		meta = FLIB.flib_metascheme_from_ini(metaschemePath);
		if(meta == null) {
			stopWithError(getString(R.string.error_unexpected, "Missing metasettings.ini"));
			return START_NOT_STICKY;
		}
		conn = FLIB.flib_netconn_create(playerName, meta, dataPath.getAbsolutePath(), host, port);
		if(conn == null) {
			stopWithError(getString(R.string.error_connection_failed));
			return START_NOT_STICKY;
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
		FLIB.flib_metascheme_release(meta);
		tickHandler.start();
		instance = this;
		return START_NOT_STICKY;
	}
	
	private void stopWithoutError() {
		Intent intent = new Intent(ACTION_DISCONNECTED);
		intent.putExtra(EXTRA_HAS_ERROR, false);
		broadcastManager.sendBroadcast(intent);
		stopSelf();
	}
	
	private void stopWithError(String userMessage) {
		Intent intent = new Intent(ACTION_DISCONNECTED);
		intent.putExtra(EXTRA_MESSAGE, userMessage);
		intent.putExtra(EXTRA_HAS_ERROR, true);
		broadcastManager.sendBroadcast(intent);
		stopSelf();
	}
	
	@Override
	public void onCreate() {
		Log.d("NetplayService", "onCreate");
		broadcastManager = LocalBroadcastManager.getInstance(getApplicationContext());
		lobbyChatlog = new MessageLog(getApplicationContext());
		roomChatlog = new MessageLog(getApplicationContext());
		tickHandler = new TickHandler(getMainLooper(), TICK_INTERVAL_MS_UNBOUND, new Runnable() {
			public void run() {
				if(conn != null) {
					FLIB.flib_netconn_tick(conn);
				}
			}
		});
		if(Flib.INSTANCE.flib_init() != 0) {
			stopWithError(getString(R.string.error_unexpected, "Unable to start frontlib"));
		}
	}
	
	@Override
	public void onDestroy() {
		instance = null;
		Log.d("NetplayService", "onDestroy");
		tickHandler.stop();
		if(conn != null) {
			FLIB.flib_netconn_destroy(conn);
			conn = null;
		}
		Flib.INSTANCE.flib_quit();
	}

	public class NetplayBinder extends Binder {
		NetplayService getService() {
            return NetplayService.this;
        }
	}
	
	private StrCallback lobbyJoinCb = new StrCallback() {
		public void callback(Pointer context, String arg1) {
			playerList.addPlayerWithNewId(arg1);
			lobbyChatlog.appendPlayerJoin(arg1);
		}
	};
	
	private StrStrCallback lobbyLeaveCb = new StrStrCallback() {
		public void callback(Pointer context, String name, String msg) {
			playerList.removePlayer(name);
			lobbyChatlog.appendPlayerLeave(name, msg);
		}
	};
	
	private StrStrCallback chatCb = new StrStrCallback() {
		public void callback(Pointer context, String name, String msg) {
			getCurrentLog().appendChat(name, msg);
		}
	};
	
	private IntStrCallback messageCb = new IntStrCallback() {
		public void callback(Pointer context, int type, String msg) {
			getCurrentLog().appendMessage(type, msg);
		}
	};
	
	private RoomCallback roomAddCb = new RoomCallback() {
		public void callback(Pointer context, RoomPtr roomPtr) {
			roomList.addRoomWithNewId(roomPtr);
		}
	};
	
	private StrRoomCallback roomUpdateCb = new StrRoomCallback() {
		public void callback(Pointer context, String name, RoomPtr roomPtr) {
			roomList.updateRoom(name, roomPtr);
		}
	};
	
	private StrCallback roomDeleteCb = new StrCallback() {
		public void callback(Pointer context, String name) {
			roomList.removeRoom(name);
		}
	};
	
	private VoidCallback connectedCb = new VoidCallback() {
		public void callback(Pointer context) {
			broadcastManager.sendBroadcast(new Intent(ACTION_CONNECTED));
			joined = true;
			FLIB.flib_netconn_send_request_roomlist(conn);
		}
	};
	
	private RoomListCallback roomlistCb = new RoomListCallback() {
		public void callback(Pointer context, RoomArrayPtr arg1, int count) {
			roomList.updateList(arg1.getRooms(count));
		}
	};
	
	private IntStrCallback disconnectCb = new IntStrCallback() {
		public void callback(Pointer context, int reason, String arg2) {
			switch(reason) {
			case JnaFrontlib.NETCONN_DISCONNECT_AUTH_FAILED:
				stopWithError(getString(R.string.error_auth_failed));
				break;
			case JnaFrontlib.NETCONN_DISCONNECT_CONNLOST:
				stopWithError(getString(R.string.error_connection_lost));
				break;
			case JnaFrontlib.NETCONN_DISCONNECT_INTERNAL_ERROR:
				stopWithError(getString(R.string.error_unexpected, arg2));
				break;
			case JnaFrontlib.NETCONN_DISCONNECT_NORMAL:
				stopWithoutError();
				break;
			case JnaFrontlib.NETCONN_DISCONNECT_SERVER_TOO_OLD:
				stopWithError(getString(R.string.error_server_too_old));
				break;
			default:
				stopWithError(arg2);
				break;
			}
			FLIB.flib_netconn_destroy(conn);
			conn = null;
		}
	};
	
	public void disconnect() {
		if(conn != null) {
			FLIB.flib_netconn_send_quit(conn, "User quit");
			FLIB.flib_netconn_destroy(conn);
			conn = null;
		}
		stopWithoutError();
	}
	
	public void sendChat(String s) {
		FLIB.flib_netconn_send_chat(conn, s);
		if(FLIB.flib_netconn_is_in_room_context(conn)) {
			roomChatlog.appendChat(playerName, s);
		} else {
			lobbyChatlog.appendChat(playerName, s);
		}
	}
	
	private MessageLog getCurrentLog() {
		if(FLIB.flib_netconn_is_in_room_context(conn)) {
			return roomChatlog;
		} else {
			return lobbyChatlog;
		}
	}
	
	public void sendNick(String nick) { FLIB.flib_netconn_send_nick(conn, nick); }
	public void sendPassword(String password) { FLIB.flib_netconn_send_password(conn, password); }
	public void sendQuit(String message) { FLIB.flib_netconn_send_quit(conn, message); }
	public void sendRoomlistRequest() { if(joined) FLIB.flib_netconn_send_request_roomlist(conn); }
	public void sendPlayerInfoQuery(String name) { FLIB.flib_netconn_send_playerInfo(conn, name); }
	
	public boolean isConnected() {
		return conn != null;
	}

	public static boolean isActive() {
		return instance!=null;
	}
}

