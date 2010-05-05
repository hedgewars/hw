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
    firstIndex,
    withIStore,
    withIStore2,
    (!),
    indices
    ) where

import qualified Data.Array.IArray as IA
import qualified Data.Array.IO as IOA
import qualified Data.IntSet as IntSet
import Data.IORef
import Control.Monad


newtype ElemIndex = ElemIndex Int
    deriving (Eq)
newtype MStore e = MStore (IORef (IntSet.IntSet, IntSet.IntSet, IOA.IOArray Int e))
newtype IStore e = IStore (IntSet.IntSet, IA.Array Int e)

instance Show ElemIndex where
    show (ElemIndex i) = 'i' : show i

firstIndex :: ElemIndex
firstIndex = ElemIndex 0

-- MStore code
initialSize :: Int
initialSize = 10


growFunc :: Int -> Int
growFunc a = a * 3 `div` 2


newStore :: IO (MStore e)
newStore = do
    newar <- IOA.newArray_ (0, initialSize - 1)
    new <- newIORef (IntSet.empty, IntSet.fromAscList [0..initialSize - 1], newar)
    return (MStore new)


growStore :: MStore e -> IO ()
growStore (MStore ref) = do
    (busyElems, freeElems, arr) <- readIORef ref
    (_, m') <- IOA.getBounds arr
    let newM' = growFunc (m' + 1) - 1
    newArr <- IOA.newArray_ (0, newM')
    sequence_ [IOA.readArray arr i >>= IOA.writeArray newArr i | i <- [0..m']]
    writeIORef ref (busyElems, freeElems `IntSet.union` (IntSet.fromAscList [m'+1..newM']), newArr)


growIfNeeded :: MStore e -> IO ()
growIfNeeded m@(MStore ref) = do
    (_, freeElems, _) <- readIORef ref
    when (IntSet.null freeElems) $ growStore m


addElem :: MStore e -> e -> IO ElemIndex
addElem m@(MStore ref) element = do
    growIfNeeded m
    (busyElems, freeElems, arr) <- readIORef ref
    let (n, freeElems') = IntSet.deleteFindMin freeElems
    IOA.writeArray arr n element
    writeIORef ref (IntSet.insert n busyElems, freeElems', arr)
    return $ ElemIndex n


removeElem :: MStore e -> ElemIndex -> IO ()
removeElem (MStore ref) (ElemIndex n) = do
    (busyElems, freeElems, arr) <- readIORef ref
    IOA.writeArray arr n undefined
    writeIORef ref (IntSet.delete n busyElems, IntSet.insert n freeElems, arr)


readElem :: MStore e -> ElemIndex -> IO e
readElem (MStore ref) (ElemIndex n) = readIORef ref >>= \(_, _, arr) -> IOA.readArray arr n


writeElem :: MStore e -> ElemIndex -> e -> IO ()
writeElem (MStore ref) (ElemIndex n) el = readIORef ref >>= \(_, _, arr) -> IOA.writeArray arr n el


modifyElem :: MStore e -> (e -> e) -> ElemIndex -> IO ()
modifyElem (MStore ref) f (ElemIndex n) = do
    (_, _, arr) <- readIORef ref
    IOA.readArray arr n >>= (IOA.writeArray arr n) . f


-- A way to use see MStore elements in pure code via IStore
m2i :: MStore e -> IO (IStore e)
m2i (MStore ref) = do
    (a, _, c') <- readIORef ref 
    c <- IOA.unsafeFreeze c'
    return $ IStore (a, c)

withIStore :: MStore e -> (IStore e -> a) -> IO a
withIStore m f = liftM f (m2i m)


withIStore2 :: MStore e1 -> MStore e2 -> (IStore e1 -> IStore e2 -> a) -> IO a
withIStore2 m1 m2 f = do
    i1 <- m2i m1
    i2 <- m2i m2
    return $ f i1 i2


-- IStore code
(!) :: IStore e -> ElemIndex -> e
(!) (IStore (_, arr)) (ElemIndex i) = (IA.!) arr i

indices :: IStore e -> [ElemIndex]
indices (IStore (busy, _)) = map ElemIndex $ IntSet.toList busy
