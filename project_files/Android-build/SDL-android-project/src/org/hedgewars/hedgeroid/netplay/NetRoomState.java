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

package org.hedgewars.hedgeroid.netplay;

import static org.hedgewars.hedgeroid.netplay.ThreadedNetConnection.ToNetMsgType.*;
import static org.hedgewars.hedgeroid.util.ObjectUtils.equal;

import java.util.Arrays;
import java.util.Collections;
import java.util.Map;
import java.util.TreeMap;

import org.hedgewars.hedgeroid.BasicRoomState;
import org.hedgewars.hedgeroid.Datastructures.GameConfig;
import org.hedgewars.hedgeroid.Datastructures.MapRecipe;
import org.hedgewars.hedgeroid.Datastructures.Scheme;
import org.hedgewars.hedgeroid.Datastructures.Team;
import org.hedgewars.hedgeroid.Datastructures.TeamInGame;
import org.hedgewars.hedgeroid.Datastructures.TeamIngameAttributes;
import org.hedgewars.hedgeroid.Datastructures.Weaponset;
import org.hedgewars.hedgeroid.netplay.ThreadedNetConnection.ToNetMsgType;

/**
 * This class manages the room state in a network game.
 */
class NetRoomState extends BasicRoomState {
    final Map<String, TeamInGame> requestedTeams = new TreeMap<String, TeamInGame>();
    private Netplay netplay;

    public NetRoomState(Netplay netplay) {
        this.netplay = netplay;
        initRoomState(false);
    }

    public void changeWeaponset(Weaponset weaponset) {
        if(getChiefStatus() && !equal(weaponset, getWeaponset())) {
            sendToNet(MSG_SEND_WEAPONSET, weaponset);
            setWeaponset(weaponset);
        }
    }

    public void changeMapRecipe(MapRecipe mapRecipe) {
        if(getChiefStatus() && !equal(mapRecipe, getMapRecipe())) {
            sendToNet(MSG_SEND_MAP, mapRecipe);
            setMapRecipe(mapRecipe);
        }
    }

    public void changeMapNameAndGenerator(String mapName) {
        if(getChiefStatus() && !equal(mapName, getMapRecipe().name)) {
            int newGenerator = MapRecipe.generatorForMapname(mapName);
            if(newGenerator != getMapRecipe().mapgen) {
                sendToNet(MSG_SEND_MAP_GENERATOR, newGenerator, null);
            }
            sendToNet(MSG_SEND_MAP_NAME, mapName);
            setMapRecipe(getMapRecipe().withName(mapName).withMapgen(newGenerator));
        }
    }

    public void changeMapTemplate(int template) {
        if(getChiefStatus() && template != getMapRecipe().templateFilter) {
            sendToNet(MSG_SEND_MAP_TEMPLATE, template, null);
            setMapRecipe(getMapRecipe().withTemplateFilter(template));
        }
    }

    public void changeMazeSize(int mazeSize) {
        if(getChiefStatus() && mazeSize != getMapRecipe().mazeSize) {
            sendToNet(MSG_SEND_MAZE_SIZE, mazeSize, 0);
            setMapRecipe(getMapRecipe().withMazeSize(mazeSize));
        }
    }

    public void changeMapSeed(String seed) {
        if(getChiefStatus() && !equal(seed, getMapRecipe().seed)) {
            sendToNet(MSG_SEND_MAP_SEED, seed);
            setMapRecipe(getMapRecipe().withSeed(seed));
        }
    }

    public void changeMapTheme(String theme) {
        if(getChiefStatus() && !equal(theme, getMapRecipe().theme)) {
            sendToNet(MSG_SEND_MAP_THEME, theme);
            setMapRecipe(getMapRecipe().withTheme(theme));
        }
    }

    public void changeMapDrawdata(byte[] drawdata) {
        if(getChiefStatus() && !Arrays.equals(drawdata, getMapRecipe().getDrawData())) {
            sendToNet(MSG_SEND_MAP_DRAWDATA, drawdata);
            setMapRecipe(getMapRecipe().withDrawData(drawdata));
        }
    }

    public void changeGameStyle(String gameStyle) {
        if(getChiefStatus() && !equal(gameStyle, getGameStyle())) {
            sendToNet(MSG_SEND_GAMESTYLE, gameStyle);
            setGameStyle(gameStyle);
        }
    }

    public void changeScheme(Scheme scheme) {
        if(getChiefStatus() && !equal(scheme, getScheme())) {
            sendToNet(MSG_SEND_SCHEME, scheme);
            setScheme(scheme);
        }
    }

    void initRoomState(boolean chief) {
        setTeams(Collections.<String, TeamInGame>emptyMap());
        requestedTeams.clear();

        setChief(chief);
        setGameStyle(GameConfig.DEFAULT_STYLE);
        setMapRecipe(MapRecipe.makeRandomMap(0, "seed", GameConfig.DEFAULT_THEME));
        setScheme(netplay.defaultScheme);
        setWeaponset(netplay.defaultWeaponset);
        sendFullConfig();
    }

    void sendFullConfig() {
        if(getChiefStatus()) {
            sendToNet(MSG_SEND_GAMESTYLE, getGameStyle());
            sendToNet(MSG_SEND_SCHEME, getScheme());
            sendToNet(MSG_SEND_WEAPONSET, getWeaponset());
            sendToNet(MSG_SEND_MAP, getMapRecipe());
        }
    }

    private boolean sendToNet(ToNetMsgType what, Object obj) {
        return netplay.sendToNet(what, 0, obj);
    }

    private boolean sendToNet(ToNetMsgType what, int arg1, Object obj) {
        return netplay.sendToNet(what, arg1, obj);
    }

    public void requestAddTeam(Team team, int colorIndex) {
        TeamIngameAttributes tia = new TeamIngameAttributes(netplay.getPlayerName(), colorIndex, TeamIngameAttributes.DEFAULT_HOG_COUNT, false);
        TeamInGame newTeamInGame = new TeamInGame(team, tia);
        requestedTeams.put(team.name, newTeamInGame);
        sendToNet(MSG_SEND_ADD_TEAM, newTeamInGame);
    }

    public void requestRemoveTeam(String teamname) {
        sendToNet(MSG_SEND_REMOVE_TEAM, teamname);
    }

    public void changeTeamColorIndex(String teamname, int colorIndex) {
        if(getChiefStatus()) {
            TeamInGame team = getTeams().get(teamname);
            if(team.ingameAttribs.colorIndex != colorIndex) {
                sendToNet(MSG_SEND_TEAM_COLOR_INDEX, colorIndex, teamname);
                putTeam(team.withAttribs(team.ingameAttribs.withColorIndex(colorIndex)));
            }
        }
    }

    public void changeTeamHogCount(String teamname, int hogcount) {
        if(getChiefStatus()) {
            TeamInGame team = getTeams().get(teamname);
            if(team.ingameAttribs.hogCount != hogcount) {
                sendToNet(MSG_SEND_TEAM_HOG_COUNT, hogcount, teamname);
                putTeam(team.withAttribs(team.ingameAttribs.withHogCount(hogcount)));
            }
        }
    }
}
