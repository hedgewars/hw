module Opts where

import System
import System.Console.GetOpt
import Network
import Data.Maybe ( fromMaybe )
import Miscutils

data Flag = ListenPort PortNumber
	deriving Show

options :: [OptDescr Flag]
options = [
	Option ['p'] ["port"] (OptArg defaultPort "PORT") "listen on PORT"
	]

defaultPort :: Maybe String -> Flag
defaultPort str = ListenPort $ fromInteger (fromMaybe 46631 (maybeRead (fromMaybe "46631" str) :: Maybe Integer))

opts :: IO [Flag]
opts = do
	args <- getArgs
	case getOpt Permute options args of
		(o, [], []) -> return o
		(_,_,errs) -> ioError (userError (concat errs ++ usageInfo header options))
	where header = "Usage: newhwserv [OPTION...]"

getPort :: [Flag] -> PortNumber
getPort [] = 46631
getPort (ListenPort a:flags) = a
