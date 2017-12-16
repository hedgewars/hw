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

{-# LANGUAGE CPP, OverloadedStrings #-}

#if defined(OFFICIAL_SERVER)
module EngineInteraction(replayToDemo, checkNetCmd, toEngineMsg, drawnMapData, prependGhostPoints) where
#else
module EngineInteraction(checkNetCmd, toEngineMsg) where
#endif

import qualified Data.Set as Set
import Control.Monad
import qualified Codec.Binary.Base64 as Base64
import qualified Data.ByteString.Char8 as B
import qualified Data.ByteString as BW
import qualified Data.ByteString.Lazy as BL
import qualified Data.Map as Map
import qualified Data.List as L
import Data.Word
import Data.Int
import Data.Bits
import Control.Arrow
import Data.Maybe
import Data.Binary
import Data.Binary.Put
-------------
import CoreTypes
import Utils

#if defined(OFFICIAL_SERVER)
import qualified Codec.Compression.Zlib.Internal as ZI
import qualified Codec.Compression.Zlib as Z

decompressWithoutExceptions :: BL.ByteString -> BL.ByteString
decompressWithoutExceptions = BL.fromChunks . ZI.foldDecompressStreamWithInput chunk end err decomp
    where
        decomp = ZI.decompressST ZI.zlibFormat ZI.defaultDecompressParams
        chunk = (:)
        end _ = []
        err = const $ [BW.empty]
#endif

toEngineMsg :: B.ByteString -> B.ByteString
toEngineMsg msg = Base64.encode (fromIntegral (BW.length msg) `BW.cons` msg)


{-fromEngineMsg :: B.ByteString -> Maybe B.ByteString
fromEngineMsg msg = liftM BW.pack (Base64.decode (B.unpack msg) >>= removeLength)
    where
        removeLength (x:xs) = if length xs == fromIntegral x then Just xs else Nothing
        removeLength _ = Nothing-}

em :: B.ByteString -> B.ByteString
em = toEngineMsg

eml :: [B.ByteString] -> B.ByteString
eml = em . B.concat

splitMessages :: B.ByteString -> [B.ByteString]
splitMessages = L.unfoldr (\b -> if B.null b then Nothing else Just $ B.splitAt (1 + fromIntegral (BW.head b)) b)


checkNetCmd :: [Word8] -> B.ByteString -> (B.ByteString, B.ByteString, Maybe (Maybe B.ByteString))
checkNetCmd teamsIndexes msg = check decoded
    where
        decoded = liftM splitMessages $ Base64.decode msg
        check (Left _) = (B.empty, B.empty, Nothing)
        check (Right msgs) = let (a, b) = (filter isLegal msgs, filter isNonEmpty a) in (encode a, encode b, lft a)
        encode = Base64.encode . B.concat
        isLegal m = (B.length m > 1) && (flip Set.member legalMessages . B.head . B.tail $ m) && not (isMalformed (B.head m) (B.tail m))
        lft = foldr l Nothing
        l m n = let m' = B.head $ B.tail m; tst = flip Set.member in
                      if not $ tst timedMessages m' then n
                        else if '+' /= m' then Just Nothing else Just . Just . Base64.encode $ m
        isNonEmpty = (/=) '+' . B.head . B.tail
        legalMessages = Set.fromList $ "M#+LlRrUuDdZzAaSjJ,NpPwtgfhbc12345" ++ slotMessages
        slotMessages = "\128\129\130\131\132\133\134\135\136\137\138"
        timedMessages = Set.fromList $ "+LlRrUuDdZzAaSjJ,NpPwtgfc12345" ++ slotMessages
        isMalformed 'h' m | B.length m >= 3 = let hognum = m `B.index` 1; teamnum = m `BW.index` 2 in hognum < '1' || hognum > '8' || teamnum `L.notElem` teamsIndexes
                          | otherwise = True
        isMalformed _ _ = False

#if defined(OFFICIAL_SERVER)
replayToDemo :: [TeamInfo]
        -> Map.Map B.ByteString B.ByteString
        -> Map.Map B.ByteString [B.ByteString]
        -> [B.ByteString]
        -> (Maybe GameDetails, [B.ByteString])
replayToDemo ti mParams prms msgs = if not sane then (Nothing, []) else (Just $ GameDetails scriptName infRopes vamp infattacks, concat [
        [em "TD"]
        , maybeScript
        , maybeMap
        , [eml ["etheme ", head $ prms Map.! "THEME"]]
        , [eml ["eseed ", mParams Map.! "SEED"]]
        , [eml ["e$gmflags ", showB gameFlags]]
        , schemeFlags
        , schemeAdditional
        , [eml ["e$template_filter ", mParams Map.! "TEMPLATE"]]
        , [eml ["e$feature_size ", mParams Map.! "FEATURE_SIZE"]]
        , [eml ["e$mapgen ", mapgen]]
        , mapgenSpecific
        , concatMap teamSetup ti
        , msgs
        , [em "!"]
        ])
    where
        keys1, keys2 :: Set.Set B.ByteString
        keys1 = Set.fromList ["FEATURE_SIZE", "MAP", "MAPGEN", "MAZE_SIZE", "SEED", "TEMPLATE"]
        keys2 = Set.fromList ["AMMO", "SCHEME", "SCRIPT", "THEME"]
        sane = Set.null (keys1 Set.\\ Map.keysSet mParams)
            && Set.null (keys2 Set.\\ Map.keysSet prms)
            && (not . null . drop 41 $ scheme)
            && (not . null . tail $ prms Map.! "AMMO")
            && ((B.length . head . tail $ prms Map.! "AMMO") > 200)
        mapGenTypes = ["+rnd+", "+maze+", "+drawn+", "+perlin+"]
        scriptName = head . fromMaybe ["Normal"] $ Map.lookup "SCRIPT" prms
        maybeScript = let s = scriptName in if s == "Normal" then [] else [eml ["escript Scripts/Multiplayer/", spaces2Underlining s, ".lua"]]
        maybeMap = let m = mParams Map.! "MAP" in if m `elem` mapGenTypes then [] else [eml ["emap ", m]]
        scheme = tail $ prms Map.! "SCHEME"
        mapgen = mParams Map.! "MAPGEN"
        mazeSizeMsg = eml ["e$maze_size ", mParams Map.! "MAZE_SIZE"]
        mapgenSpecific = case mapgen of
            "1" -> [mazeSizeMsg]
            "2" -> [mazeSizeMsg]
            "3" -> let d = head . fromMaybe [""] $ Map.lookup "DRAWNMAP" prms in if BW.length d <= 4 then [] else drawnMapData d
            _ -> []
        gameFlags :: Word32
        gameFlags = foldl (\r (b, f) -> if b == "false" then r else r .|. f) 0 $ zip scheme gameFlagConsts
        schemeFlags = map (\(v, (n, m)) -> eml [n, " ", showB $ (readInt_ v) * m])
            $ filter (\(_, (n, _)) -> not $ B.null n)
            $ zip (drop (length gameFlagConsts) scheme) schemeParams
        schemeAdditional = let scriptParam = B.tail $ scheme !! 42 in [eml ["e$scriptparam ", scriptParam] | not $ B.null scriptParam]
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
        infRopes = ammoStr `B.index` 7  == '9'
        vamp = gameFlags .&. 0x00000200 /= 0
        infattacks = gameFlags .&. 0x00100000 /= 0
        spaces2Underlining = B.map (\c -> if c == ' ' then '_' else c)

drawnMapData :: B.ByteString -> [B.ByteString]
drawnMapData =
          L.map (\m -> eml ["edraw ", BW.pack m])
        . L.unfoldr by200
        . BL.unpack
        . unpackDrawnMap
    where
        by200 :: [a] -> Maybe ([a], [a])
        by200 [] = Nothing
        by200 m = Just $ L.splitAt 200 m

unpackDrawnMap :: B.ByteString -> BL.ByteString
unpackDrawnMap = either
        (const BL.empty) 
        (decompressWithoutExceptions . BL.pack . drop 4 . BW.unpack)
        . Base64.decode

compressWithLength :: BL.ByteString -> BL.ByteString
compressWithLength b = BL.drop 8 . encode . runPut $ do
    put $ ((fromIntegral $ BL.length b)::Word32)
    mapM_ putWord8 $ BW.unpack $ BL.toStrict $ Z.compress b

packDrawnMap :: BL.ByteString -> B.ByteString
packDrawnMap =
      Base64.encode
    . BL.toStrict
    . compressWithLength

prependGhostPoints :: [(Int16, Int16)] -> B.ByteString -> B.ByteString
prependGhostPoints pts dm = packDrawnMap $ (runPut $ forM_ pts $ \(x, y) -> put x >> put y >> putWord8 99) `BL.append` unpackDrawnMap dm

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
    , ("e$airmines", 1)
    , ("e$healthprob", 1)
    , ("e$hcaseamount", 1)
    , ("e$waterrise", 1)
    , ("e$healthdec", 1)
    , ("e$ropepct", 1)
    , ("e$getawaytime", 1)
    , ("e$worldedge", 1)
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
#endif
