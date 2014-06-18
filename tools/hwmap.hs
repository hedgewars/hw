module Main where

import qualified Data.ByteString.Lazy as BL
import Data.Word
import Data.Int
import Data.Binary
import Data.Bits
import Control.Monad

data LineType = Solid | Erasing
    deriving Eq

data Chunk = Line LineType Word8 [(Int16, Int16)]

instance Binary Chunk where
    put (Line lt r ((x1, y1):ps)) = do
        let flags = r .|. (if lt == Solid then 0 else (1 `shift` 6))
        putWord8 $ flags .|. (1 `shift` 7)
        put x1
        put y1
        forM_ ps $ \(x, y) -> do
            putWord8 flags
            put x
            put y
    get = undefined

mapString = BL.drop 8 . encode $
    [
        Line Solid 7 [(0, 0), (2048, 1024), (1024, 768)]
    ]

main = BL.writeFile "out.hwmap" mapString
