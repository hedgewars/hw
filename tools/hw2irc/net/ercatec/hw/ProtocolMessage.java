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

import java.util.Arrays;
import java.util.List;
import java.util.Iterator;

public final class ProtocolMessage
{
    public static final int ROOM_FIELD_COUNT = 9;

    private static int minServerVersion = 49;

    public static enum Type {
        // for unknown message types
        _UNKNOWN_MESSAGETYPE_,
        // server messages
        ERROR,
        PING,
        PONG,
        NICK,
        PROTO,
        ASKPASSWORD,
        SERVER_AUTH,
        CONNECTED,
        SERVER_MESSAGE,
        BYE,
        INFO,
        NOTICE,
        CHAT,
        LOBBY__JOINED,
        LOBBY__LEFT,
        ROOMS,
        ROOM,
        ROOM_ADD,
        ROOM_DEL,
        ROOM_UPD,
        ROOM__JOINED,
        ROOM__LEFT,
        CFG,
        TOGGLE_RESTRICT_TEAMS,
        CLIENT_FLAGS,
        CF, // this just an alias and will be mapped to CLIENT_FLAGS
        EM // engine messages
    }

    public final boolean isValid;
    private Type type;
    private String[] args;

/*
    public ProtocolMessage(String messageType)
    {
        args = new String[0];

        try
        {
            type = Type.valueOf(messageType);
            isValid = messageSyntaxIsValid();
        }
        catch (IllegalArgumentException whoops)
        {
            type = Type._UNKNOWN_MESSAGETYPE_;
            args = new String[] { messageType };
            isValid = false;
        }
    }
*/

    private final String[] emptyArgs = new String[0];

    private String[] withoutFirst(final String[] array, final int amount) {
        return Arrays.copyOfRange(array, amount, array.length);
    }

    private final List<String> parts;

    // invalid Message
    public ProtocolMessage() {
        this.parts =  Arrays.asList(emptyArgs);
        this.args = emptyArgs;
        this.isValid = false;
    }

    public ProtocolMessage(final List<String> parts)
    {
        this.parts = parts;
        this.args = emptyArgs;

        final int partc = parts.size();

        if (partc < 1) {
            isValid = false;
            return;
        }

        try {
            type = Type.valueOf(parts.get(0).replaceAll(":", "__"));
        }
        catch (IllegalArgumentException whoops) {
            type = Type._UNKNOWN_MESSAGETYPE_;
        }

        if (type == Type._UNKNOWN_MESSAGETYPE_) {
            args = parts.toArray(args);
            isValid = false;
        }
        else {
            // all parts after command become arguments
            if (partc > 1)
                args = withoutFirst(parts.toArray(args), 1);
            isValid = checkMessage();
        }
    }

    private boolean checkMessage()
    {
        int argc = args.length;

        switch (type)
        {
            // no arguments allowed
            case PING:
            case PONG:
            case TOGGLE_RESTRICT_TEAMS:
                if (argc != 0)
                    return false;
                break;

            // one argument or more
            case EM: // engine messages
            case LOBBY__JOINED: // list of joined players
            case ROOM__JOINED: // list of joined players
                if (argc < 1)
                    return false;
                break;

            // one argument
            case SERVER_MESSAGE:
            case BYE: // disconnect reason
            case ERROR: // error message
            case NICK: // nickname
            case PROTO: // protocol version
            case SERVER_AUTH: // last stage of mutual of authentication
            case ASKPASSWORD: // request for auth with salt
                if (argc != 1)
                    return false;
                break;

            case NOTICE: // argument should be a number
                if (argc != 1)
                    return false;
                try {
                    Integer.parseInt(args[0]);
                } 
                catch (NumberFormatException e) {
                    return false;
                }
                break;

            // two arguments
            case CONNECTED: // server description and version
            case CHAT: // player nick and chat message
            case LOBBY__LEFT: // player nick and leave reason
            case ROOM__LEFT: // player nick and leave reason
                if (argc != 2)
                    return false;
                break;
                
            case ROOM: // "ADD" (or "UPD" + room name ) + room attrs or "DEL" and room name
                if(argc < 2)
                    return false;

                final String subC = args[0];

                if (subC.equals("ADD")) {
                    if(argc != ROOM_FIELD_COUNT + 1)
                        return false;
                    this.type = Type.ROOM_ADD;
                    this.args = withoutFirst(args, 1);
                }
                else if (subC.equals("UPD")) {
                    if(argc != ROOM_FIELD_COUNT + 2)
                        return false;
                    this.type = Type.ROOM_UPD;
                    this.args = withoutFirst(args, 1);
                }
                else if (subC.equals("DEL") && (argc == 2)) {
                    this.type = Type.ROOM_DEL;
                    this.args = withoutFirst(args, 1);
                }
                else
                    return false;
                break;

            // two arguments or more
            case CFG: // setting name and list of setting parameters
                if (argc < 2)
                    return false;
                break;
            case CLIENT_FLAGS: // string of changed flags and player name(s)
            case CF: // alias of CLIENT_FLAGS
                if (argc < 2)
                    return false;
                if (this.type == Type.CF)
                    this.type = Type.CLIENT_FLAGS;
                break;

            // four arguments
            case INFO: // info about a player, name, ip/id, version, room
                if (argc != 4)
                    return false;
                break;

            // multiple of ROOM_FIELD_COUNT arguments (incl. 0)
            case ROOMS:
                if (argc % ROOM_FIELD_COUNT != 0)
                    return false;
                break;
        }

        return true;
    }

    private void maybeSendPassword() {
        
    }

    public Type getType()
    {
        return type;
    }

    public String[] getArguments()
    {
        return args;
    }

    public boolean isValid()
    {
        return isValid;
    }

    public static String partsToString(final List<String> parts)
    {
        final Iterator<String> iter = parts.iterator();

        if (!iter.hasNext())
            return "( -EMPTY- )";

        String result = "(\"" + iter.next();

        while (iter.hasNext()) {
            result += "\", \"" + iter.next();
        }

        return result + "\")";
    }

    public String toString() {
        return partsToString(this.parts);
    }
}
