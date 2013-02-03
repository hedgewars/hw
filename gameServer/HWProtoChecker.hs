{-# LANGUAGE OverloadedStrings #-}
module HWProtoChecker where

import qualified Data.Map as Map
import Data.Maybe
import Data.List
import Control.Monad.Reader
--------------------------------------
import CoreTypes
import Actions
import Utils
import HandlerUtils
import RoomsAndClients
import EngineInteraction


handleCmd_checker :: CmdHandler

handleCmd_checker ["READY"] = return [CheckRecord]

handleCmd_checker _ = return [ProtocolError "Unknown command"]
