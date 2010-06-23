module HandlerUtils where

import Control.Monad.Reader
import qualified Data.ByteString.Char8 as B

import RoomsAndClients
import CoreTypes
import Actions

thisClient :: Reader (ClientIndex, IRnC) ClientInfo
thisClient = do
    (ci, rnc) <- ask
    return $ rnc `client` ci

clientNick :: Reader (ClientIndex, IRnC) B.ByteString
clientNick = liftM nick thisClient

roomOthersChans :: Reader (ClientIndex, IRnC) [ClientChan]
roomOthersChans = do
    (ci, rnc) <- ask
    let ri = clientRoom rnc ci
    return $ map (sendChan . client rnc) $ filter (/= ci) (roomClients rnc ri)

thisClientChans :: Reader (ClientIndex, IRnC) [ClientChan]
thisClientChans = do
    (ci, rnc) <- ask
    return $ [sendChan (rnc `client` ci)]

answerClient :: [B.ByteString] -> Reader (ClientIndex, IRnC) [Action]
answerClient msg = thisClientChans >>= return . (: []) . flip AnswerClients msg

allRoomInfos :: Reader (a, IRnC) [RoomInfo]
allRoomInfos = liftM ((\irnc -> map (room irnc) $ allRooms irnc) . snd) ask
