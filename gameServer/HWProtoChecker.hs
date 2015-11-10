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

{-# LANGUAGE OverloadedStrings #-}
module HWProtoChecker where

import Data.Maybe
import Control.Monad.Reader
--------------------------------------
import CoreTypes
import HandlerUtils


handleCmd_checker :: CmdHandler

handleCmd_checker ["READY"] = return [ModifyClient $ \c -> c{isReady = True}, CheckRecord]

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
