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

data Chunk = Line LineType Word8 [(Int16, Int16)]

instance Binary Chunk where
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
mapString = B.pack . Base64.encode . BW.unpack . BL.toStrict . compressWithLength . BL.drop 8 . encode $ drawnMap

main = B.writeFile "out.hwmap" mapString

drawnMap = [
        Line Solid 7 [(0, 0), (2048, 1024), (1024, 768)]
    ]
