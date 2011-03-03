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

options :: [OptDescr (ServerInfo c -> ServerInfo c)]
options = [
    Option "p" ["port"] (ReqArg readListenPort "PORT") "listen on PORT",
    Option "d" ["dedicated"] (ReqArg readDedicated "BOOL") "start as dedicated (True or False)"
    ]

readListenPort
    , readDedicated
    :: String -> ServerInfo c -> ServerInfo c


readListenPort str opts = opts{listenPort = readPort}
    where
        readPort = fromInteger $ fromMaybe 46631 (maybeRead str :: Maybe Integer)

readDedicated str opts = opts{isDedicated = readDed}
    where
        readDed = fromMaybe True (maybeRead str :: Maybe Bool)

getOpts :: ServerInfo c -> IO (ServerInfo c)
getOpts opts = do
    args <- getArgs
    case getOpt Permute options args of
        (o, [], []) -> return $ foldr ($) opts o
        (_,_,errs) -> ioError (userError (concat errs ++ usageInfo header options))
    where header = "Usage: hedgewars-server [OPTION...]"
