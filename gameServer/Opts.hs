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

{-# LANGUAGE CPP #-}
module Opts
(
    getOpts,
) where

import System.Environment
import System.Console.GetOpt
import Data.Maybe ( fromMaybe )
-------------------
import CoreTypes
import Utils

options :: [OptDescr (ServerInfo -> ServerInfo)]
options = [
    Option "p" ["port"] (ReqArg readListenPort "PORT") "listen on PORT",
    Option "d" ["dedicated"] (ReqArg readDedicated "BOOL") "start as dedicated (True or False)"
    ]

readListenPort
    , readDedicated
    :: String -> ServerInfo -> ServerInfo


readListenPort str opts = opts{listenPort = readPort}
    where
        readPort = fromInteger $ fromMaybe 46631 (maybeRead str :: Maybe Integer)

readDedicated str opts = opts{isDedicated = readDed}
    where
        readDed = fromMaybe True (maybeRead str :: Maybe Bool)

getOpts :: ServerInfo -> IO ServerInfo
getOpts opts = do
    args <- getArgs
    case getOpt Permute options args of
        (o, [], []) -> return $ foldr ($) opts{runArgs = args} o
        (_,_,errs) -> ioError (userError (concat errs ++ usageInfo header options))
    where header = "Usage: hedgewars-server [OPTION...]"
