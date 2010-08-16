module RoomsAndClients(
    RoomIndex(),
    ClientIndex(),
    MRoomsAndClients(),
    IRoomsAndClients(),
    newRoomsAndClients,
    addRoom,
    addClient,
    removeRoom,
    removeClient,
    modifyRoom,
    modifyClient,
    lobbyId,
    moveClientToLobby,
    moveClientToRoom,
    clientRoom,
    clientRoomM,
    clientExists,
    client,
    room,
    client'sM,
    room'sM,
    allClientsM,
    clientsM,
    roomClientsM,
    roomClientsIndicesM,
    withRoomsAndClients,
    allRooms,
    allClients,
    clientRoom,
    showRooms,
    roomClients
    ) where


import Store
import Control.Monad


data Room r = Room {
    roomClients' :: [ClientIndex],
    room' :: r
    }


data Client c = Client {
    clientRoom' :: RoomIndex,
    client' :: c
    }


newtype RoomIndex = RoomIndex ElemIndex
    deriving (Eq)
newtype ClientIndex = ClientIndex ElemIndex
    deriving (Eq, Show, Read, Ord)

instance Show RoomIndex where
    show (RoomIndex i) = 'r' : show i

unRoomIndex :: RoomIndex -> ElemIndex
unRoomIndex (RoomIndex r) = r

unClientIndex :: ClientIndex -> ElemIndex
unClientIndex (ClientIndex c) = c


newtype MRoomsAndClients r c = MRoomsAndClients (MStore (Room r), MStore (Client c))
newtype IRoomsAndClients r c = IRoomsAndClients (IStore (Room r), IStore (Client c))


lobbyId :: RoomIndex
lobbyId = RoomIndex firstIndex


newRoomsAndClients :: r -> IO (MRoomsAndClients r c)
newRoomsAndClients r = do
    rooms <- newStore
    clients <- newStore
    let rnc = MRoomsAndClients (rooms, clients)
    ri <- addRoom rnc r
    when (ri /= lobbyId) $ error "Empty struct inserts not at firstIndex index"
    return rnc


roomAddClient :: ClientIndex -> Room r -> Room r
roomAddClient cl room = room{roomClients' = cl : roomClients' room}

roomRemoveClient :: ClientIndex -> Room r -> Room r
roomRemoveClient cl room = room{roomClients' = filter (/= cl) $ roomClients' room}


addRoom :: MRoomsAndClients r c -> r -> IO RoomIndex
addRoom (MRoomsAndClients (rooms, _)) room = do
    i <- addElem rooms (Room  [] room)
    return $ RoomIndex i


addClient :: MRoomsAndClients r c -> c -> IO ClientIndex
addClient (MRoomsAndClients (rooms, clients)) client = do
    i <- addElem clients (Client lobbyId client)
    modifyElem rooms (roomAddClient (ClientIndex i)) (unRoomIndex lobbyId)
    return $ ClientIndex i

removeRoom :: MRoomsAndClients r c -> RoomIndex -> IO ()
removeRoom rnc@(MRoomsAndClients (rooms, _)) room@(RoomIndex ri) 
    | room == lobbyId = error "Cannot delete lobby"
    | otherwise = do
        clIds <- liftM roomClients' $ readElem rooms ri
        forM_ clIds (moveClientToLobby rnc)
        removeElem rooms ri


removeClient :: MRoomsAndClients r c -> ClientIndex -> IO ()
removeClient (MRoomsAndClients (rooms, clients)) cl@(ClientIndex ci) = do
    RoomIndex ri <- liftM clientRoom' $ readElem clients ci
    modifyElem rooms (roomRemoveClient cl) ri
    removeElem clients ci


modifyRoom :: MRoomsAndClients r c -> (r -> r) -> RoomIndex -> IO ()
modifyRoom (MRoomsAndClients (rooms, _)) f (RoomIndex ri) = modifyElem rooms (\r -> r{room' = f $ room' r}) ri

modifyClient :: MRoomsAndClients r c -> (c -> c) -> ClientIndex -> IO ()
modifyClient (MRoomsAndClients (_, clients)) f (ClientIndex ci) = modifyElem clients (\c -> c{client' = f $ client' c}) ci

moveClientInRooms :: MRoomsAndClients r c -> RoomIndex -> RoomIndex -> ClientIndex -> IO ()
moveClientInRooms (MRoomsAndClients (rooms, clients)) (RoomIndex riFrom) rt@(RoomIndex riTo) cl@(ClientIndex ci) = do
    modifyElem rooms (roomRemoveClient cl) riFrom
    modifyElem rooms (roomAddClient cl) riTo
    modifyElem clients (\c -> c{clientRoom' = rt}) ci


moveClientToLobby :: MRoomsAndClients r c -> ClientIndex -> IO ()
moveClientToLobby rnc ci = do
    room <- clientRoomM rnc ci
    moveClientInRooms rnc room lobbyId ci


moveClientToRoom :: MRoomsAndClients r c -> RoomIndex -> ClientIndex -> IO ()
moveClientToRoom rnc ri ci = moveClientInRooms rnc lobbyId ri ci


clientExists :: MRoomsAndClients r c -> ClientIndex -> IO Bool
clientExists (MRoomsAndClients (_, clients)) (ClientIndex ci) = elemExists clients ci

clientRoomM :: MRoomsAndClients r c -> ClientIndex -> IO RoomIndex
clientRoomM (MRoomsAndClients (_, clients)) (ClientIndex ci) = liftM clientRoom' (clients `readElem` ci)

client'sM :: MRoomsAndClients r c -> (c -> a) -> ClientIndex -> IO a
client'sM (MRoomsAndClients (_, clients)) f (ClientIndex ci) = liftM (f . client') (clients `readElem` ci)

room'sM :: MRoomsAndClients r c -> (r -> a) -> RoomIndex -> IO a
room'sM (MRoomsAndClients (rooms, _)) f (RoomIndex ri) = liftM (f . room') (rooms `readElem` ri)

allClientsM :: MRoomsAndClients r c -> IO [ClientIndex]
allClientsM (MRoomsAndClients (_, clients)) = liftM (map ClientIndex) $ indicesM clients

clientsM :: MRoomsAndClients r c -> IO [c]
clientsM (MRoomsAndClients (_, clients)) = indicesM clients >>= mapM (\ci -> liftM client' $ readElem clients ci)

roomClientsIndicesM :: MRoomsAndClients r c -> RoomIndex -> IO [ClientIndex]
roomClientsIndicesM (MRoomsAndClients (rooms, clients)) (RoomIndex ri) = liftM roomClients' (rooms `readElem` ri)

roomClientsM :: MRoomsAndClients r c -> RoomIndex -> IO [c]
roomClientsM (MRoomsAndClients (rooms, clients)) (RoomIndex ri) = liftM roomClients' (rooms `readElem` ri) >>= mapM (\(ClientIndex ci) -> liftM client' $ readElem clients ci)

withRoomsAndClients :: MRoomsAndClients r c -> (IRoomsAndClients r c -> a) -> IO a
withRoomsAndClients (MRoomsAndClients (rooms, clients)) f =
    withIStore2 rooms clients (\r c -> f $ IRoomsAndClients (r, c))

----------------------------------------
----------- IRoomsAndClients -----------

showRooms :: (Show r, Show c) => IRoomsAndClients r c -> String
showRooms rnc@(IRoomsAndClients (rooms, clients)) = concatMap showRoom (allRooms rnc)
    where
    showRoom r = unlines $ ((show r) ++ ": " ++ (show $ room' $ rooms ! (unRoomIndex r))) : (map showClient (roomClients' $ rooms ! (unRoomIndex r)))
    showClient c = "    " ++ (show c) ++ ": " ++ (show $ client' $ clients ! (unClientIndex c))


allRooms :: IRoomsAndClients r c -> [RoomIndex]
allRooms (IRoomsAndClients (rooms, _)) = map RoomIndex $ indices rooms

allClients :: IRoomsAndClients r c -> [ClientIndex]
allClients (IRoomsAndClients (_, clients)) = map ClientIndex $ indices clients

clientRoom :: IRoomsAndClients r c -> ClientIndex -> RoomIndex
clientRoom (IRoomsAndClients (_, clients)) (ClientIndex ci) = clientRoom' (clients ! ci)

client :: IRoomsAndClients r c -> ClientIndex -> c
client (IRoomsAndClients (_, clients)) (ClientIndex ci) = client' (clients ! ci)

room :: IRoomsAndClients r c -> RoomIndex -> r
room (IRoomsAndClients (rooms, _)) (RoomIndex ri) = room' (rooms ! ri)

roomClients :: IRoomsAndClients r c -> RoomIndex -> [ClientIndex]
roomClients (IRoomsAndClients (rooms, _)) (RoomIndex ri) = roomClients' $ (rooms ! ri)
