{-# LANGUAGE OverloadedStrings #-}
module Confuse where

import Numeric
import Data.Char
import Control.Monad
import qualified Data.ByteString as B
import qualified Data.ByteString.UTF8 as UTF8

hx :: [Char] -> String
hx cs = let ch = (chr . fst . last . readHex $ cs) in
            case ch of
                 '\'' -> "''"
                 '\\' -> "\\\\"
                 c -> c : []

conv :: String -> B.ByteString
conv s = B.concat ["('", UTF8.fromString i, "', '", UTF8.fromString r, "')"]
    where
        i :: String
        i = hx s
        r :: String
        r = concatMap hx . words . takeWhile ((/=) ';') . tail $ dropWhile ((/=) '\t') s

main = do
    ll <- liftM (filter (isHexDigit . head) . filter (not . null) . lines) $ readFile "confusables.txt"
    B.writeFile "insert.sql" . B.intercalate ",\n" . map conv $ ll
