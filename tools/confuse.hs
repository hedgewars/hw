{-# LANGUAGE OverloadedStrings #-}
module Confuse where

import Numeric
import Data.Char
import Control.Monad
import qualified Data.ByteString as B
import qualified Data.ByteString.UTF8 as UTF8
import qualified Data.Map as Map

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

convRules :: (B.ByteString, [B.ByteString]) -> B.ByteString
convRules (a, b) = B.concat ["<reset>", u a, "</reset>\n<s>", B.concat $ map u b, "</s>"]
    where
        u a = B.concat ["\\","u",a]

toPair :: String -> (B.ByteString, [B.ByteString])
toPair s = (UTF8.fromString $ takeWhile isHexDigit s, map UTF8.fromString . words . takeWhile ((/=) ';') . tail $ dropWhile ((/=) '\t') s)


main = do
    ll <- liftM (filter (isHexDigit . head) . filter (not . null) . lines) $ readFile "confusables.txt"
    B.writeFile "rules.txt" . B.intercalate "\n" . map convRules . Map.toList . Map.fromList . filter notTooLong . filter fits16bit . map toPair $ ll
    where
        notTooLong = (>) 6 . length . snd
        fits16bit (a, b) = let f = (>) 5 . B.length in all f $ a:b
        
