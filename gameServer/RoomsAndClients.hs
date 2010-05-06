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
    lobbyId,
    moveClientToLobby,
    moveClientToRoom,
    clientRoom,
    client,
    allClients,
    withRoomsAndClients,
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
    deriving (Eq, Show, Read)

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
    modifyElem rooms (roomAddClient (ClientIndex i)) rid
    return $ ClientIndex i
    where
        rid = (\(RoomIndex i) -> i) lobbyId

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


clientRoomM :: MRoomsAndClients r c -> ClientIndex -> IO RoomIndex
clientRoomM (MRoomsAndClients (_, clients)) (ClientIndex ci) = liftM clientRoom' (clients `readElem` ci)


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

roomClients :: IRoomsAndClients r c -> RoomIndex -> [ClientIndex]
roomClients (IRoomsAndClients (rooms, _)) (RoomIndex ri) = roomClients' $ (rooms ! ri)
