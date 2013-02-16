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

handleCmd_checker ["CHECKED", "FAIL", msg] = do
    isChecking <- liftM (isJust . checkInfo) thisClient
    if not isChecking then
        return []
        else
        return [CheckFailed msg, ModifyClient $ \c -> c{checkInfo = Nothing}]


handleCmd_checker ("CHECKED" : "OK" : info) = do
    isChecking <- liftM (isJust . checkInfo) thisClient
    if not isChecking then
        return []
        else
        return [CheckSuccess info, ModifyClient $ \c -> c{checkInfo = Nothing}]

handleCmd_checker _ = return [ProtocolError "Unknown command"]
