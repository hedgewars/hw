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

{-# LANGUAGE OverloadedStrings, CPP #-}
module HWProtoNEState where

import Control.Monad.Reader
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Char8 as B
import Data.Digest.Pure.SHA
--------------------------------------
import CoreTypes
import Utils
import RoomsAndClients
import HandlerUtils

handleCmd_NotEntered :: CmdHandler

handleCmd_NotEntered ["NICK", newNick] = do
    (ci, irnc) <- ask
    let cl = irnc `client` ci
    if not . B.null $ nick cl then return [ProtocolError $ loc "Nickname already provided."]
        else
        if illegalName newNick then return [ByeClient $ loc "Illegal nickname! Nicknames must be between 1-40 characters long, must not have a trailing or leading space and must not have any of these characters: $()*+?[]^{|}"]
            else
            return $
                ModifyClient (\c -> c{nick = newNick}) :
                AnswerClients [sendChan cl] ["NICK", newNick] :
                [CheckRegistered | clientProto cl /= 0]

handleCmd_NotEntered ["PROTO", protoNum] = do
    (ci, irnc) <- ask
    let cl = irnc `client` ci
    if clientProto cl > 0 then return [ProtocolError $ loc "Protocol already known."]
        else
        if parsedProto == 0 then return [ProtocolError $ loc "Bad number."]
            else
            return $
                ModifyClient (\c -> c{clientProto = parsedProto}) :
                AnswerClients [sendChan cl] ["PROTO", showB parsedProto] :
                [CheckRegistered | not . B.null $ nick cl]
    where
        parsedProto = readInt_ protoNum


handleCmd_NotEntered ["PASSWORD", passwd] = do
    (ci, irnc) <- ask
    let cl = irnc `client` ci

    if clientProto cl < 48 && passwd == webPassword cl then
        return $ JoinLobby : [AnswerClients [sendChan cl] ["ADMIN_ACCESS"] | isAdministrator cl]
        else
        -- String is parsed by frontend, do not localize!
        return [ByeClient "Authentication failed"]


handleCmd_NotEntered ["PASSWORD", passwd, clientSalt] = do
    (ci, irnc) <- ask
    let cl = irnc `client` ci

    let clientHash = h [clientSalt, serverSalt cl, webPassword cl, showB $ clientProto cl, "!hedgewars"]
    let serverHash = h [serverSalt cl, clientSalt, webPassword cl, showB $ clientProto cl, "!hedgewars"]

    if passwd == clientHash then
        return [
            AnswerClients [sendChan cl] ["SERVER_AUTH", serverHash] 
            , JoinLobby
            ]
        else
        -- String is parsed by frontend, do not localize!
        return [ByeClient "Authentication failed"]
    where
        h = B.pack . showDigest . sha1 . BL.fromChunks

#if defined(OFFICIAL_SERVER)
handleCmd_NotEntered ["CHECKER", protoNum, newNick, password] = do
    (ci, irnc) <- ask
    let cl = irnc `client` ci

    if parsedProto == 0 then return [ProtocolError $ loc "Bad number."]
        else
        return $ [
            ModifyClient (\c -> c{clientProto = parsedProto, nick = newNick, webPassword = password, isChecker = True})
            , CheckRegistered]
    where
        parsedProto = readInt_ protoNum
#endif

handleCmd_NotEntered (s:_) = return [ProtocolError $ "Incorrect command '" `B.append` s `B.append` "' (state: not entered)"]
