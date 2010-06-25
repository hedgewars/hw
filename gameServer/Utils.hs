{-# LANGUAGE OverloadedStrings #-}
module Utils where

import Control.Concurrent
import Control.Concurrent.STM
import Data.Char
import Data.Word
import qualified Data.Map as Map
import qualified Data.IntMap as IntMap
import qualified Data.Set as Set
import Data.ByteString.Internal (w2c)
import Numeric
import Network.Socket
import System.IO
import qualified Data.List as List
import Control.Monad
import Maybe
-------------------------------------------------
import qualified Codec.Binary.Base64 as Base64
import qualified Data.ByteString.Char8 as B
import qualified Data.ByteString as BW
import CoreTypes


sockAddr2String :: SockAddr -> IO B.ByteString
sockAddr2String (SockAddrInet _ hostAddr) = liftM B.pack $ inet_ntoa hostAddr
sockAddr2String (SockAddrInet6 _ _ (a, b, c, d) _) =
    return $ B.pack $ (foldr1 (.)
        $ List.intersperse (\a -> ':':a)
        $ concatMap (\n -> (\(a, b) -> [showHex a, showHex b]) $ divMod n 65536) [a, b, c, d]) []

toEngineMsg :: B.ByteString -> B.ByteString
toEngineMsg msg = B.pack $ Base64.encode (fromIntegral (BW.length msg) : (BW.unpack msg))

fromEngineMsg :: B.ByteString -> Maybe B.ByteString
fromEngineMsg msg = Base64.decode (B.unpack msg) >>= removeLength >>= return . BW.pack
    where
        removeLength (x:xs) = if length xs == fromIntegral x then Just xs else Nothing
        removeLength _ = Nothing

checkNetCmd :: B.ByteString -> (Bool, Bool)
checkNetCmd = check . liftM B.unpack . fromEngineMsg
    where
        check Nothing = (False, False)
        check (Just (m:ms)) = (m `Set.member` legalMessages, m == '+')
        check _ = (False, False)
        legalMessages = Set.fromList $ "M#+LlRrUuDdZzAaSjJ,sFNpPwtghb12345" ++ slotMessages
        slotMessages = "\128\129\130\131\132\133\134\135\136\137\138"

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
        : (B.pack $ show $ difficulty team)
        : hhsInfo
    where
        hhsInfo = concatMap (\(HedgehogInfo name hat) -> [name, hat]) $ hedgehogs team

modifyTeam :: TeamInfo -> RoomInfo -> RoomInfo
modifyTeam team room = room{teams = replaceTeam team $ teams room}
    where
    replaceTeam _ [] = error "modifyTeam: no such team"
    replaceTeam team (t:teams) =
        if teamname team == teamname t then
            team : teams
        else
            t : replaceTeam team teams

illegalName :: B.ByteString -> Bool
illegalName = all isSpace . B.unpack

protoNumber2ver :: Word16 -> B.ByteString
protoNumber2ver 17 = "0.9.7-dev"
protoNumber2ver 19 = "0.9.7"
protoNumber2ver 20 = "0.9.8-dev"
protoNumber2ver 21 = "0.9.8"
protoNumber2ver 22 = "0.9.9-dev"
protoNumber2ver 23 = "0.9.9"
protoNumber2ver 24 = "0.9.10-dev"
protoNumber2ver 25 = "0.9.10"
protoNumber2ver 26 = "0.9.11-dev"
protoNumber2ver 27 = "0.9.11"
protoNumber2ver 28 = "0.9.12-dev"
protoNumber2ver 29 = "0.9.12"
protoNumber2ver 30 = "0.9.13-dev"
protoNumber2ver 31 = "0.9.13"
protoNumber2ver 32 = "0.9.14-dev"
protoNumber2ver _ = "Unknown"

askFromConsole :: String -> IO String
askFromConsole msg = do
    putStr msg
    hFlush stdout
    getLine


unfoldrE :: (b -> Either b (a, b)) -> b -> ([a], b)
unfoldrE f b  =
    case f b of
        Right (a, new_b) -> let (a', b') = unfoldrE f new_b in (a : a', b')
        Left new_b       -> ([], new_b)

showB :: Show a => a -> B.ByteString
showB = B.pack .show
