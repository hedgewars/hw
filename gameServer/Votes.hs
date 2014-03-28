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


voted :: Bool -> Reader (ClientIndex, IRnC) [Action]
voted vote = do
    cl <- thisClient
    rm <- thisRoom
    uid <- liftM clUID thisClient

    if isNothing $ voting rm then
        return [AnswerClients [sendChan cl] ["CHAT", "[server]", loc "There's no voting going on"]]
    else if uid `L.notElem` entitledToVote (fromJust $ voting rm) then
        return []
    else if uid `L.elem` map fst (votes . fromJust $ voting rm) then
        return [AnswerClients [sendChan cl] ["CHAT", "[server]", loc "You already have voted"]]
    else
        actOnVoting . fromJust . liftM (\v -> v{votes = (uid, vote):votes v}) $ voting rm
    where
    actOnVoting :: Voting -> Reader (ClientIndex, IRnC) [Action]
    actOnVoting vt = do
        let (pro, contra) = L.partition snd $ votes vt
        let v = (length $ entitledToVote vt) `div` 2 + 1

        if length contra >= v then
            closeVoting
        else if length pro >= v then do
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
             Just (mp, p) -> return [ModifyRoom $ \r -> r{params = p, mapParams = mp}]


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
