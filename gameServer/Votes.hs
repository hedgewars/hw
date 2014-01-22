module Votes where

import Data.Unique
import CoreTypes
import RoomsAndClients
import Control.Monad.Reader
import Control.Monad.State
import ServerState

voted :: Unique -> Bool -> Reader (ClientIndex, IRnC) [Action]
voted = undefined

startVote :: VoteType -> Reader (ClientIndex, IRnC) [Action]
startVote = undefined

checkVotes :: StateT ServerState IO ()
checkVotes = undefined
