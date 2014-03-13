{-# LANGUAGE OverloadedStrings #-}
module Votes where

import Control.Monad.Reader
import Control.Monad.State
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
        let (contra, pro) = L.partition snd $ votes vt
        let v = (length $ entitledToVote vt) `div` 2 + 1

        if length contra >= v then
            closeVoting
        else if length pro >= v then do
            act $ voteType vt
            closeVoting
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
        liftM ([ModifyRoom (\r -> r{voting = Just (newVoting vt){entitledToVote = uids}})
        , AnswerClients chans ["CHAT", "[server]", B.concat [loc "New voting started", ": ", voteInfo vt]]
        ] ++ ) $ voted True


checkVotes :: StateT ServerState IO ()
checkVotes = undefined


voteInfo :: VoteType -> B.ByteString
voteInfo (VoteKick n) = B.concat [loc "kick", " ", n]
voteInfo (VoteMap n) = B.concat [loc "map", " ", n]
