/*
 * Hedgewars for Android. An Android port of Hedgewars, a free turn based strategy game
 * Copyright (c) 2011-2012 Richard Deurwaarder <xeli@xelification.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */


package org.hedgewars.hedgeroid.EngineProtocol;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.UnknownHostException;

public class EngineProtocolNetwork extends Thread{

	public static final String GAMEMODE_LOCAL = "TL";
	public static final String GAMEMODE_DEMO = "TD";
	public static final String GAMEMODE_NET = "TN";
	public static final String GAMEMODE_SAVE = "TS";
	
	public static final int BUFFER_SIZE = 255; //From iOS code which got it from the origional frontend
	
	public static final int MODE_GENLANDPREVIEW = 0;
	public static final int MODE_GAME = 1;

	private ServerSocket serverSocket;
	private InputStream input;
	private OutputStream output;
	public int port;
	private final GameConfig config;
	private boolean clientQuit = false;

	public EngineProtocolNetwork(GameConfig _config){
		config = _config;
		try {
			serverSocket = new ServerSocket(0);
			port = serverSocket.getLocalPort();
			Thread ipcThread = new Thread(this, "IPC - Thread");			
			ipcThread.start();
		} catch (UnknownHostException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	public void run(){
		//if(mode == MODE_GENLANDPREVIEW) genLandPreviewIPC();
		/*else if (mode == MODE_GAME)*/ gameIPC();
	}
	
	private void gameIPC(){
		Socket sock = null;
		try{
			sock = serverSocket.accept();
			input = sock.getInputStream();
			output = sock.getOutputStream();
			
			int msgSize = 0;
			byte[] buffer = new byte[BUFFER_SIZE];

			while(!clientQuit){
				msgSize = 0;

				input.read(buffer, 0, 1);
				msgSize = buffer[0];

				input.read(buffer, 0, msgSize);
				System.out.println("IPC" + (char)buffer[0] + " : " + new String(buffer, 1,msgSize-1, "US_ASCII"));
				switch(buffer[0]){
				case 'C'://game init
					config.sendToEngine(this);
					break;
				case '?'://ping - pong
					sendToEngine("!");
					break;
				case 'e'://Send protocol version
					System.out.println(new String(buffer));
					break;
				case 'i'://game statistics
					switch(buffer[1]){
					case 'r'://winning team
						break;
					case 'D'://best shot
						break;
					case 'k'://best hedgehog
						break;
					case 'K'://# hogs killed
						break;
					case 'H'://team health graph
						break;
					case 'T':// local team stats
						break;
					case 'P'://teams ranking
						break;
					case 's'://self damage
						break;
					case 'S'://friendly fire
						break;
					case 'B'://turn skipped
						break;
					default:
					}
					break;
				case 'E'://error - quits game
					System.out.println(new String(buffer));
					return;
				case 'q'://game ended remove save file

				    return;
				case 'Q'://game ended but not finished

					return;
				}

			}
		}catch(IOException e){
			e.printStackTrace();
		}finally{
			try {
				if(sock != null) sock.close();
			} catch (IOException e) {}
			try{
				if(serverSocket != null) serverSocket.close();
			} catch (IOException e) {}
		}
	}

	public void sendToEngine(String s){
		int length = s.length();
		
		try {
			output.write(length);
			output.write(s.getBytes(), 0, length);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	public void quitIPC(){
		clientQuit = true;
	}
	
}
