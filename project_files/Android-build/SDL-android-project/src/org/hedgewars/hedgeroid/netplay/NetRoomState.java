package org.hedgewars.hedgeroid.netplay;

import static org.hedgewars.hedgeroid.netplay.ThreadedNetConnection.ToNetMsgType.MSG_SEND_GAMESTYLE;
import static org.hedgewars.hedgeroid.netplay.ThreadedNetConnection.ToNetMsgType.MSG_SEND_MAP;
import static org.hedgewars.hedgeroid.netplay.ThreadedNetConnection.ToNetMsgType.MSG_SEND_MAP_DRAWDATA;
import static org.hedgewars.hedgeroid.netplay.ThreadedNetConnection.ToNetMsgType.MSG_SEND_MAP_GENERATOR;
import static org.hedgewars.hedgeroid.netplay.ThreadedNetConnection.ToNetMsgType.MSG_SEND_MAP_NAME;
import static org.hedgewars.hedgeroid.netplay.ThreadedNetConnection.ToNetMsgType.MSG_SEND_MAP_SEED;
import static org.hedgewars.hedgeroid.netplay.ThreadedNetConnection.ToNetMsgType.MSG_SEND_MAP_TEMPLATE;
import static org.hedgewars.hedgeroid.netplay.ThreadedNetConnection.ToNetMsgType.MSG_SEND_MAP_THEME;
import static org.hedgewars.hedgeroid.netplay.ThreadedNetConnection.ToNetMsgType.MSG_SEND_MAZE_SIZE;
import static org.hedgewars.hedgeroid.netplay.ThreadedNetConnection.ToNetMsgType.MSG_SEND_SCHEME;
import static org.hedgewars.hedgeroid.netplay.ThreadedNetConnection.ToNetMsgType.MSG_SEND_WEAPONSET;

import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

import org.hedgewars.hedgeroid.RoomStateManager;
import org.hedgewars.hedgeroid.Datastructures.GameConfig;
import org.hedgewars.hedgeroid.Datastructures.MapRecipe;
import org.hedgewars.hedgeroid.Datastructures.Scheme;
import org.hedgewars.hedgeroid.Datastructures.Weaponset;
import org.hedgewars.hedgeroid.netplay.ThreadedNetConnection.ToNetMsgType;

/**
 * This class manages the room state in a network game.
 */
class NetRoomState implements RoomStateManager {
	private List<RoomStateManager.Observer> observers = new LinkedList<RoomStateManager.Observer>();
	private Netplay netplay;
	
	boolean chief;
	String gameStyle;
	Scheme scheme;
	MapRecipe map;
	Weaponset weaponset;
	
	public NetRoomState(Netplay netplay) {
		this.netplay = netplay;
		this.map = MapRecipe.makeRandomMap(0, "seed", GameConfig.DEFAULT_THEME);
	}

	public MapRecipe getMapRecipe() {
		return map;
	}

	public boolean getChiefStatus() {
		return chief;
	}

	public Scheme getScheme() {
		return scheme;
	}

	public String getGameStyle() {
		return gameStyle;
	}

	public Weaponset getWeaponset() {
		return weaponset;
	}

	public void changeWeaponset(Weaponset weaponset) {
		if(chief && !weaponset.equals(this.weaponset)) {
			sendToNet(MSG_SEND_WEAPONSET, weaponset);
			setWeaponset(weaponset);
		}
	}
	
	public void changeMapRecipe(MapRecipe mapRecipe) {
		if(chief && !mapRecipe.equals(this.map)) {
			sendToNet(MSG_SEND_MAP, mapRecipe);
			setMapRecipe(mapRecipe);
		}
	}
	
	public void changeMapNameAndGenerator(String mapName) {
		if(chief && !mapName.equals(this.map.name)) {
			int newGenerator = MapRecipe.generatorForMapname(mapName);
			if(newGenerator != this.map.mapgen) {
				sendToNet(MSG_SEND_MAP_GENERATOR, newGenerator, null);
			}
			sendToNet(MSG_SEND_MAP_NAME, mapName);
			setMapRecipe(map.withName(mapName).withMapgen(newGenerator));
		}
	}
	
	public void changeMapTemplate(int template) {
		if(chief && template != this.map.templateFilter) {
			sendToNet(MSG_SEND_MAP_TEMPLATE, template, null);
			setMapRecipe(map.withTemplateFilter(template));
		}
	}
	
	public void changeMazeSize(int mazeSize) {
		if(chief && mazeSize != this.map.mazeSize) {
			sendToNet(MSG_SEND_MAZE_SIZE, mazeSize, 0);
			setMapRecipe(map.withMazeSize(mazeSize));
		}
	}
	
	public void changeMapSeed(String seed) {
		if(chief && !seed.equals(this.map.seed)) {
			sendToNet(MSG_SEND_MAP_SEED, seed);
			setMapRecipe(map.withSeed(seed));
		}
	}
	
	public void changeMapTheme(String theme) {
		if(chief && !theme.equals(this.map.theme)) {
			sendToNet(MSG_SEND_MAP_THEME, theme);
			setMapRecipe(map.withTheme(theme));
		}
	}
	
	public void changeMapDrawdata(byte[] drawdata) {
		if(chief && !Arrays.equals(drawdata, this.map.getDrawData())) {
			sendToNet(MSG_SEND_MAP_DRAWDATA, drawdata);
			setMapRecipe(map.withDrawData(drawdata));
		}
	}
	
	public void changeGameStyle(String gameStyle) {
		if(chief && !gameStyle.equals(this.gameStyle)) {
			sendToNet(MSG_SEND_GAMESTYLE, gameStyle);
			setGameStyle(gameStyle);
		}
	}
	
	public void changeScheme(Scheme scheme) {
		if(chief && !scheme.equals(this.scheme)) {
			sendToNet(MSG_SEND_SCHEME, scheme);
			setScheme(scheme);
		}
	}
	
	void setWeaponset(Weaponset weaponset) {
		if(!weaponset.equals(this.weaponset)) {
			this.weaponset = weaponset;
			for(RoomStateManager.Observer observer : observers) {
				observer.onWeaponsetChanged(weaponset);
			}
		}
	}
	
	void setMapRecipe(MapRecipe map) {
		if(!map.equals(this.map)) { 
			this.map = map;
			for(RoomStateManager.Observer observer : observers) {
				observer.onMapChanged(map);
			}
		}
	}
	
	void setGameStyle(String gameStyle) {
		if(!gameStyle.equals(this.gameStyle)) {
			this.gameStyle = gameStyle;
			for(RoomStateManager.Observer observer : observers) {
				observer.onGameStyleChanged(gameStyle);
			}
		}
	}
	
	void setScheme(Scheme scheme) {
		if(!scheme.equals(this.scheme)) {
			this.scheme = scheme;
			for(RoomStateManager.Observer observer : observers) {
				observer.onSchemeChanged(scheme);
			}
		}
	}
	
	void setChief(boolean chief) {
		if(chief != this.chief) {
			this.chief = chief;
			for(RoomStateManager.Observer observer : observers) {
				observer.onChiefStatusChanged(chief);
			}
		}
	}
	
	void sendFullConfig() {
		if(chief) {
			sendToNet(MSG_SEND_GAMESTYLE, gameStyle);
			sendToNet(MSG_SEND_SCHEME, scheme);
			sendToNet(MSG_SEND_WEAPONSET, weaponset);
			sendToNet(MSG_SEND_MAP, map);
		}
	}
	
	public void registerObserver(Observer observer) {
		observers.add(observer);
	}

	public void unregisterObserver(Observer observer) {
		observers.remove(observer);
	}
	
	private boolean sendToNet(ToNetMsgType what, Object obj) {
		return netplay.sendToNet(what, 0, obj);
	}
	
	private boolean sendToNet(ToNetMsgType what, int arg1, Object obj) {
		return netplay.sendToNet(what, arg1, obj);
	}
}
