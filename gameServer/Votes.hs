{-# LANGUAGE OverloadedStrings #-}
module Votes where

import Data.Unique
import Control.Monad.Reader
import Control.Monad.State
import ServerState
import qualified Data.ByteString.Char8 as B
import Data.Maybe
-------------------
import Utils
import CoreTypes
import HandlerUtils

voted :: Unique -> Bool -> Reader (ClientIndex, IRnC) [Action]
voted _ _ = do
    return []

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
        ] ++ ) $ voted (clUID cl) True

checkVotes :: StateT ServerState IO ()
checkVotes = undefined

voteInfo :: VoteType -> B.ByteString
voteInfo (VoteKick n) = B.concat [loc "kick", " ", n]

