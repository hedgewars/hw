package org.hedgewars.hedgeroid;

import java.util.Map;

import org.hedgewars.hedgeroid.Datastructures.MapRecipe;
import org.hedgewars.hedgeroid.Datastructures.Scheme;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.Datastructures.Weaponset;

/**
 * This interface is supposed to abstract the handling of room state for several
 * fragments that can display and manipulate it. The purpose of this is to allow
 * using these fragments both for setting up networked and local games, despite
 * the fact that for local games the settings can be changed immediately in
 * memory, while they have to be sent out to the server for networked games.
 * 
 * If/when the state changes as result of calling one of the "changeX" or
 * "requestX" functions, that will also trigger the corresponding change
 * listener method. There is no guarantee that calling a changeX method will
 * actually change the setting (e.g. if you're not room chief).
 * 
 * For local games, getChiefStatus is always true.
 * 
 * Implementations of this interface are probably not thread safe and should
 * only be used on the UI thread.
 */
public interface RoomStateManager {
	// Query current state
	MapRecipe getMapRecipe();
	boolean getChiefStatus();
	Scheme getScheme();
	String getGameStyle();
	Weaponset getWeaponset();
	Map<String, TeamInGame> getTeams();
	
	// Manipulate state
	void changeMapRecipe(MapRecipe map);
	void changeMapTheme(String theme);

	/**
	 * This function sets both the map's name and generator. There is no function
	 * to change them independendly since e.g. the QtFrontend relies on them being
	 * consistent.
	 * 
	 * If the name parameter is equal to one of the MapRecipe.MAPNAME_REGULAR, MAPNAME_MAZE
	 * or MAPNAME_DRAWN constants, the map generator is set accordingly. Otherwise, the
	 * map generator is set to represent a mapfile. The map's name is always set to
	 * the parameter.
	 */
	void changeMapNameAndGenerator(String mapName);
	void changeMapTemplate(int template);
	void changeMazeSize(int mazeSize);
	void changeMapSeed(String seed);
	void changeMapDrawdata(byte[] drawdata);
	
	void changeScheme(Scheme scheme);
	void changeGameStyle(String style);
	void changeWeaponset(Weaponset weaponset);
	
	void requestAddTeam(Team team, int colorIndex);
	void requestRemoveTeam(String teamname);
	void changeTeamColorIndex(String teamname, int colorIndex);
	void changeTeamHogCount(String teamname, int hogcount);
	
	// Observe changes
	void addListener(Listener observer);
	void removeListener(Listener observer);
	
	public interface Listener {
		void onMapChanged(MapRecipe recipe);
		void onChiefStatusChanged(boolean isChief);
		void onSchemeChanged(Scheme scheme);
		void onGameStyleChanged(String gameStyle);
		void onWeaponsetChanged(Weaponset weaponset);
		void onTeamsChanged(Map<String, TeamInGame> teams);
	}
	
	public static class ListenerAdapter implements Listener {
		public void onMapChanged(MapRecipe recipe) {}
		public void onChiefStatusChanged(boolean isChief) {}
		public void onSchemeChanged(Scheme scheme) {}
		public void onGameStyleChanged(String gameStyle) {}
		public void onWeaponsetChanged(Weaponset weaponset) {}
		public void onTeamsChanged(Map<String, TeamInGame> teams) {}
	}
	
	public interface Provider {
		RoomStateManager getRoomStateManager();
	}
}
