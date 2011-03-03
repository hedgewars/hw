{-# LANGUAGE OverloadedStrings #-}
module Utils where

import Data.Char
import Data.Word
import qualified Data.Map as Map
import qualified Data.Set as Set
import Numeric
import Network.Socket
import System.IO
import qualified Data.List as List
import Control.Monad
import qualified Codec.Binary.Base64 as Base64
import qualified Data.ByteString.Char8 as B
import qualified Data.ByteString as BW
-------------------------------------------------
import CoreTypes


sockAddr2String :: SockAddr -> IO B.ByteString
sockAddr2String (SockAddrInet _ hostAddr) = liftM B.pack $ inet_ntoa hostAddr
sockAddr2String (SockAddrInet6 _ _ (a, b, c, d) _) =
    return $ B.pack $ (foldr1 (.)
        $ List.intersperse (':':)
        $ concatMap (\n -> (\(a0, a1) -> [showHex a0, showHex a1]) $ divMod n 65536) [a, b, c, d]) []

toEngineMsg :: B.ByteString -> B.ByteString
toEngineMsg msg = B.pack $ Base64.encode (fromIntegral (BW.length msg) : BW.unpack msg)

fromEngineMsg :: B.ByteString -> Maybe B.ByteString
fromEngineMsg msg = liftM BW.pack (Base64.decode (B.unpack msg) >>= removeLength)
    where
        removeLength (x:xs) = if length xs == fromIntegral x then Just xs else Nothing
        removeLength _ = Nothing

checkNetCmd :: B.ByteString -> (Bool, Bool)
checkNetCmd = check . liftM B.unpack . fromEngineMsg
    where
        check Nothing = (False, False)
        check (Just (m:_)) = (m `Set.member` legalMessages, m == '+')
        check _ = (False, False)
        legalMessages = Set.fromList $ "M#+LlRrUuDdZzAaSjJ,sFNpPwtghbc12345" ++ slotMessages
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
        : (B.pack . show $ difficulty team)
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

illegalName :: B.ByteString -> Bool
illegalName b = null s || all isSpace s || isSpace (head s) || isSpace (last s)
    where
        s = B.unpack b

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

showB :: Show a => a -> B.ByteString
showB = B.pack .show
