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
        , serverMessage = value "sv_message" cfg
        , serverMessageForOldVersions = value "sv_messageOld" cfg
        , latestReleaseVersion = read . fromJust $ getValue "sv_latestProto" cfg
        , serverConfig = Just cfg
    }
    return si
    where
        value n c = B.pack . fromJust2 n $ getValue n c
        fromJust2 n Nothing = error $ "Missing config entry " ++ n
        fromJust2 _ (Just a) = a

writeServerConfig :: ServerInfo c -> IO ()
writeServerConfig = undefined
