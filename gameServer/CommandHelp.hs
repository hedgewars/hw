{-
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 \-}

{-# LANGUAGE OverloadedStrings #-}
module CommandHelp where

import qualified Data.ByteString.Char8 as B

import CoreTypes
import Utils

-- List and documentation of chat commands

cmdHelpSharedPlayer :: [B.ByteString]
cmdHelpSharedPlayer = [
    loc "/info <player>: Show info about player",
    loc "/me <message>: Chat action, e.g. '/me eats pizza' becomes '* Player eats pizza'",
    loc "/rnd: Flip a virtual coin and reply with 'heads' or 'tails'",
    loc "/rnd [A] [B] [C] [...]: Reply with a random word from the given list",
    loc "/watch <id>: Watch a demo stored on the server with the given ID",
    loc "/help: Show chat command help"
    ]

cmdHelpRoomOnlyPlayer :: [B.ByteString]
cmdHelpRoomOnlyPlayer = [
    -- For everyone
    loc "/callvote [arguments]: Start a vote",
    loc "/vote <yes/no>: Vote 'yes' or 'no' for active vote",
    -- For room master only
    loc "/greeting <message>: Set greeting message to be shown to players who join the room",
    loc "/delegate <player>: Surrender room control to player",
    loc "/maxteams <N>: Limit maximum number of teams to N"
    ]

cmdHelpSharedAdmin :: [B.ByteString]
cmdHelpSharedAdmin = [
    loc "/global <message>: Send global chat message which can be seen by everyone on the server",
    loc "/registered_only: Toggle 'registered only' state. If enabled, only registered players can join server",
    loc "/super_power: Activate your super power. With it you can enter any room and are protected from kicking. Expires when you leave server",
    -- TODO: Add help for /save
    loc "/save <parameter>"
    -- TODO: Add /restart_server? This command seems broken at the moment
    ]

cmdHelpLobbyOnlyAdmin :: [B.ByteString]
cmdHelpLobbyOnlyAdmin = [
    loc "/stats: Query server stats"
    ]

cmdHelpRoomOnlyAdmin :: [B.ByteString]
cmdHelpRoomOnlyAdmin = [
    loc "/force <yes/no>: Force vote result for active vote",
    loc "/fix: Force this room to stay open when it is empty",
    loc "/unfix: Undo the /fix command",
    loc "/saveroom <file name>: Save room configuration into a file",
    loc "/loadroom <file name>: Load room configuration from a file",
    -- TODO: Add help for /delete
    loc "/delete <parameter>"
    ]

cmdHelpHeaderLobby :: [B.ByteString]
cmdHelpHeaderLobby = [ loc "List of lobby chat commands:" ]

cmdHelpHeaderRoom :: [B.ByteString]
cmdHelpHeaderRoom = [ loc "List of room chat commands:" ]

cmdHelpHeaderAdmin :: [B.ByteString]
cmdHelpHeaderAdmin = [ loc "Commands for server admins only:" ]

-- Put it all together
-- Lobby commands
cmdHelpLobbyPlayer :: [B.ByteString]
cmdHelpLobbyPlayer = cmdHelpHeaderLobby ++ cmdHelpSharedPlayer

cmdHelpLobbyAdmin :: [B.ByteString]
cmdHelpLobbyAdmin = cmdHelpLobbyPlayer ++ cmdHelpHeaderAdmin ++ cmdHelpLobbyOnlyAdmin ++ cmdHelpSharedAdmin

-- Room commands
cmdHelpRoomPlayer :: [B.ByteString]
cmdHelpRoomPlayer = cmdHelpHeaderRoom ++ cmdHelpRoomOnlyPlayer ++ cmdHelpSharedPlayer

cmdHelpRoomAdmin :: [B.ByteString]
cmdHelpRoomAdmin = cmdHelpRoomPlayer ++ cmdHelpHeaderAdmin ++ cmdHelpRoomOnlyAdmin ++ cmdHelpSharedAdmin

-- Helper functions for chat command handler
cmdHelpActionEntry :: [ClientChan] -> B.ByteString -> Action
cmdHelpActionEntry chan msg = AnswerClients chan [ "CHAT", "[server]", msg ]

cmdHelpActionList :: [ClientChan] -> [B.ByteString] -> [Action]
cmdHelpActionList chan list = map (cmdHelpActionEntry chan) list
