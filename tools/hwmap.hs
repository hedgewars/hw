module Main where

import qualified Data.ByteString.Char8 as B
import qualified Data.ByteString as BW
import qualified Data.ByteString.Lazy as BL
import qualified Codec.Binary.Base64 as Base64
import Data.Word
import Data.Int
import Data.Binary
import Data.Binary.Put
import Data.Bits
import Control.Monad
import qualified Codec.Compression.Zlib as Z

data LineType = Solid | Erasing
    deriving Eq

data Chunk = SpecialPoints [(Int16, Int16)]
    | Line LineType Word8 [(Int16, Int16)]

transform :: ((Int16, Int16) -> (Int16, Int16)) -> [Chunk] -> [Chunk]
transform f = map tf
    where
    tf (SpecialPoints p) = SpecialPoints $ map f p
    tf (Line t r p) = Line t r $ map f p
    
scale f = transform (\(a, b) -> (a * f, b * f))
mirror = transform (\(a, b) -> (4095 - a, b))
translate dx dy = transform (\(a, b) -> (a + dx, b + dy))

instance Binary Chunk where
    put (SpecialPoints p) = do
        forM_ p $ \(x, y) -> do
            put x
            put y
            putWord8 0
    put (Line lt r ((x1, y1):ps)) = do
        let flags = r .|. (if lt == Solid then 0 else (1 `shift` 6))
        put x1
        put y1
        putWord8 $ flags .|. (1 `shift` 7)
        forM_ ps $ \(x, y) -> do
            put x
            put y
            putWord8 flags
    get = undefined

compressWithLength :: BL.ByteString -> BL.ByteString
compressWithLength b = BL.drop 8 . encode . runPut $ do
    put $ ((fromIntegral $ BL.length b)::Word32)
    mapM_ putWord8 $ BW.unpack $ BL.toStrict $ Z.compress b

mapString :: B.ByteString
mapString = B.pack . Base64.encode . BW.unpack . BL.toStrict . compressWithLength . BL.drop 8 . encode $ drawnMap02

main = B.writeFile "out.hwmap" mapString

drawnMap01 = translate (-3) (-3) $ sp ++ mirror sp ++ base ++ mirror base
    where
    sp = translate 128 128 . scale 256 $ [SpecialPoints [
        (6, 0)
        , (1, 4)
        , (4, 7)
        , (7, 5)
        ]]
    base = scale 256 $ [
        l [(5, 0), (5, 1)]
        , l [(7, 0), (7, 1)]
        , l [(8, 1), (6, 1), (6, 4)]
        , l [(8, 1), (8, 6), (6, 6), (6, 7), (8, 7)]
        , l [(7, 2), (7, 5), (5, 5)]
        , l [(5, 3), (5, 8)]
        , l [(6, 2), (4, 2)]
        , l [(1, 1), (4, 1), (4, 7)]
        , l [(3, 5), (3, 7), (2, 7), (2, 8)]
        , l [(2, 1), (2, 2)]
        , l [(0, 2), (1, 2), (1, 3), (3, 3), (3, 2)]
        , l [(0, 5), (1, 5)]
        , l [(1, 4), (4, 4)]
        , l [(2, 4), (2, 6), (1, 6), (1, 7)]
        , l [(0, 8), (8, 8)]
        ]
    l = Line Solid 0

drawnMap02 = translate (-3) (-3) $ sp ++ mirror sp ++ base ++ mirror base
    where
    sp = translate 128 128 . scale 256 $ [SpecialPoints [
        (7, 0)
        , (7, 7)
        ]]
    base = scale 256 $ [
        l [(8, 0), (8, 1), (1, 1)]
        , l [(2, 1), (2, 2), (3, 2), (3, 3), (4, 3), (4, 4), (5, 4), (5, 5), (6, 5), (6, 6), (7, 6), (7, 7), (7, 1)]
        , l [(0, 2), (1, 2), (1, 3), (2, 3), (2, 4), (3, 4), (3, 5), (4, 5), (4, 6), (5, 6), (5, 7), (6, 7), (6, 8), (8, 8), (8, 2)]
        ]
    l = Line Solid 0
