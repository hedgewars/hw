module HandlerUtils where

import Control.Monad.Reader

import RoomsAndClients
import CoreTypes
import Actions

thisClient :: Reader (ClientIndex, IRnC) ClientInfo
thisClient = do
    (ci, rnc) <- ask
    return $ rnc `client` ci

clientNick :: Reader (ClientIndex, IRnC) String
clientNick = liftM nick thisClient

roomOthersChans :: Reader (ClientIndex, IRnC) [ClientChan]
roomOthersChans = do
    (ci, rnc) <- ask
    let ri = clientRoom rnc ci
    return $ map (sendChan . client rnc) (roomClients rnc ri)

thisClientChans :: Reader (ClientIndex, IRnC) [ClientChan]
thisClientChans = do
    (ci, rnc) <- ask
    return $ [sendChan (rnc `client` ci)]

answerClient :: [String] -> Reader (ClientIndex, IRnC) [Action]
answerClient msg = thisClientChans >>= return . (: []) . flip AnswerClients msg
