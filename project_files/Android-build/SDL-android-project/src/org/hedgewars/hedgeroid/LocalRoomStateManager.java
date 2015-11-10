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

package org.hedgewars.hedgeroid;

import org.hedgewars.hedgeroid.Datastructures.GameConfig;
import org.hedgewars.hedgeroid.Datastructures.MapRecipe;
import org.hedgewars.hedgeroid.Datastructures.Scheme;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.Datastructures.TeamIngameAttributes;
import org.hedgewars.hedgeroid.Datastructures.Weaponset;

import android.util.Log;

/**
 * This RoomStateManager is responsible for keeping/changing the roomstate in local play.
 * That is very straightforward, just react to every request by immediately changing the
 * state.
 */
public class LocalRoomStateManager extends BasicRoomState {
    private static final String TAG = LocalRoomStateManager.class.getSimpleName();

    public LocalRoomStateManager(Scheme defaultScheme, Weaponset defaultWeaponset) {
        setChief(true);
        setGameStyle(GameConfig.DEFAULT_STYLE);
        setMapRecipe(MapRecipe.makeRandomMap(0, MapRecipe.makeRandomSeed(), GameConfig.DEFAULT_THEME));
        setScheme(defaultScheme);
        setWeaponset(defaultWeaponset);
    }

    public void changeMapRecipe(MapRecipe map) {
        setMapRecipe(map);
    }

    public void changeMapTheme(String theme) {
        setMapRecipe(getMapRecipe().withTheme(theme));
    }

    public void changeMapNameAndGenerator(String mapName) {
        int newGenerator = MapRecipe.generatorForMapname(mapName);
        setMapRecipe(getMapRecipe().withName(mapName).withMapgen(newGenerator));
    }

    public void changeMapTemplate(int template) {
        setMapRecipe(getMapRecipe().withTemplateFilter(template));
    }

    public void changeMazeSize(int mazeSize) {
        setMapRecipe(getMapRecipe().withMazeSize(mazeSize));
    }

    public void changeMapSeed(String seed) {
        setMapRecipe(getMapRecipe().withSeed(seed));
    }

    public void changeMapDrawdata(byte[] drawdata) {
        setMapRecipe(getMapRecipe().withDrawData(drawdata));
    }

    public void changeScheme(Scheme scheme) {
        setScheme(scheme);
    }

    public void changeGameStyle(String style) {
        setGameStyle(style);
    }

    public void changeWeaponset(Weaponset weaponset) {
        setWeaponset(weaponset);
    }

    public void requestAddTeam(Team team, int colorIndex) {
        putTeam(new TeamInGame(team, new TeamIngameAttributes("Player", colorIndex, TeamIngameAttributes.DEFAULT_HOG_COUNT, false)));
    }

    public void requestRemoveTeam(String teamname) {
        removeTeam(teamname);
    }

    public void changeTeamColorIndex(String teamname, int colorIndex) {
        TeamInGame oldTeam = getTeams().get(teamname);
        if(oldTeam != null) {
            putTeam(oldTeam.withAttribs(oldTeam.ingameAttribs.withColorIndex(colorIndex)));
        } else {
            Log.e(TAG, "Requested color change for unknown team "+ teamname);
        }
    }

    public void changeTeamHogCount(String teamname, int hogcount) {
        TeamInGame oldTeam = getTeams().get(teamname);
        if(oldTeam != null) {
            putTeam(oldTeam.withAttribs(oldTeam.ingameAttribs.withHogCount(hogcount)));
        } else {
            Log.e(TAG, "Requested hog count change for unknown team "+ teamname);
        }
    }
}
