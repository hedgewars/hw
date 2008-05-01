module Miscutils where

import IO
import System.IO
import Control.Concurrent
import Control.Concurrent.STM
import Control.Exception (finally)
import Data.Word
import Data.Char

data ClientInfo =
	ClientInfo
	{
		chan :: TChan String,
		handle :: Handle,
		nick :: String,
		protocol :: Word16,
		room :: String,
		isMaster :: Bool
	}

data RoomInfo =
	RoomInfo
	{
		name :: String,
		password :: String
	}

tselect :: [ClientInfo] -> STM (String, ClientInfo)
tselect = foldl orElse retry . map (\ci -> (flip (,) ci) `fmap` readTChan (chan ci))

maybeRead :: Read a => String -> Maybe a
maybeRead s = case reads s of
	[(x, rest)] | all isSpace rest -> Just x
	_         -> Nothing
