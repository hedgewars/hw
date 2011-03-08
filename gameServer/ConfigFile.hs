{-# LANGUAGE RankNTypes #-}
module ConfigFile where

import Data.Maybe
import Data.TConfig
import qualified Data.ByteString.Char8 as B
-------------------
import CoreTypes

cfgFileName :: String
cfgFileName = "hedgewars-server.ini"


readServerConfig :: ServerInfo -> IO ServerInfo
readServerConfig serverInfo' = do
    cfg <- readConfig cfgFileName
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


writeServerConfig :: ServerInfo -> IO ()
writeServerConfig ServerInfo{serverConfig = Nothing} = return ()
writeServerConfig ServerInfo{
    dbHost = dh,
    dbName = dn,
    dbLogin = dl,
    dbPassword = dp,
    serverMessage = sm,
    serverMessageForOldVersions = smo,
    latestReleaseVersion = ver,
    serverConfig = Just cfg}
        = do
    let newCfg = foldl (\c (n, v) -> repConfig n (B.unpack v) c) cfg entries
    writeConfig cfgFileName (repConfig "sv_latestProto" (show ver) newCfg)
    where
        entries = [
            ("dbHost", dh)
            , ("dbName", dn)
            , ("dbLogin", dl)
            , ("dbPassword", dp)
            , ("sv_message", sm)
            , ("sv_messageOld", smo)
            ]
