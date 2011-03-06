module HandlerUtils where

import Control.Monad.Reader
import qualified Data.ByteString.Char8 as B
import Data.List

import RoomsAndClients
import CoreTypes
import Actions

thisClient :: Reader (ClientIndex, IRnC) ClientInfo
thisClient = do
    (ci, rnc) <- ask
    return $ rnc `client` ci

thisRoom :: Reader (ClientIndex, IRnC) RoomInfo
thisRoom = do
    (ci, rnc) <- ask
    let ri = clientRoom rnc ci
    return $ rnc `room` ri

clientNick :: Reader (ClientIndex, IRnC) B.ByteString
clientNick = liftM nick thisClient

roomOthersChans :: Reader (ClientIndex, IRnC) [ClientChan]
roomOthersChans = do
    (ci, rnc) <- ask
    let ri = clientRoom rnc ci
    return $ map (sendChan . client rnc) $ filter (/= ci) (roomClients rnc ri)

roomSameClanChans :: Reader (ClientIndex, IRnC) [ClientChan]
roomSameClanChans = do
    (ci, rnc) <- ask
    let ri = clientRoom rnc ci
    let otherRoomClients = map (client rnc) . filter (/= ci) $ roomClients rnc ri
    let cl = rnc `client` ci
    let sameClanClients = Prelude.filter (\c -> clientClan c == clientClan cl) otherRoomClients
    return $ map sendChan sameClanClients

roomClientsChans :: Reader (ClientIndex, IRnC) [ClientChan]
roomClientsChans = do
    (ci, rnc) <- ask
    let ri = clientRoom rnc ci
    return $ map (sendChan . client rnc) (roomClients rnc ri)

thisClientChans :: Reader (ClientIndex, IRnC) [ClientChan]
thisClientChans = do
    (ci, rnc) <- ask
    return [sendChan (rnc `client` ci)]

answerClient :: [B.ByteString] -> Reader (ClientIndex, IRnC) [Action]
answerClient msg = liftM ((: []) . flip AnswerClients msg) thisClientChans

allRoomInfos :: Reader (a, IRnC) [RoomInfo]
allRoomInfos = liftM ((\irnc -> map (room irnc) $ allRooms irnc) . snd) ask

clientByNick :: B.ByteString -> Reader (ClientIndex, IRnC) (Maybe ClientIndex)
clientByNick n = do
    (_, rnc) <- ask
    let allClientIDs = allClients rnc
    return $ find (\clId -> n == nick (client rnc clId)) allClientIDs

