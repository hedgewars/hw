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
module Consts where

import qualified Data.ByteString.Char8 as B

serverVersion :: B.ByteString
serverVersion = "3"

-- Maximum hedgehogs per team
cHogsPerTeam :: Int
cHogsPerTeam = 8

-- Maximum teams count
cMaxTeams :: Int
cMaxTeams = 8

-- Maximum total number of hedgehogs
cMaxHHs :: Int
cMaxHHs = cHogsPerTeam * cMaxTeams

{- "Fake" nick names used for special server messages in chat.
They are enclosed in brackets; these characters not allowed in real nick names.
The brackets are required as they are parsed by the frontend.
Names enclosed in square brackets send messages that are supposed to be translated by the frontend.
Names enclosed in parenthesis send messages that are not supposed to be translated. -}

-- For most server messages, usually response to a command
nickServer :: B.ByteString
nickServer = "[server]"

-- For /rnd command
nickRandom :: B.ByteString
nickRandom = "[random]"

-- For /global command
nickGlobal :: B.ByteString
nickGlobal = "(global notice)"
