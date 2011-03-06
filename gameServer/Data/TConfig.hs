-- Module      : Data.TConfig
-- Copyright   : (c) Anthony Simpson 2009
-- License     : BSD3
--
-- Maintainer  : DiscipleRayne@gmail.com
-- Stability   : relatively stable
-- Portability : portable
---------------------------------------------------
{-|
  A small and simple text file configuration
  library written in Haskell. It is similar
  to the INI file format, but lacks a few of
  it's features, such as sections. It is
  suitable for simple games that need to
  keep track of certain information between
  plays.
-}
module Data.TConfig
    (
     getValue
   , repConfig
   , readConfig
   , writeConfig
   , remKey
   , addKey
   , Conf ()
   ) where

import Data.Char
import qualified Data.Map as M

type Key   = String
type Value = String
type Conf  = M.Map Key Value

-- |Adds a key and value to the end of the configuration.
addKey :: Key -> Value -> Conf -> Conf
addKey k v conf = M.insert k (addQuotes v) conf

-- |Utility Function. Checks for the existence
-- of a key.
checkKey :: Key -> Conf -> Bool
checkKey k conf = M.member k conf

-- |Utility function.
-- Removes a key and it's value from the configuration.
remKey :: Key -> Conf -> Conf
remKey k conf = M.delete k conf

-- |Utility function. Searches a configuration for a
-- key, and returns it's value.
getValue :: Key -> Conf -> Maybe Value
getValue k conf = case M.lookup k conf of
                    Just val -> Just $ stripQuotes val
                    Nothing  -> Nothing

stripQuotes :: String -> String
stripQuotes x | any isSpace x = filter (/= '\"') x
              | otherwise     = x

-- |Returns a String wrapped in quotes if it
-- contains spaces, otherwise returns the string
-- untouched.
addQuotes :: String -> String
addQuotes x | any isSpace x = "\"" ++ x ++ "\""
            | otherwise     = x

-- |Utility function. Replaces the value
-- associated with a key in a configuration.
repConfig :: Key -> Value -> Conf -> Conf
repConfig k rv conf = let f _ = Just rv
                      in M.alter f k conf

-- |Reads a file and parses to a Map String String.
readConfig :: FilePath -> IO Conf
readConfig path = readFile path >>= return . parseConfig

-- |Parses a parsed configuration back to a file.
writeConfig :: FilePath -> Conf -> IO ()
writeConfig path con = writeFile path $ putTogether con

-- |Turns a list of configuration types back into a String
-- to write to a file.
putTogether :: Conf -> String
putTogether = concat . putTogether' . backToString
    where putTogether' (x:y:xs) = x : " = " : y : "\n" : putTogether' xs
          putTogether' _        = []

-- |Turns a list of configuration types into a list of Strings
backToString :: Conf -> [String]
backToString conf = backToString' $ M.toList conf
    where backToString' ((x,y):xs) = x : y : backToString' xs
          backToString' _          = []

-- |Parses a string into a list of Configuration types.
parseConfig :: String -> Conf
parseConfig = listConfig . popString . parse

parse :: String -> [String]
parse = words . filter (/= '=')

-- |Turns a list of key value key value etc... pairs into
-- A list of Configuration types.
listConfig :: [String] -> Conf
listConfig = M.fromList . helper
    where helper (x:y:xs) = (x,y) : helper xs
          helper _        = []

-- |Parses strings from the parseConfig'd file.
popString :: [String] -> [String]
popString []     = []
popString (x:xs)
    | head x == '\"' = findClose $ break (('\"' ==) . last) xs
    | otherwise      = x : popString xs
    where findClose (y,ys) =
              [unwords $ x : y ++ [head ys]] ++ popString (tail ys)
