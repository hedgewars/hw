{-# LANGUAGE ScopedTypeVariables, OverloadedStrings #-}

import qualified Data.ByteString.Char8 as B
import Control.Exception as E
import System.Environment
import Control.Monad
import qualified Data.Map as Map
import Data.Word
import Data.Int
import qualified Codec.Binary.Base64 as Base64
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString as BW
import qualified Codec.Compression.Zlib.Internal as ZI
import qualified Codec.Compression.Zlib as Z
import qualified Data.List as L
import qualified Data.Set as Set
import Data.Binary
import Data.Binary.Put
import Data.Bits
import Control.Arrow
import Data.Maybe
import qualified Data.Either as Ei


decompressWithoutExceptions :: BL.ByteString -> BL.ByteString
decompressWithoutExceptions = BL.fromChunks . ZI.foldDecompressStreamWithInput chunk end err decomp
    where
        decomp = ZI.decompressST ZI.zlibFormat ZI.defaultDecompressParams
        chunk = (:)
        end _ = []
        err = const $ [BW.empty]

data HedgehogInfo =
    HedgehogInfo B.ByteString B.ByteString
    deriving (Show, Read)
    
data TeamInfo =
    TeamInfo
    {
        teamowner :: !B.ByteString,
        teamname :: !B.ByteString,
        teamcolor :: !B.ByteString,
        teamgrave :: !B.ByteString,
        teamfort :: !B.ByteString,
        teamvoicepack :: !B.ByteString,
        teamflag :: !B.ByteString,
        isOwnerRegistered :: !Bool,
        difficulty :: !Int,
        hhnum :: !Int,
        hedgehogs :: ![HedgehogInfo]
    }
    deriving (Show, Read)
    
readInt_ :: (Num a) => B.ByteString -> a
readInt_ str =
  case B.readInt str of
       Just (i, t) | B.null t -> fromIntegral i
       _                      -> 0

toEngineMsg :: B.ByteString -> B.ByteString
toEngineMsg msg = fromIntegral (BW.length msg) `BW.cons` msg

em :: B.ByteString -> B.ByteString
em = toEngineMsg

eml :: [B.ByteString] -> B.ByteString
eml = em . B.concat       
    
showB :: (Show a) => a -> B.ByteString
showB = B.pack . show
    
replayToDemo :: [TeamInfo]
        -> Map.Map B.ByteString B.ByteString
        -> Map.Map B.ByteString [B.ByteString]
        -> [B.ByteString]
        -> B.ByteString
replayToDemo ti mParams prms msgs = if not sane then "" else (B.concat $ concat [
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
        , map (Ei.fromRight "" . Base64.decode) $ reverse msgs
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

loadReplay :: String -> IO (Maybe ([TeamInfo], [(B.ByteString, B.ByteString)], [(B.ByteString, [B.ByteString])], [B.ByteString]))
loadReplay fileName = E.handle (\(e :: SomeException) -> return Nothing) $ do
            liftM (Just . read) $ readFile fileName

convert :: String -> IO ()
convert fileName = do
    Just (t, c1, c2, m) <- loadReplay fileName
    B.writeFile (fileName ++ ".hwd") $ replayToDemo t (Map.fromList c1) (Map.fromList c2) m

main = do
    args <- getArgs
    when (length args == 1) $ (convert (head args))
