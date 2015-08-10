{-
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 \-}

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
        , bans = read . fromJust2 "bans" $ getValue "bans" cfg
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
    bans = b,
    latestReleaseVersion = ver,
    serverConfig = Just cfg}
        =
    writeConfig cfgFileName $ foldl1 (.) entries cfg
    where
        entries =
            repConfig "sv_latestProto" (show ver)
            : repConfig "bans" (show b)
            : map (\(n, v) -> repConfig n (B.unpack v)) [
            ("dbHost", dh)
            , ("dbName", dn)
            , ("dbLogin", dl)
            , ("dbPassword", dp)
            , ("sv_message", sm)
            , ("sv_messageOld", smo)
            ]
