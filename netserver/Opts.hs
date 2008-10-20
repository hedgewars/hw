module Opts where

import System
import System.Console.GetOpt
import Network
import Data.Maybe ( fromMaybe )
import Miscutils
import System.IO.Unsafe

data GlobalOptions =
	GlobalOptions
	{
		isDedicated :: Bool,
		serverMessage :: String,
		listenPort :: PortNumber
	}
defaultMessage = "<h2><p align=center><a href=\"http://www.hedgewars.org/\">http://www.hedgewars.org/</a></p></h2>"
defaultOptions = (GlobalOptions False defaultMessage 46631)

options :: [OptDescr (GlobalOptions -> GlobalOptions)]
options = [
	Option ['p'] ["port"] (ReqArg readListenPort "PORT") "listen on PORT",
	Option ['d'] ["dedicated"] (ReqArg readDedicated "BOOL") "start as dedicated (True or False)"
	]

readListenPort, readDedicated :: String -> GlobalOptions -> GlobalOptions
readListenPort str opts = opts{listenPort = readPort}
	where
		readPort = fromInteger $ fromMaybe 46631 (maybeRead str :: Maybe Integer)

readDedicated str opts = opts{isDedicated = readDedicated}
	where
		readDedicated = fromMaybe True (maybeRead str :: Maybe Bool)

opts :: IO GlobalOptions
opts = do
	args <- getArgs
	case getOpt Permute options args of
		(o, [], []) -> return $ foldr ($) defaultOptions o
		(_,_,errs) -> ioError (userError (concat errs ++ usageInfo header options))
	where header = "Usage: newhwserv [OPTION...]"

{-# NOINLINE globalOptions #-}
globalOptions = unsafePerformIO opts
