module Opts
(
	getOpts,
) where

import System
import System.Console.GetOpt
import Network
import Data.Maybe ( fromMaybe )
import Miscutils
import System.IO.Unsafe


options :: [OptDescr (ServerInfo -> ServerInfo)]
options = [
	Option ['p'] ["port"] (ReqArg readListenPort "PORT") "listen on PORT",
	Option ['d'] ["dedicated"] (ReqArg readDedicated "BOOL") "start as dedicated (True or False)",
	Option []    ["password"] (ReqArg readPassword "STRING") "admin password"
	]

readListenPort, readDedicated, readPassword :: String -> ServerInfo -> ServerInfo
readListenPort str opts = opts{listenPort = readPort}
	where
		readPort = fromInteger $ fromMaybe 46631 (maybeRead str :: Maybe Integer)

readDedicated str opts = opts{isDedicated = readDedicated}
	where
		readDedicated = fromMaybe True (maybeRead str :: Maybe Bool)

readPassword str opts = opts{adminPassword = str}

getOpts :: ServerInfo -> IO ServerInfo
getOpts opts = do
	args <- getArgs
	case getOpt Permute options args of
		(o, [], []) -> return $ foldr ($) opts o
		(_,_,errs) -> ioError (userError (concat errs ++ usageInfo header options))
	where header = "Usage: newhwserv [OPTION...]"
