{-# LANGUAGE OverloadedStrings #-}

module EngineInteraction(replayToDemo, checkNetCmd, toEngineMsg, drawnMapData) where

import qualified Data.Set as Set
import Control.Monad
import qualified Codec.Binary.Base64 as Base64
import qualified Data.ByteString.Char8 as B
import qualified Data.ByteString as BW
import qualified Data.ByteString.Lazy as BL
import qualified Data.Map as Map
import qualified Data.List as L
import Data.Word
import Data.Bits
import Control.Arrow
import Data.Maybe
import Codec.Compression.Zlib as Z
-------------
import CoreTypes
import Utils


toEngineMsg :: B.ByteString -> B.ByteString
toEngineMsg msg = B.pack $ Base64.encode (fromIntegral (BW.length msg) : BW.unpack msg)


fromEngineMsg :: B.ByteString -> Maybe B.ByteString
fromEngineMsg msg = liftM BW.pack (Base64.decode (B.unpack msg) >>= removeLength)
    where
        removeLength (x:xs) = if length xs == fromIntegral x then Just xs else Nothing
        removeLength _ = Nothing

em :: B.ByteString -> B.ByteString
em = toEngineMsg

eml :: [B.ByteString] -> B.ByteString
eml = em . B.concat

splitMessages :: B.ByteString -> [B.ByteString]
splitMessages = L.unfoldr (\b -> if B.null b then Nothing else Just $ B.splitAt (1 + fromIntegral (BW.head b)) b)


checkNetCmd :: B.ByteString -> (B.ByteString, B.ByteString, Maybe (Maybe B.ByteString))
checkNetCmd msg = check decoded
    where
        decoded = liftM (splitMessages . BW.pack) $ Base64.decode $ B.unpack msg
        check Nothing = (B.empty, B.empty, Nothing)
        check (Just msgs) = let (a, b) = (filter isLegal msgs, filter isNonEmpty a) in (encode a, encode b, lft a)
        encode = B.pack . Base64.encode . BW.unpack . B.concat
        isLegal m = (B.length m > 1) && (flip Set.member legalMessages . B.head . B.tail $ m)
        lft = foldr l Nothing
        l m n = let m' = B.head $ B.tail m; tst = flip Set.member in
                      if not $ tst timedMessages m' then n
                        else if '+' /= m' then Just Nothing else Just . Just . B.pack . Base64.encode . BW.unpack $ m
        isNonEmpty = (/=) '+' . B.head . B.tail
        legalMessages = Set.fromList $ "M#+LlRrUuDdZzAaSjJ,sNpPwtghbc12345" ++ slotMessages
        slotMessages = "\128\129\130\131\132\133\134\135\136\137\138"
        timedMessages = Set.fromList $ "+LlRrUuDdZzAaSjJ,NpPwtgc12345" ++ slotMessages


replayToDemo :: [TeamInfo]
        -> Map.Map B.ByteString B.ByteString
        -> Map.Map B.ByteString [B.ByteString]
        -> [B.ByteString]
        -> [B.ByteString]
replayToDemo ti mParams prms msgs = concat [
        [em "TD"]
        , maybeScript
        , maybeMap
        , [eml ["etheme ", head $ prms Map.! "THEME"]]
        , [eml ["eseed ", mParams Map.! "SEED"]]
        , [eml ["e$gmflags ", showB gameFlags]]
        , schemeFlags
        , [eml ["e$template_filter ", mParams Map.! "TEMPLATE"]]
        , [eml ["e$mapgen ", mapgen]]
        , mapgenSpecific
        , concatMap teamSetup ti
        , msgs
        , [em "!"]
        ]
    where
        mapGenTypes = ["+rnd+", "+maze+", "+drawn+"]
        maybeScript = let s = head . fromMaybe ["Normal"] $ Map.lookup "SCRIPT" prms in if s == "Normal" then [] else [eml ["escript Scripts/Multiplayer/", s, ".lua"]]
        maybeMap = let m = mParams Map.! "MAP" in if m `elem` mapGenTypes then [] else [eml ["emap ", m]]
        scheme = tail $ prms Map.! "SCHEME"
        mapgen = mParams Map.! "MAPGEN"
        mapgenSpecific = case mapgen of
            "1" -> [eml ["e$maze_size ", head $ prms Map.! "MAZE_SIZE"]]
            "2" -> let d = head $ prms Map.! "DRAWNMAP" in if null $ tail d then [] else drawnMapData d
            _ -> []
        gameFlags :: Word32
        gameFlags = foldl (\r (b, f) -> if b == "false" then r else r .|. f) 0 $ zip scheme gameFlagConsts
        schemeFlags = map (\(v, (n, m)) -> eml [n, " ", showB $ (readInt_ v) * m])
            $ filter (\(_, (n, _)) -> not $ B.null n)
            $ zip (drop (length gameFlagConsts) scheme) schemeParams
        ammoStr :: B.ByteString
        ammoStr = head . tail $ prms Map.! "AMMO"
        ammo = let l = B.length ammoStr `div` 4; ((a, b), (c, d)) = (B.splitAt l . fst &&& B.splitAt l . snd) . B.splitAt (l * 2) $ ammoStr in
                   (map (\(x, y) -> eml [x, " ", y]) $ zip ["eammloadt", "eammprob", "eammdelay", "eammreinf"] [a, b, c, d])
                   ++ [em "eammstore" | scheme !! 14 == "true" || scheme !! 20 == "false"]
        initHealth = scheme !! 27
        teamSetup :: TeamInfo -> [B.ByteString]
        teamSetup t = (++) ammo $
                eml ["eaddteam <hash> ", showB $ (1 + (readInt_ $ teamcolor t) :: Int) * 2113696, " ", teamname t]
                : em "erdriven"
                : eml ["efort ", teamfort t]
                : take (2 * hhnum t) (
                    concatMap (\(HedgehogInfo hname hhat) -> [
                            eml ["eaddhh ", showB $ difficulty t, " ", initHealth, " ", hname]
                            , eml ["ehat ", hhat]
                            ])
                        $ hedgehogs t
                        )

drawnMapData :: B.ByteString -> [B.ByteString]
drawnMapData =
          L.map (\m -> eml ["edraw ", BW.pack m])
        . L.unfoldr by200
        . BL.unpack
        . Z.decompress
        . BL.pack
        . L.drop 4
        . fromMaybe []
        . Base64.decode
        . B.unpack
    where
        by200 :: [a] -> Maybe ([a], [a])
        by200 [] = Nothing
        by200 m = Just $ L.splitAt 200 m

schemeParams :: [(B.ByteString, Int)]
schemeParams = [
      ("e$damagepct", 1)
    , ("e$turntime", 1000)
    , ("", 0)
    , ("e$sd_turns", 1)
    , ("e$casefreq", 1)
    , ("e$minestime", 1000)
    , ("e$minesnum", 1)
    , ("e$minedudpct", 1)
    , ("e$explosives", 1)
    , ("e$healthprob", 1)
    , ("e$hcaseamount", 1)
    , ("e$waterrise", 1)
    , ("e$healthdec", 1)
    , ("e$ropepct", 1)
    , ("e$getawaytime", 1)
    ]


gameFlagConsts :: [Word32]
gameFlagConsts = [
          0x00001000
        , 0x00000010
        , 0x00000004
        , 0x00000008
        , 0x00000020
        , 0x00000040
        , 0x00000080
        , 0x00000100
        , 0x00000200
        , 0x00000400
        , 0x00000800
        , 0x00002000
        , 0x00004000
        , 0x00008000
        , 0x00010000
        , 0x00020000
        , 0x00040000
        , 0x00080000
        , 0x00100000
        , 0x00200000
        , 0x00400000
        , 0x00800000
        , 0x01000000
        , 0x02000000
        , 0x04000000
        ]



