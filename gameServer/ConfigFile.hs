{-# LANGUAGE RankNTypes #-}
module ConfigFile where

import Data.Maybe
import Data.TConfig
import qualified Data.ByteString.Char8 as B
-------------------
import CoreTypes

readServerConfig serverInfo' = do
    cfg <- readConfig "hedgewars-server.ini"
    let si = serverInfo'{
        dbHost = value "dbHost" cfg
        , dbName = value "dbName" cfg
        , dbLogin = value "dbLogin" cfg
        , dbPassword = value "dbPassword" cfg
        , serverConfig = Just cfg
    }
    return si
    where
        value n c = B.pack . fromJust $ getValue n c

writeServerConfig :: ServerInfo c -> IO ()
writeServerConfig = undefined
