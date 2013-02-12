{-# LANGUAGE OverloadedStrings #-}

module EngineInteraction where

import qualified Data.Set as Set
import Control.Monad
import qualified Codec.Binary.Base64 as Base64
import qualified Data.ByteString.Char8 as B
import qualified Data.ByteString as BW
import qualified Data.Map as Map
import qualified Data.List as L
import Data.Word
import Data.Bits
import Control.Arrow
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


splitMessages :: B.ByteString -> [B.ByteString]
splitMessages = L.unfoldr (\b -> if B.null b then Nothing else Just $ B.splitAt (1 + fromIntegral (BW.head b)) b)


checkNetCmd :: B.ByteString -> (B.ByteString, B.ByteString)
checkNetCmd msg = check decoded
    where
        decoded = liftM (splitMessages . BW.pack) $ Base64.decode $ B.unpack msg
        check Nothing = (B.empty, B.empty)
        check (Just msgs) = let (a, b) = (filter isLegal msgs, filter isNonEmpty a) in (encode a, encode b)
        encode = B.pack . Base64.encode . BW.unpack . B.concat
        isLegal m = (B.length m > 1) && (flip Set.member legalMessages . B.head . B.tail $ m)
        isNonEmpty = (/=) '+' . B.head
        legalMessages = Set.fromList $ "M#+LlRrUuDdZzAaSjJ,sNpPwtghbc12345" ++ slotMessages
        slotMessages = "\128\129\130\131\132\133\134\135\136\137\138"


replayToDemo :: [TeamInfo]
        -> Map.Map B.ByteString B.ByteString
        -> Map.Map B.ByteString [B.ByteString]
        -> [B.ByteString]
        -> [B.ByteString]
replayToDemo teams mapParams params msgs = concat [
        [em "TD"]
        , maybeScript
        , maybeMap
        , [eml ["etheme ", head $ params Map.! "THEME"]]
        , [eml ["eseed ", mapParams Map.! "SEED"]]
        , [eml ["e$gmflags ", showB gameFlags]]
        , schemeFlags
        , [eml ["e$template_filter ", mapParams Map.! "TEMPLATE"]]
        , [eml ["e$mapgen ", mapgen]]
        , mapgenSpecific
        , concatMap teamSetup teams
        , msgs
        , [em "!"]
        ]
    where
        em = toEngineMsg
        eml = em . B.concat
        mapGenTypes = ["+rnd+", "+maze+", "+drawn+"]
        maybeScript = let s = head $ params Map.! "SCRIPT" in if s == "Normal" then [] else [eml ["escript Scripts/Multiplayer/", s, ".lua"]]
        maybeMap = let m = mapParams Map.! "MAP" in if m `elem` mapGenTypes then [] else [eml ["emap ", m]]
        scheme = tail $ params Map.! "SCHEME"
        mapgen = mapParams Map.! "MAPGEN"
        mapgenSpecific = case mapgen of
            "+maze+" -> [eml ["e$maze_size ", head $ params Map.! "MAZE_SIZE"]]
            "+drawn" -> drawnMapData . head $ params Map.! "DRAWNMAP"
            _ -> []
        gameFlags :: Word32
        gameFlags = foldl (\r (b, f) -> if b == "false" then r else r .|. f) 0 $ zip scheme gameFlagConsts
        schemeFlags = map (\(v, (n, m)) -> eml [n, " ", showB $ (readInt_ v) * m])
            $ filter (\(_, (n, _)) -> not $ B.null n)
            $ zip (drop (length gameFlagConsts) scheme) schemeParams
        ammoStr :: B.ByteString
        ammoStr = head . tail $ params Map.! "AMMO"
        ammo = let l = B.length ammoStr `div` 4; ((a, b), (c, d)) = (B.splitAt l . fst &&& B.splitAt l . snd) . B.splitAt (l * 2) $ ammoStr in
                   (map (\(x, y) -> eml [x, " ", y]) $ zip ["eammloadt", "eammprob", "eammdelay", "eammreinf"] [a, b, c, d])
                   ++ [em "eammstore" | scheme !! 14 == "true" || scheme !! 20 == "false"]
        initHealth = scheme !! 27
        teamSetup :: TeamInfo -> [B.ByteString]
        teamSetup t = (++) ammo $
                eml ["eaddteam <hash> ", showB $ (1 + (readInt_ $ teamcolor t) :: Int) * 1234, " ", teamname t]
                : em "erdriven"
                : eml ["efort ", teamfort t]
                : replicate (hhnum t) (eml ["eaddhh 0 ", initHealth, " hedgehog"])

drawnMapData :: B.ByteString -> [B.ByteString]
drawnMapData = error "drawnMapData"

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



