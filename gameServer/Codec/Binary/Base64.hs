-- |
-- Module    : Codec.Binary.Base64
-- Copyright : (c) 2007 Magnus Therning
-- License   : BSD3
--
-- Implemented as specified in RFC 4648
-- (<http://tools.ietf.org/html/rfc4648>).
--
-- Further documentation and information can be found at
-- <http://www.haskell.org/haskellwiki/Library/Data_encoding>.
module Codec.Binary.Base64
    ( encode
    , decode
    , decode'
    , chop
    , unchop
    ) where

import Control.Monad
import Data.Array
import Data.Bits
import Data.Maybe
import Data.Word
import qualified Data.Map as M

-- {{{1 enc/dec map
_encMap =
    [ (0, 'A'), (1, 'B'), (2, 'C'), (3, 'D'), (4, 'E')
    , (5, 'F') , (6, 'G'), (7, 'H'), (8, 'I'), (9, 'J')
    , (10, 'K'), (11, 'L'), (12, 'M'), (13, 'N'), (14, 'O')
    , (15, 'P'), (16, 'Q'), (17, 'R'), (18, 'S'), (19, 'T')
    , (20, 'U'), (21, 'V'), (22, 'W'), (23, 'X'), (24, 'Y')
    , (25, 'Z'), (26, 'a'), (27, 'b'), (28, 'c'), (29, 'd')
    , (30, 'e'), (31, 'f'), (32, 'g'), (33, 'h'), (34, 'i')
    , (35, 'j'), (36, 'k'), (37, 'l'), (38, 'm'), (39, 'n')
    , (40, 'o'), (41, 'p'), (42, 'q'), (43, 'r'), (44, 's')
    , (45, 't'), (46, 'u'), (47, 'v'), (48, 'w'), (49, 'x')
    , (50, 'y'), (51, 'z'), (52, '0'), (53, '1'), (54, '2')
    , (55, '3'), (56, '4'), (57, '5'), (58, '6'), (59, '7')
    , (60, '8'), (61, '9'), (62, '+'), (63, '/') ]

-- {{{1 encodeArray
encodeArray :: Array Word8 Char
encodeArray = array (0, 64) _encMap

-- {{{1 decodeMap
decodeMap :: M.Map Char Word8
decodeMap  = M.fromList [(snd i, fst i) | i <- _encMap]

-- {{{1 encode
-- | Encode data.
encode :: [Word8]
    -> String
encode = let
        pad n = take n $ repeat 0
        enc [] = ""
        enc l@[o] = (++ "==") . take 2 .enc $ l ++ pad 2
        enc l@[o1, o2] = (++ "=") . take 3 . enc $ l ++ pad 1
        enc (o1:o2:o3:os) = let
                i1 = o1 `shiftR` 2
                i2 = (o1 `shiftL` 4 .|. o2 `shiftR` 4) .&. 0x3f
                i3 = (o2 `shiftL` 2 .|. o3 `shiftR` 6) .&. 0x3f
                i4 = o3 .&. 0x3f
            in (foldr (\ i s -> (encodeArray ! i) : s) "" [i1, i2, i3, i4]) ++ enc os
    in enc

-- {{{1 decode
-- | Decode data (lazy).
decode' :: String
    -> [Maybe Word8]
decode' = let
        pad n = take n $ repeat $ Just 0
        dec [] = []
        dec l@[Just eo1, Just eo2] = take 1 . dec $ l ++ pad 2
        dec l@[Just eo1, Just eo2, Just eo3] = take 2 . dec $ l ++ pad 1
        dec (Just eo1:Just eo2:Just eo3:Just eo4:eos) = let
                o1 = eo1 `shiftL` 2 .|. eo2 `shiftR` 4
                o2 = eo2 `shiftL` 4 .|. eo3 `shiftR` 2
                o3 = eo3 `shiftL` 6 .|. eo4
            in Just o1:Just o2:Just o3:(dec eos)
        dec _ = [Nothing]
    in
        dec . map (flip M.lookup decodeMap) . takeWhile (/= '=')

-- | Decode data (strict).
decode :: String
    -> Maybe [Word8]
decode = sequence . decode'

-- {{{1 chop
-- | Chop up a string in parts.
--
--   The length given is rounded down to the nearest multiple of 4.
--
--   /Notes:/
--
--   * PEM requires lines that are 64 characters long.
--
--   * MIME requires lines that are at most 76 characters long.
chop :: Int     -- ^ length of individual lines
    -> String
    -> [String]
chop n "" = []
chop n s = let
        enc_len | n < 4 = 4
                | otherwise = n `div` 4 * 4
    in (take enc_len s) : chop n (drop enc_len s)

-- {{{1 unchop
-- | Concatenate the strings into one long string.
unchop :: [String]
    -> String
unchop = foldr (++) ""
