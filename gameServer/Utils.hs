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

{-# LANGUAGE OverloadedStrings,CPP #-}
module Utils where

import Data.Char
import Data.Word
import qualified Data.Map as Map
import qualified Data.Char as Char
import Numeric
import Network.Socket
import System.IO
import qualified Data.List as List
import Control.Monad
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Char8 as B
import qualified Data.ByteString.UTF8 as UTF8
import Data.Maybe
#if defined(OFFICIAL_SERVER)
import qualified Data.Aeson.Types as Aeson
import qualified Data.Text as Text
#endif
-------------------------------------------------
import CoreTypes


sockAddr2String :: SockAddr -> IO B.ByteString
sockAddr2String (SockAddrInet _ hostAddr) = liftM B.pack $ inet_ntoa hostAddr
sockAddr2String (SockAddrInet6 _ _ (a, b, c, d) _) =
    return $ B.pack $ (foldr1 (.)
        $ List.intersperse (':':)
        $ concatMap (\n -> (\(a0, a1) -> [showHex a0, showHex a1]) $ divMod n 65536) [a, b, c, d]) []

maybeRead :: Read a => String -> Maybe a
maybeRead s = case reads s of
    [(x, rest)] | all isSpace rest -> Just x
    _         -> Nothing

teamToNet :: TeamInfo -> [B.ByteString]
teamToNet team =
        "ADD_TEAM"
        : teamname team
        : teamgrave team
        : teamfort team
        : teamvoicepack team
        : teamflag team
        : teamowner team
        : (showB . difficulty $ team)
        : hhsInfo
    where
        hhsInfo = concatMap (\(HedgehogInfo n hat) -> [n, hat]) $ hedgehogs team

modifyTeam :: TeamInfo -> RoomInfo -> RoomInfo
modifyTeam team room = room{teams = replaceTeam team $ teams room}
    where
    replaceTeam _ [] = error "modifyTeam: no such team"
    replaceTeam tm (t:ts) =
        if teamname tm == teamname t then
            tm : ts
        else
            t : replaceTeam tm ts

-- NOTE: Don't forget to update the error messages when you change the naming rules!
illegalName :: B.ByteString -> Bool
illegalName b = B.null b || length s > 40 || all isSpace s || isSpace (head s) || isSpace (last s) || any isIllegalChar s
    where
        s = UTF8.toString b
        isIllegalChar c = c `List.elem` ("$()*+?[]^{|}\x7F" ++ ['\x00'..'\x1F'] ++ ['\xFFF0'..'\xFFFF'])

protoNumber2ver :: Word16 -> B.ByteString
protoNumber2ver v = Map.findWithDefault "Unknown" v vermap
    where
        vermap = Map.fromList [
            (17, "0.9.7-dev")
            , (19, "0.9.7")
            , (20, "0.9.8-dev")
            , (21, "0.9.8")
            , (22, "0.9.9-dev")
            , (23, "0.9.9")
            , (24, "0.9.10-dev")
            , (25, "0.9.10")
            , (26, "0.9.11-dev")
            , (27, "0.9.11")
            , (28, "0.9.12-dev")
            , (29, "0.9.12")
            , (30, "0.9.13-dev")
            , (31, "0.9.13")
            , (32, "0.9.14-dev")
            , (33, "0.9.14")
            , (34, "0.9.15-dev")
            , (35, "0.9.14.1")
            , (37, "0.9.15")
            , (38, "0.9.16-dev")
            , (39, "0.9.16")
            , (40, "0.9.17-dev")
            , (41, "0.9.17")
            , (42, "0.9.18-dev")
            , (43, "0.9.18")
            , (44, "0.9.19-dev")
            , (45, "0.9.19")
            , (46, "0.9.20-dev")
            , (47, "0.9.20")
            , (48, "0.9.21-dev")
            , (49, "0.9.21")
            , (50, "0.9.22-dev")
            , (51, "0.9.22")
            , (52, "0.9.23-dev")
            , (53, "0.9.23")
            , (54, "0.9.24-dev")
            , (55, "0.9.24")
            , (56, "0.9.25-dev")
            ]

askFromConsole :: B.ByteString -> IO B.ByteString
askFromConsole msg = do
    B.putStr msg
    hFlush stdout
    B.getLine


unfoldrE :: (b -> Either b (a, b)) -> b -> ([a], b)
unfoldrE f b  =
    case f b of
        Right (a, new_b) -> let (a', b') = unfoldrE f new_b in (a : a', b')
        Left new_b       -> ([], new_b)

showB :: (Show a) => a -> B.ByteString
showB = B.pack . show

readInt_ :: (Num a) => B.ByteString -> a
readInt_ str =
  case B.readInt str of
       Just (i, t) | B.null t -> fromIntegral i
       _                      -> 0

cutHost :: B.ByteString -> B.ByteString
cutHost = B.intercalate "." .  flip (++) ["*","*"] . List.take 2 . B.split '.'

caseInsensitiveCompare :: B.ByteString -> B.ByteString -> Bool
caseInsensitiveCompare a b = upperCase a == upperCase b

upperCase :: B.ByteString -> B.ByteString
upperCase = UTF8.fromString . map Char.toUpper . UTF8.toString

roomInfo :: Word16 -> B.ByteString -> RoomInfo -> [B.ByteString]
roomInfo p n r
    | p < 46 = [
        showB $ isJust $ gameInfo r,
        name r,
        showB $ playersIn r,
        showB $ length $ teams r,
        n,
        Map.findWithDefault "+rnd+" "MAP" (mapParams r),
        head (Map.findWithDefault ["Default"] "SCHEME" (params r)),
        head (Map.findWithDefault ["Default"] "AMMO" (params r))
        ]
    | p < 48 = [
        showB $ isJust $ gameInfo r,
        name r,
        showB $ playersIn r,
        showB $ length $ teams r,
        n,
        Map.findWithDefault "+rnd+" "MAP" (mapParams r),
        head (Map.findWithDefault ["Normal"] "SCRIPT" (params r)),
        head (Map.findWithDefault ["Default"] "SCHEME" (params r)),
        head (Map.findWithDefault ["Default"] "AMMO" (params r))
        ]
    | otherwise = [
        B.pack roomFlags,
        name r,
        showB $ playersIn r,
        showB $ length $ teams r,
        n,
        Map.findWithDefault "+rnd+" "MAP" (mapParams r),
        head (Map.findWithDefault ["Normal"] "SCRIPT" (params r)),
        head (Map.findWithDefault ["Default"] "SCHEME" (params r)),
        head (Map.findWithDefault ["Default"] "AMMO" (params r))
        ]
    where
        roomFlags = concat [
            "-"
            , ['g' | isJust $ gameInfo r]
            , ['p' | not . B.null $ password r]
            , ['j' | isRestrictedJoins  r]
            , ['r' | isRegisteredOnly  r]
            ]

answerFullConfigParams ::
            ClientInfo
            -> Map.Map B.ByteString B.ByteString
            -> Map.Map B.ByteString [B.ByteString]
            -> [Action]
answerFullConfigParams cl mpr pr
        | clientProto cl < 38 = map (toAnswer cl) $
                (reverse . map (\(a, b) -> (a, [b])) $ Map.toList mpr)
                ++ (("SCHEME", pr Map.! "SCHEME")
                : (filter (\(p, _) -> p /= "SCHEME") $ Map.toList pr))

        | clientProto cl < 48 = map (toAnswer cl) $
                ("FULLMAPCONFIG", let l = Map.elems mpr in if length l > 5 then tail l else l)
                : ("SCHEME", pr Map.! "SCHEME")
                : (filter (\(p, _) -> p /= "SCHEME") $ Map.toList pr)

        | otherwise = map (toAnswer cl) $
                ("FULLMAPCONFIG", Map.elems mpr)
                : ("SCHEME", pr Map.! "SCHEME")
                : (filter (\(p, _) -> p /= "SCHEME") $ Map.toList pr)
    where
        toAnswer cl (paramName, paramStrs) = AnswerClients [sendChan cl] $ "CFG" : paramName : paramStrs


answerAllTeams :: ClientInfo -> [TeamInfo] -> [Action]
answerAllTeams cl = concatMap toAnswer
    where
        clChan = sendChan cl
        toAnswer team =
            [AnswerClients [clChan] $ teamToNet team,
            AnswerClients [clChan] ["TEAM_COLOR", teamname team, teamcolor team],
            AnswerClients [clChan] ["HH_NUM", teamname team, showB $ hhnum team]]


-- Locale function to localize strings.
-- loc is just the identity functions, but it will be collected by scripts
-- for localization. Use loc to mark a string for translation.
loc :: B.ByteString -> B.ByteString
loc = id

maybeNick :: Maybe ClientInfo -> B.ByteString
maybeNick = fromMaybe "[]" . liftM nick

-- borrowed from Data.List, just more general in types
deleteBy2                :: (a -> b -> Bool) -> a -> [b] -> [b]
deleteBy2 _  _ []        = []
deleteBy2 eq x (y:ys)    = if x `eq` y then ys else y : deleteBy2 eq x ys

deleteFirstsBy2          :: (a -> b -> Bool) -> [a] -> [b] -> [a]
deleteFirstsBy2 eq       =  foldl (flip (deleteBy2 (flip eq)))

sanitizeName :: B.ByteString -> B.ByteString
sanitizeName = B.map sc
    where
        sc c | isAlphaNum c = c
             | otherwise = '_'

isRegistered :: ClientInfo -> Bool
isRegistered = (<) 0 . B.length . webPassword

#if defined(OFFICIAL_SERVER)
instance Aeson.ToJSON B.ByteString where
  toJSON = Aeson.toJSON . B.unpack

instance Aeson.FromJSON B.ByteString where
  parseJSON = Aeson.withText "ByteString" $ pure . B.pack . Text.unpack
  
instance Aeson.ToJSONKey B.ByteString where
  toJSONKey = Aeson.toJSONKeyText (Text.pack . B.unpack)
  
instance Aeson.FromJSONKey B.ByteString where
  fromJSONKey = Aeson.FromJSONKeyTextParser (return . B.pack . Text.unpack)
#endif  
