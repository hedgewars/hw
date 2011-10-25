module EngineInteraction where

import qualified Data.Set as Set
import qualified Data.List as List
import Control.Monad
import qualified Codec.Binary.Base64 as Base64
import qualified Data.ByteString.Char8 as B
import qualified Data.ByteString as BW
-------------
import CoreTypes


toEngineMsg :: B.ByteString -> B.ByteString
toEngineMsg msg = B.pack $ Base64.encode (fromIntegral (BW.length msg) : BW.unpack msg)


fromEngineMsg :: B.ByteString -> Maybe B.ByteString
fromEngineMsg msg = liftM BW.pack (Base64.decode (B.unpack msg) >>= removeLength)
    where
        removeLength (x:xs) = if length xs == fromIntegral x then Just xs else Nothing
        removeLength _ = Nothing


checkNetCmd :: B.ByteString -> (Bool, Bool)
checkNetCmd msg = check decoded
    where
        decoded = fromEngineMsg msg
        check Nothing = (False, False)
        check (Just ms) | B.length ms > 0 = let m = B.head ms in (m `Set.member` legalMessages, m == '+')
                        | otherwise        = (False, False)
        legalMessages = Set.fromList $ "M#+LlRrUuDdZzAaSjJ,sNpPwtghbc12345" ++ slotMessages
        slotMessages = "\128\129\130\131\132\133\134\135\136\137\138"

gameInfo2Replay :: GameInfo -> B.ByteString
gameInfo2Replay GameInfo{roundMsgs = rm,
        teamsAtStart = teams,
        giMapParams = params1,
        giParams = params2} = undefined
