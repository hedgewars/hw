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
import Control.Monad

type Key   = String
type Value = String
type Conf  = M.Map Key Value

-- |Adds a key and value to the end of the configuration.
addKey :: Key -> Value -> Conf -> Conf
addKey = M.insert

-- |Utility function.
-- Removes a key and it's value from the configuration.
remKey :: Key -> Conf -> Conf
remKey = M.delete

-- |Utility function. Searches a configuration for a
-- key, and returns it's value.
getValue :: Key -> Conf -> Maybe Value
getValue = M.lookup

-- |Utility function. Replaces the value
-- associated with a key in a configuration.
repConfig :: Key -> Value -> Conf -> Conf
repConfig k rv conf = let f _ = Just rv
                      in M.alter f k conf

-- |Reads a file and parses to a Map String String.
readConfig :: FilePath -> IO Conf
readConfig path = liftM (M.fromList . map ((\(a, b) -> (filter (not . isSpace) a, dropWhile isSpace b)) . break (== '=')) . filter (not . null) . lines) $ readFile path

-- |Parses a parsed configuration back to a file.
writeConfig :: FilePath -> Conf -> IO ()
writeConfig path = writeFile path . unlines . map (\(a, b) -> a ++ " = " ++ b) . M.toList
