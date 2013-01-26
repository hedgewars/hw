{-# LANGUAGE OverloadedStrings, CPP #-}
module HWProtoNEState where

import Control.Monad.Reader
import qualified Data.ByteString.Char8 as B
--------------------------------------
import CoreTypes
import Actions
import Utils
import RoomsAndClients

handleCmd_NotEntered :: CmdHandler

handleCmd_NotEntered ["NICK", newNick] = do
    (ci, irnc) <- ask
    let cl = irnc `client` ci
    if not . B.null $ nick cl then return [ProtocolError $ loc "Nickname already chosen"]
        else
        if illegalName newNick then return [ByeClient $ loc "Illegal nickname"]
            else
            return $
                ModifyClient (\c -> c{nick = newNick}) :
                AnswerClients [sendChan cl] ["NICK", newNick] :
                [CheckRegistered | clientProto cl /= 0]

handleCmd_NotEntered ["PROTO", protoNum] = do
    (ci, irnc) <- ask
    let cl = irnc `client` ci
    if clientProto cl > 0 then return [ProtocolError $ loc "Protocol already known"]
        else
        if parsedProto == 0 then return [ProtocolError $ loc "Bad number"]
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

    if passwd == webPassword cl then
        return $ JoinLobby : [AnswerClients [sendChan cl] ["ADMIN_ACCESS"] | isAdministrator cl]
        else
        return [ByeClient "Authentication failed"]


#if defined(OFFICIAL_SERVER)
handleCmd_NotEntered ["CHECKER", protoNum, newNick, password] = do
    (ci, irnc) <- ask
    let cl = irnc `client` ci

    if parsedProto == 0 then return [ProtocolError $ loc "Bad number"]
        else
        return $ [
            ModifyClient (\c -> c{clientProto = parsedProto, nick = newNick, webPassword = password, isChecker = True})
            , CheckRegistered]
    where
        parsedProto = readInt_ protoNum
#endif

handleCmd_NotEntered _ = return [ProtocolError "Incorrect command (state: not entered)"]
