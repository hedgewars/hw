{-
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2014 Andrey Korotaev <unC0Rr@gmail.com>
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
module Votes where

import Control.Monad.Reader
import Control.Monad.State.Strict
import ServerState
import qualified Data.ByteString.Char8 as B
import qualified Data.List as L
import qualified Data.Map as Map
import Data.Maybe
-------------------
import Utils
import CoreTypes
import HandlerUtils
import EngineInteraction


voted :: Bool -> Reader (ClientIndex, IRnC) [Action]
voted vote = do
    cl <- thisClient
    rm <- thisRoom
    uid <- liftM clUID thisClient

    case voting rm of
        Nothing -> 
            return [AnswerClients [sendChan cl] ["CHAT", "[server]", loc "There's no voting going on"]]
        Just voting ->
            if uid `L.notElem` entitledToVote voting then
                return []
            else if uid `L.elem` map fst (votes voting) then
                return [AnswerClients [sendChan cl] ["CHAT", "[server]", loc "You already have voted"]]
            else
                actOnVoting $ voting{votes = (uid, vote):votes voting}

    where
    actOnVoting :: Voting -> Reader (ClientIndex, IRnC) [Action]
    actOnVoting vt = do
        let (pro, contra) = L.partition snd $ votes vt
        let totalV = length $ entitledToVote vt 
        let successV = totalV `div` 2 + 1

        if length contra > totalV - successV then
            closeVoting
        else if length pro >= successV then do
            a <- act $ voteType vt
            c <- closeVoting
            return $ c ++ a
        else
            return [ModifyRoom $ \r -> r{voting = Just vt}]

    closeVoting = do
        chans <- roomClientsChans
        return [
            AnswerClients chans ["CHAT", "[server]", loc "Voting closed"]
            , ModifyRoom (\r -> r{voting = Nothing})
            ]

    act (VoteKick nickname) = do
        (thisClientId, rnc) <- ask
        maybeClientId <- clientByNick nickname
        rm <- thisRoom
        let kickId = fromJust maybeClientId
        let kickCl = rnc `client` kickId
        let sameRoom = clientRoom rnc thisClientId == clientRoom rnc kickId
        return
            [KickRoomClient kickId |
                isJust maybeClientId
                && sameRoom
                && ((isNothing $ gameInfo rm) || teamsInGame kickCl == 0)
            ]
    act (VoteMap roomSave) = do
        rm <- thisRoom
        let rs = Map.lookup roomSave (roomSaves rm)
        case rs of
             Nothing -> return []
             Just (mp, p) -> do
                 cl <- thisClient
                 chans <- roomClientsChans
                 let a = map (replaceChans chans) $ answerFullConfigParams cl mp p
                 return $ 
                    (ModifyRoom $ \r -> r{params = p, mapParams = mp})
                    : SendUpdateOnThisRoom
                    : a
        where
            replaceChans chans (AnswerClients _ msg) = AnswerClients chans msg
            replaceChans _ a = a
    act (VotePause) = do
        rm <- thisRoom
        chans <- roomClientsChans
        let modifyGameInfo f room  = room{gameInfo = fmap f $ gameInfo room}
        return [ModifyRoom (modifyGameInfo $ \g -> g{isPaused = not $ isPaused g}),
                AnswerClients chans ["CHAT", "[server]", loc "Pause toggled"],
                AnswerClients chans ["EM", toEngineMsg "I"]]
    act (VoteNewSeed) =
        return [SetRandomSeed]
    act (VoteHedgehogsPerTeam h) = do
        rm <- thisRoom
        chans <- roomClientsChans
        let answers = concatMap (\t -> 
                [ModifyRoom $ modifyTeam t{hhnum = h}
                , AnswerClients chans ["HH_NUM", teamname t, showB h]]
                )
                $
                if isJust $ gameInfo rm then
                    teamsAtStart . fromJust . gameInfo $ rm 
                else
                    teams rm

        return $ ModifyRoom (\r -> r{defaultHedgehogsNumber = h}) : answers


startVote :: VoteType -> Reader (ClientIndex, IRnC) [Action]
startVote vt = do
    (ci, rnc) <- ask
    --cl <- thisClient
    rm <- thisRoom
    chans <- roomClientsChans

    let uids = map (clUID . client rnc) . roomClients rnc $ clientRoom rnc ci

    if isJust $ voting rm then
        return []
    else
        return [
            ModifyRoom (\r -> r{voting = Just (newVoting vt){entitledToVote = uids}})
            , AnswerClients chans ["CHAT", "[server]", B.concat [loc "New voting started", ": ", voteInfo vt]]
            , ReactCmd ["VOTE", "YES"]
        ]


checkVotes :: StateT ServerState IO [Action]
checkVotes = do
    rnc <- gets roomsClients
    liftM concat $ io $ do
        ris <- allRoomsM rnc
        mapM (check rnc) ris
    where
        check rnc ri = do
            e <- room'sM rnc voting ri
            case e of
                 Just rv -> do
                     modifyRoom rnc (\r -> r{voting = if voteTTL rv == 0 then Nothing else Just rv{voteTTL = voteTTL rv - 1}}) ri
                     if voteTTL rv == 0 then do
                        chans <- liftM (map sendChan) $ roomClientsM rnc ri
                        return [AnswerClients chans ["CHAT", "[server]", loc "Voting expired"]]
                        else
                        return []
                 Nothing -> return []


voteInfo :: VoteType -> B.ByteString
voteInfo (VoteKick n) = B.concat [loc "kick", " ", n]
voteInfo (VoteMap n) = B.concat [loc "map", " ", n]
voteInfo (VotePause) = B.concat [loc "pause"]
voteInfo (VoteNewSeed) = B.concat [loc "new seed"]
voteInfo (VoteHedgehogsPerTeam i) = B.concat [loc "number of hedgehogs in team", " ", showB i]
