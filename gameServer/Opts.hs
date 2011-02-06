{-# LANGUAGE CPP #-}
module Opts
(
    getOpts,
) where

import System.Environment
import System.Console.GetOpt
import Data.Maybe ( fromMaybe )
#if defined(OFFICIAL_SERVER)
import qualified Data.ByteString.Char8 as B
import Network
#endif
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
#if defined(OFFICIAL_SERVER)
    , readDbLogin
    , readDbPassword
    readDbHost
#endif
    :: String -> ServerInfo -> ServerInfo


readListenPort str opts = opts{listenPort = readPort}
    where
        readPort = fromInteger $ fromMaybe 46631 (maybeRead str :: Maybe Integer)

readDedicated str opts = opts{isDedicated = readDed}
    where
        readDed = fromMaybe True (maybeRead str :: Maybe Bool)

#if defined(OFFICIAL_SERVER)
readDbLogin str opts = opts{dbLogin = B.pack str}
readDbPassword str opts = opts{dbPassword = B.pack str}
readDbHost str opts = opts{dbHost = B.pack str}
#endif

getOpts :: ServerInfo -> IO ServerInfo
getOpts opts = do
    args <- getArgs
    case getOpt Permute options args of
        (o, [], []) -> return $ foldr ($) opts o
        (_,_,errs) -> ioError (userError (concat errs ++ usageInfo header options))
    where header = "Usage: hedgewars-server [OPTION...]"
