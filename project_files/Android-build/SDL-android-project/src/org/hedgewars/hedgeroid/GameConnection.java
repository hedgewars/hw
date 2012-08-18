package org.hedgewars.hedgeroid;

import org.hedgewars.hedgeroid.Datastructures.GameConfig;
import org.hedgewars.hedgeroid.frontlib.Flib;
import org.hedgewars.hedgeroid.frontlib.Frontlib;
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

import com.sun.jna.Memory;
import com.sun.jna.Pointer;

public final class GameConnection {
	private static final Handler mainHandler = new Handler(Looper.getMainLooper());
	
	private final HandlerThread thread;
	private final Handler handler;
	private final TickHandler tickHandler;
	private final Netplay netplay; // ==null if not a netgame
	private GameconnPtr conn;

	/**
	 * The actual connection has to be set up on a separate thread because networking
	 * is not allowed on the UI thread, so the port can't be queried immediately after
	 * creating the GameConnection object. Instead, one of these interface methods is
	 * called once we know which port we are listening on (or once we fail to set this up).
	 * Methods will be called on the UI thread.
	 */
	public static interface Listener {
		/**
		 * We are listening for the engine at $port, go start the engine.
		 */
		void gameConnectionReady(int port);
		
		/**
		 * The connection has stopped, either because the game has ended or was interrupted,
		 * or maybe we failed to create the connection at all (in that case gameConnectionReady wasn't called).
		 */
		void gameConnectionDisconnected(int reason);
	}
	
	private GameConnection(Netplay netplay) {
		this.netplay = netplay;
		thread = new HandlerThread("IPCThread");
		thread.start();
		handler = new Handler(thread.getLooper());
		tickHandler = new TickHandler(thread.getLooper(), 50, new Runnable() {
			public void run() {
				if(conn != null) {
					Flib.INSTANCE.flib_gameconn_tick(conn);
				}
			}
		});
		tickHandler.start();
	}
	
	public static GameConnection forNetgame(final GameConfig config, Netplay netplay, final Listener listener) {
		final GameConnection result = new GameConnection(netplay);
		final String playerName = netplay.getPlayerName();
		result.handler.post(new Runnable() {
			public void run() {
				GameconnPtr conn = Flib.INSTANCE.flib_gameconn_create(playerName, GameSetupPtr.createJavaOwned(config), true);
				result.setupConnection(conn, true, listener);
			}
		});
		return result;
	}
	
	public static GameConnection forLocalGame(final GameConfig config, final Listener listener) {
		final GameConnection result = new GameConnection(null);
		result.handler.post(new Runnable() {
			public void run() {
				GameconnPtr conn = Flib.INSTANCE.flib_gameconn_create("Player", GameSetupPtr.createJavaOwned(config), false);
				result.setupConnection(conn, false, listener);
			}
		});
		return result;
	}
	
	// runs on the IPCThread
	private void setupConnection(GameconnPtr conn, final boolean netgame, final Listener listener) {
		if(conn == null) {
			mainHandler.post(new Runnable() {
				public void run() { listener.gameConnectionDisconnected(Frontlib.GAME_END_ERROR); }
			});
			shutdown();
		} else {
			this.conn = conn;
			final int port = Flib.INSTANCE.flib_gameconn_getport(conn);
			mainHandler.post(new Runnable() {
				public void run() { 
					listener.gameConnectionReady(port);
					if(netgame) {
						netplay.registerGameMessageListener(gameMessageListener);
					}
				}
			});
			Flib.INSTANCE.flib_gameconn_onConnect(conn, connectCb, null);
			Flib.INSTANCE.flib_gameconn_onDisconnect(conn, disconnectCb, null);
			Flib.INSTANCE.flib_gameconn_onErrorMessage(conn, errorMessageCb, null);
			if(netgame) {
				Flib.INSTANCE.flib_gameconn_onChat(conn, chatCb, null);
				Flib.INSTANCE.flib_gameconn_onEngineMessage(conn, engineMessageCb, null);
			}
		}
	}
	
	// runs on the IPCThread
	private void shutdown() {
		tickHandler.stop();
		thread.quit();
		Flib.INSTANCE.flib_gameconn_destroy(conn);
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
		public void callback(Pointer context, Pointer buffer, NativeSizeT size) {
			netplay.sendEngineMessage(buffer.getByteArray(0, size.intValue()));
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
					shutdown();
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
					Memory mem = new Memory(em.length);
					mem.write(0, em, 0, em.length);
					Flib.INSTANCE.flib_gameconn_send_enginemsg(conn, mem, NativeSizeT.valueOf(em.length));
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
