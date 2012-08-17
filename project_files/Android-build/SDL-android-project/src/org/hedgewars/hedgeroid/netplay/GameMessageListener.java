package org.hedgewars.hedgeroid.netplay;

/**
 * Interface with several event callbacks that represent network messages which are interesting
 * for a running game, e.g. because they concern the lifecycle of the game or because they contain
 * data that needs to be passed on.
 * 
 * These functions might be called on any thread.
 */
public interface GameMessageListener {
	void onChatMessage(String nick, String message);
	void onEngineMessage(byte[] em);
	void onMessage(int type, String message);
	void onNetDisconnected();
}
