{-
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 \-}

{-# LANGUAGE BangPatterns, GeneralizedNewtypeDeriving #-}
module Store(
    ElemIndex(),
    MStore(),
    IStore(),
    newStore,
    addElem,
    removeElem,
    readElem,
    writeElem,
    modifyElem,
    elemExists,
    firstIndex,
    indicesM,
    withIStore,
    withIStore2,
    (!),
    indices
    ) where

import qualified Data.IntSet as IntSet
import qualified Data.Vector as V
import qualified Data.Vector.Mutable as MV
import Data.IORef
import Control.Monad
import Control.DeepSeq


newtype ElemIndex = ElemIndex Int
    deriving (Eq, Show, Read, Ord, NFData)
newtype MStore e = MStore (IORef (IntSet.IntSet, IntSet.IntSet, MV.IOVector e))
newtype IStore e = IStore (IntSet.IntSet, V.Vector e)


firstIndex :: ElemIndex
firstIndex = ElemIndex 0

-- MStore code
initialSize :: Int
initialSize = 16


growFunc :: Int -> Int
growFunc a = a * 3 `div` 2

truncFunc :: Int -> Int
truncFunc a | a > growFunc initialSize = (a `div` 2)
            | otherwise = a


newStore :: IO (MStore e)
newStore = do
    newar <- MV.new initialSize
    new <- newIORef (IntSet.empty, IntSet.fromAscList [0..initialSize - 1], newar)
    return (MStore new)


growStore :: MStore e -> IO ()
growStore (MStore ref) = do
    (busyElems, freeElems, arr) <- readIORef ref
    let oldSize = MV.length arr
    let newSize = growFunc oldSize
    newArr <- MV.grow arr (newSize - oldSize)
    writeIORef ref (busyElems, freeElems `IntSet.union` IntSet.fromAscList [oldSize .. newSize-1], newArr)


growIfNeeded :: MStore e -> IO ()
growIfNeeded m@(MStore ref) = do
    (_, freeElems, _) <- readIORef ref
    when (IntSet.null freeElems) $ growStore m


truncateIfNeeded :: MStore e -> IO ()
truncateIfNeeded (MStore ref) = do
    (busyElems, _, arr) <- readIORef ref
    let oldSize = MV.length arr
    let newSize = truncFunc oldSize
    when (newSize < oldSize && (not $ IntSet.null busyElems) && IntSet.findMax busyElems < newSize) $ do
        writeIORef ref (busyElems, IntSet.fromAscList [0..newSize - 1] `IntSet.difference` busyElems, MV.take newSize arr)


addElem :: MStore e -> e -> IO ElemIndex
addElem m@(MStore ref) element = do
    growIfNeeded m
    (busyElems, freeElems, arr) <- readIORef ref
    let (!n, freeElems') = IntSet.deleteFindMin freeElems
    MV.write arr n element
    writeIORef ref (IntSet.insert n busyElems, freeElems', arr)
    return $ ElemIndex n


removeElem :: MStore e -> ElemIndex -> IO ()
removeElem m@(MStore ref) (ElemIndex n) = do
    (busyElems, freeElems, arr) <- readIORef ref
    MV.write arr n (error $ "Store: no element " ++ show n)
    writeIORef ref (IntSet.delete n busyElems, IntSet.insert n freeElems, arr)
    truncateIfNeeded m


readElem :: MStore e -> ElemIndex -> IO e
readElem (MStore ref) (ElemIndex n) = readIORef ref >>= \(_, _, arr) -> MV.read arr n


writeElem :: MStore e -> ElemIndex -> e -> IO ()
writeElem (MStore ref) (ElemIndex n) el = readIORef ref >>= \(_, _, arr) -> MV.write arr n el


modifyElem :: MStore e -> (e -> e) -> ElemIndex -> IO ()
modifyElem (MStore ref) f (ElemIndex n) = do
    (_, _, arr) <- readIORef ref
    MV.read arr n >>= MV.write arr n . f

elemExists :: MStore e -> ElemIndex -> IO Bool
elemExists (MStore ref) (ElemIndex n) = do
    (_, !free, _) <- readIORef ref
    return $ n `IntSet.notMember` free

indicesM :: MStore e -> IO [ElemIndex]
indicesM (MStore ref) = do
    (!busy, _, _) <- readIORef ref
    return $ map ElemIndex $ IntSet.toList busy


-- A way to see MStore elements in pure code via IStore
m2i :: MStore e -> IO (IStore e)
m2i (MStore ref) = do
    (a, _, c') <- readIORef ref
    c <- V.unsafeFreeze c'
    return $ IStore (a, c)

i2m :: MStore e -> IStore e -> IO ()
i2m (MStore ref) (IStore (_, arr)) = do
    (b, e, _) <- readIORef ref
    a <- V.unsafeThaw arr
    writeIORef ref (b, e, a)

withIStore :: MStore e -> (IStore e -> a) -> IO a
withIStore m f = do
    i <- m2i m
    let res = f i
    res `seq` i2m m i
    return res


withIStore2 :: MStore e1 -> MStore e2 -> (IStore e1 -> IStore e2 -> a) -> IO a
withIStore2 m1 m2 f = do
    i1 <- m2i m1
    i2 <- m2i m2
    let res = f i1 i2
    res `seq` i2m m1 i1
    i2m m2 i2
    return res


-- IStore code
(!) :: IStore e -> ElemIndex -> e
(!) (IStore (_, arr)) (ElemIndex i) = (V.!) arr i

indices :: IStore e -> [ElemIndex]
indices (IStore (busy, _)) = map ElemIndex $ IntSet.toList busy
