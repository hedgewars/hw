/*
 * Java net client for Hedgewars, a free turn based strategy game
 * Copyright (c) 2011 Richard Karolyi <sheepluva@ercatec.net>
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

package net.ercatec.hw;

import java.util.List;

public interface INetClient
{
    public static enum UserFlagType { UNKNOWN, ADMIN, INROOM, REGISTERED };
    public static enum BanType { BYNICK, BYIP };

    public void onConnectionLoss();
    public void onDisconnect(String reason);

    public void onMalformedMessage(String contents);

    public String onPasswordHashNeededForAuth();

    public void onChat(String user, String message);
    public void onWelcomeMessage(String message);

    public void onNotice(int number);
    public String onNickCollision(String nick);
    public void onNickSet(String nick);

    public void onLobbyJoin(String[] users);
    public void onLobbyLeave(String user, String reason);

    // TODO flags => enum array?
    public void onRoomInfo(String name, String flags, String newName,
                           int nUsers, int nTeams, String owner, String map,
                           String style, String scheme, String weapons);
    public void onRoomDel(String name);

    public void onRoomJoin(String[] users);
    public void onRoomLeave(String[] users);

    public void onPing();
    public void onPong();

    public void onUserFlagChange(String user, UserFlagType flag, boolean newValue);

    public void onUserInfo(String user, String ip, String version, String room);

    public void onBanListEntry(BanType type, String target, String duration, String reason);
    public void onBanListEnd();

    public void logDebug(String message);
    public void logError(String message);

    public void sanitizeInputs(final String[] inputs);
/*
    public void onEngineMessage(String message);
*/
}
