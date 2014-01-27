{-# LANGUAGE OverloadedStrings #-}
module Votes where

import Control.Monad.Reader
import Control.Monad.State
import ServerState
import qualified Data.ByteString.Char8 as B
import qualified Data.List as L
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
        return [ModifyRoom $ \r -> r{voting = liftM (\v -> v{votes = (uid, vote):votes v}) $ voting rm}]


startVote :: VoteType -> Reader (ClientIndex, IRnC) [Action]
startVote vt = do
    (ci, rnc) <- ask
    cl <- thisClient
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

