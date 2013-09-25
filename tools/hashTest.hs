module Test where

import Control.Monad
import Data.Word
import qualified Data.IntSet as IS

data OP = Sum
        | Mul
        | Sub
    deriving Show


genOps :: Int -> [[OP]]
genOps 1 = [[Sum], [Mul], [Sub]]
genOps n = [a : as | a <- [Sum, Mul, Sub], as <- genOps (n - 1)]


genPos :: Int -> Int -> [[Int]]
genPos m 1 = map (:[]) [-m..m - 1]
genPos m n = [a : as | a <- [-m..m - 1], as <- genPos m (n - 1)]


hash :: [Int] -> [OP] -> [Int] -> Int
hash poss op s = foldl applyOp s' (zip ss op)
    where
        applyOp v (n, Sum) = (v + n) `mod` 256
        applyOp v (n, Mul) = (v * n) `mod` 256
        applyOp v (n, Sub) = (v - n) `mod` 256
        (s' : ss) = map (\p -> if p >= 0 then s !! p else s !! (l + p)) poss
        l = length s


test = do
    a <- liftM lines getContents
    let w = minimum $ map length a
    let opsNum = 4
    let opsList = genOps (opsNum - 1)
    let posList = genPos w opsNum
    let target = length a
    let wordsList = map (map fromEnum) a
    let hashedSize = IS.size . IS.fromList
    print $ length a
    putStrLn . unlines . map show $ filter (\l -> fst l == length a) $ [(hs, (p, o)) | p <- posList, o <- opsList, let hs = hashedSize . map (hash p o) $ wordsList]

didIunderstand' = do
    a <- liftM lines getContents
    print $ length a
    print . IS.size . IS.fromList . map (testHash . map fromEnum) $ a
    where
        testHash s = let l = length s in (
                         (s !! (l - 2) * s !! 1) + s !! (l - 1) - s !! 0
                         ) `mod` 256
