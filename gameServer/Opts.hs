module Opts
(
    getOpts,
) where

import System.Environment ( getArgs )
import System.Console.GetOpt
import Network
import Data.Maybe ( fromMaybe )
import CoreTypes
import Utils

options :: [OptDescr (ServerInfo -> ServerInfo)]
options = [
    Option ['p'] ["port"] (ReqArg readListenPort "PORT") "listen on PORT",
    Option ['d'] ["dedicated"] (ReqArg readDedicated "BOOL") "start as dedicated (True or False)"
    ]

readListenPort,
    readDedicated,
    readDbLogin,
    readDbPassword,
    readDbHost :: String -> ServerInfo -> ServerInfo

readListenPort str opts = opts{listenPort = readPort}
    where
        readPort = fromInteger $ fromMaybe 46631 (maybeRead str :: Maybe Integer)

readDedicated str opts = opts{isDedicated = readDedicated}
    where
        readDedicated = fromMaybe True (maybeRead str :: Maybe Bool)

readDbLogin str opts = opts{dbLogin = str}
readDbPassword str opts = opts{dbPassword = str}
readDbHost str opts = opts{dbHost = str}

getOpts :: ServerInfo -> IO ServerInfo
getOpts opts = do
    args <- getArgs
    case getOpt Permute options args of
        (o, [], []) -> return $ foldr ($) opts o
        (_,_,errs) -> ioError (userError (concat errs ++ usageInfo header options))
    where header = "Usage: hedgewars-server [OPTION...]"
