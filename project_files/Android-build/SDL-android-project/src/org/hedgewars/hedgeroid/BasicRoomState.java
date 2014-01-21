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

import static org.hedgewars.hedgeroid.util.ObjectUtils.equal;

import java.util.Collections;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import org.hedgewars.hedgeroid.RoomStateManager;
import org.hedgewars.hedgeroid.Datastructures.MapRecipe;
import org.hedgewars.hedgeroid.Datastructures.Scheme;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.Datastructures.Weaponset;

/**
 * Common base implementation for a roomstate that will call listeners on every
 * change. The derived classes have to coordinate how state is changed to
 * complete the implementation of the RoomStateManager interface.
 *
 * See {@link RoomStateManager} for a description of what this is for.
 */
public abstract class BasicRoomState implements RoomStateManager {
    private final List<RoomStateManager.Listener> observers = new LinkedList<RoomStateManager.Listener>();

    private boolean chief;
    private String gameStyle;
    private Scheme scheme;
    private MapRecipe map;
    private Weaponset weaponset;
    private Map<String, TeamInGame> teams = Collections.emptyMap();

    public final MapRecipe getMapRecipe() {
        return map;
    }

    public final boolean getChiefStatus() {
        return chief;
    }

    public final Scheme getScheme() {
        return scheme;
    }

    public final String getGameStyle() {
        return gameStyle;
    }

    public final Weaponset getWeaponset() {
        return weaponset;
    }

    public final Map<String, TeamInGame> getTeams() {
        return teams;
    }

    public final void setWeaponset(Weaponset weaponset) {
        if(!equal(weaponset, this.weaponset)) {
            this.weaponset = weaponset;
            for(RoomStateManager.Listener observer : observers) {
                observer.onWeaponsetChanged(weaponset);
            }
        }
    }

    public final void setMapRecipe(MapRecipe map) {
        if(!equal(map, this.map)) {
            this.map = map;
            for(RoomStateManager.Listener observer : observers) {
                observer.onMapChanged(map);
            }
        }
    }

    public final void setGameStyle(String gameStyle) {
        if(!equal(gameStyle, this.gameStyle)) {
            this.gameStyle = gameStyle;
            for(RoomStateManager.Listener observer : observers) {
                observer.onGameStyleChanged(gameStyle);
            }
        }
    }

    public final void setScheme(Scheme scheme) {
        if(!equal(scheme, this.scheme)) {
            this.scheme = scheme;
            for(RoomStateManager.Listener observer : observers) {
                observer.onSchemeChanged(scheme);
            }
        }
    }

    public final void setChief(boolean chief) {
        if(chief != this.chief) {
            this.chief = chief;
            for(RoomStateManager.Listener observer : observers) {
                observer.onChiefStatusChanged(chief);
            }
        }
    }

    public final void putTeam(TeamInGame team) {
        TeamInGame oldEntry = teams.get(team.team.name);
        if(!equal(team, oldEntry)) {
            Map<String, TeamInGame> changedMap = new TreeMap<String, TeamInGame>(teams);
            changedMap.put(team.team.name, team);
            teams = Collections.unmodifiableMap(changedMap);
            for(RoomStateManager.Listener observer : observers) {
                observer.onTeamsChanged(teams);
            }
        }
    }

    public final void removeTeam(String teamname) {
        if(teams.containsKey(teamname)) {
            Map<String, TeamInGame> changedMap = new TreeMap<String, TeamInGame>(teams);
            changedMap.remove(teamname);
            teams = Collections.unmodifiableMap(changedMap);
            for(RoomStateManager.Listener observer : observers) {
                observer.onTeamsChanged(teams);
            }
        }
    }

    public final void setTeams(Map<String, TeamInGame> newTeams) {
        if(!newTeams.equals(teams)) {
            teams = Collections.unmodifiableMap(new TreeMap<String, TeamInGame>(newTeams));
            for(RoomStateManager.Listener observer : observers) {
                observer.onTeamsChanged(teams);
            }
        }
    }

    public final void addListener(Listener observer) {
        observers.add(observer);
    }

    public final void removeListener(Listener observer) {
        observers.remove(observer);
    }
}
