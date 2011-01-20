module Actions where

import Control.Concurrent.STM
import Control.Concurrent.Chan
import Data.IntMap
import qualified Data.IntSet as IntSet
import qualified Data.Sequence as Seq
import System.Log.Logger
import Control.Monad
import Data.Time
import Data.Maybe
-----------------------------
import CoreTypes
import Utils

data Action =
    AnswerThisClient [String]
    | AnswerAll [String]
    | AnswerAllOthers [String]
    | AnswerThisRoom [String]
    | AnswerOthersInRoom [String]
    | AnswerSameClan [String]
    | AnswerLobby [String]
    | SendServerMessage
    | SendServerVars
    | RoomAddThisClient Int -- roomID
    | RoomRemoveThisClient String
    | RemoveTeam String
    | RemoveRoom
    | UnreadyRoomClients
    | MoveToLobby
    | ProtocolError String
    | Warning String
    | ByeClient String
    | KickClient Int -- clID
    | KickRoomClient Int -- clID
    | BanClient String -- nick
    | RemoveClientTeams Int -- clID
    | ModifyClient (ClientInfo -> ClientInfo)
    | ModifyClient2 Int (ClientInfo -> ClientInfo)
    | ModifyRoom (RoomInfo -> RoomInfo)
    | ModifyServerInfo (ServerInfo -> ServerInfo)
    | AddRoom String String
    | CheckRegistered
    | ClearAccountsCache
    | ProcessAccountInfo AccountInfo
    | Dump
    | AddClient ClientInfo
    | PingAll
    | StatsAction

type CmdHandler = Int -> Clients -> Rooms -> [String] -> [Action]

replaceID a (b, c, d, e) = (a, c, d, e)

processAction :: (Int, ServerInfo, Clients, Rooms) -> Action -> IO (Int, ServerInfo, Clients, Rooms)


processAction (clID, serverInfo, clients, rooms) (AnswerThisClient msg) = do
    writeChan (sendChan $ clients ! clID) msg
    return (clID, serverInfo, clients, rooms)


processAction (clID, serverInfo, clients, rooms) (AnswerAll msg) = do
    mapM_ (\cl -> writeChan (sendChan cl) msg) (elems clients)
    return (clID, serverInfo, clients, rooms)


processAction (clID, serverInfo, clients, rooms) (AnswerAllOthers msg) = do
    mapM_ (\id' -> writeChan (sendChan $ clients ! id') msg) $
        Prelude.filter (\id' -> (id' /= clID) && logonPassed (clients ! id')) (keys clients)
    return (clID, serverInfo, clients, rooms)


processAction (clID, serverInfo, clients, rooms) (AnswerThisRoom msg) = do
    mapM_ (\id' -> writeChan (sendChan $ clients ! id') msg) roomClients
    return (clID, serverInfo, clients, rooms)
    where
        roomClients = IntSet.elems $ playersIDs room
        room = rooms ! rID
        rID = roomID client
        client = clients ! clID


processAction (clID, serverInfo, clients, rooms) (AnswerOthersInRoom msg) = do
    mapM_ (\id' -> writeChan (sendChan $ clients ! id') msg) $ Prelude.filter (/= clID) roomClients
    return (clID, serverInfo, clients, rooms)
    where
        roomClients = IntSet.elems $ playersIDs room
        room = rooms ! rID
        rID = roomID client
        client = clients ! clID


processAction (clID, serverInfo, clients, rooms) (AnswerLobby msg) = do
    mapM_ (\id' -> writeChan (sendChan $ clients ! id') msg) roomClients
    return (clID, serverInfo, clients, rooms)
    where
        roomClients = IntSet.elems $ playersIDs room
        room = rooms ! 0


processAction (clID, serverInfo, clients, rooms) (AnswerSameClan msg) = do
    mapM_ (\cl -> writeChan (sendChan cl) msg) sameClanOrSpec
    return (clID, serverInfo, clients, rooms)
    where
        otherRoomClients = Prelude.map ((!) clients) $ IntSet.elems $ clID `IntSet.delete` (playersIDs room)
        sameClanOrSpec = if teamsInGame client > 0 then sameClanClients else spectators
        spectators = Prelude.filter (\cl -> teamsInGame cl == 0) otherRoomClients
        sameClanClients = Prelude.filter (\cl -> teamsInGame cl > 0 && clientClan cl == thisClan) otherRoomClients
        thisClan = clientClan client
        room = rooms ! rID
        rID = roomID client
        client = clients ! clID


processAction (clID, serverInfo, clients, rooms) SendServerMessage = do
    writeChan (sendChan $ clients ! clID) ["SERVER_MESSAGE", message serverInfo]
    return (clID, serverInfo, clients, rooms)
    where
        client = clients ! clID
        message si = if clientProto client < latestReleaseVersion si then
            serverMessageForOldVersions si
            else
            serverMessage si

processAction (clID, serverInfo, clients, rooms) SendServerVars = do
    writeChan (sendChan $ clients ! clID) ("SERVER_VARS" : vars)
    return (clID, serverInfo, clients, rooms)
    where
        client = clients ! clID
        vars = [
            "MOTD_NEW", serverMessage serverInfo, 
            "MOTD_OLD", serverMessageForOldVersions serverInfo, 
            "LATEST_PROTO", show $ latestReleaseVersion serverInfo
            ]


processAction (clID, serverInfo, clients, rooms) (ProtocolError msg) = do
    writeChan (sendChan $ clients ! clID) ["ERROR", msg]
    return (clID, serverInfo, clients, rooms)


processAction (clID, serverInfo, clients, rooms) (Warning msg) = do
    writeChan (sendChan $ clients ! clID) ["WARNING", msg]
    return (clID, serverInfo, clients, rooms)


processAction (clID, serverInfo, clients, rooms) (ByeClient msg) = do
    infoM "Clients" (show (clientUID client) ++ " quits: " ++ msg)
    (_, _, newClients, newRooms) <-
            if roomID client /= 0 then
                processAction  (clID, serverInfo, clients, rooms) $ RoomRemoveThisClient "quit"
                else
                    return (clID, serverInfo, clients, rooms)

    mapM_ (processAction (clID, serverInfo, newClients, newRooms)) $ answerOthersQuit ++ answerInformRoom
    writeChan (sendChan $ clients ! clID) ["BYE", msg]
    return (
            0,
            serverInfo,
            delete clID newClients,
            adjust (\r -> r{
                    playersIDs = IntSet.delete clID (playersIDs r),
                    playersIn = (playersIn r) - 1,
                    readyPlayers = if isReady client then readyPlayers r - 1 else readyPlayers r
                    }) (roomID $ newClients ! clID) newRooms
            )
    where
        client = clients ! clID
        clientNick = nick client
        answerInformRoom =
            if roomID client /= 0 then
                if not $ Prelude.null msg then
                    [AnswerThisRoom ["LEFT", clientNick, msg]]
                else
                    [AnswerThisRoom ["LEFT", clientNick]]
            else
                []
        answerOthersQuit =
            if logonPassed client then
                if not $ Prelude.null msg then
                    [AnswerAll ["LOBBY:LEFT", clientNick, msg]]
                else
                    [AnswerAll ["LOBBY:LEFT", clientNick]]
            else
                []


processAction (clID, serverInfo, clients, rooms) (ModifyClient func) =
    return (clID, serverInfo, adjust func clID clients, rooms)


processAction (clID, serverInfo, clients, rooms) (ModifyClient2 cl2ID func) =
    return (clID, serverInfo, adjust func cl2ID clients, rooms)


processAction (clID, serverInfo, clients, rooms) (ModifyRoom func) =
    return (clID, serverInfo, clients, adjust func rID rooms)
    where
        rID = roomID $ clients ! clID


processAction (clID, serverInfo, clients, rooms) (ModifyServerInfo func) =
    return (clID, func serverInfo, clients, rooms)


processAction (clID, serverInfo, clients, rooms) (RoomAddThisClient rID) =
    processAction (
        clID,
        serverInfo,
        adjust (\cl -> cl{roomID = rID, teamsInGame = if rID == 0 then teamsInGame cl else 0}) clID clients,
        adjust (\r -> r{playersIDs = IntSet.insert clID (playersIDs r), playersIn = (playersIn r) + 1}) rID $
            adjust (\r -> r{playersIDs = IntSet.delete clID (playersIDs r)}) 0 rooms
        ) joinMsg
    where
        client = clients ! clID
        joinMsg = if rID == 0 then
                AnswerAllOthers ["LOBBY:JOINED", nick client]
            else
                AnswerThisRoom ["JOINED", nick client]


processAction (clID, serverInfo, clients, rooms) (RoomRemoveThisClient msg) = do
    (_, _, newClients, newRooms) <-
        if roomID client /= 0 then
            if isMaster client then
                if (gameinprogress room) && (playersIn room > 1) then
                    (changeMaster >>= (\state -> foldM processAction state
                        [AnswerOthersInRoom ["LEFT", nick client, msg],
                        AnswerOthersInRoom ["WARNING", "Admin left the room"],
                        RemoveClientTeams clID]))
                else -- not in game
                    processAction (clID, serverInfo, clients, rooms) RemoveRoom
            else -- not master
                foldM
                    processAction
                        (clID, serverInfo, clients, rooms)
                        [AnswerOthersInRoom ["LEFT", nick client, msg],
                        RemoveClientTeams clID]
        else -- in lobby
            return (clID, serverInfo, clients, rooms)
    
    return (
        clID,
        serverInfo,
        adjust resetClientFlags clID newClients,
        adjust removeClientFromRoom rID $ adjust insertClientToRoom 0 newRooms
        )
    where
        rID = roomID client
        client = clients ! clID
        room = rooms ! rID
        resetClientFlags cl = cl{roomID = 0, isMaster = False, isReady = False, teamsInGame = undefined}
        removeClientFromRoom r = r{
                playersIDs = otherPlayersSet,
                playersIn = (playersIn r) - 1,
                readyPlayers = if isReady client then (readyPlayers r) - 1 else readyPlayers r
                }
        insertClientToRoom r = r{playersIDs = IntSet.insert clID (playersIDs r)}
        changeMaster = do
            processAction (newMasterId, serverInfo, clients, rooms) $ AnswerThisClient ["ROOM_CONTROL_ACCESS", "1"]
            return (
                clID,
                serverInfo,
                adjust (\cl -> cl{isMaster = True}) newMasterId clients,
                adjust (\r -> r{masterID = newMasterId, name = newRoomName}) rID rooms
                )
        newRoomName = nick newMasterClient
        otherPlayersSet = IntSet.delete clID (playersIDs room)
        newMasterId = IntSet.findMin otherPlayersSet
        newMasterClient = clients ! newMasterId


processAction (clID, serverInfo, clients, rooms) (AddRoom roomName roomPassword) = do
    let newServerInfo = serverInfo {nextRoomID = newID}
    let room = newRoom{
            roomUID = newID,
            masterID = clID,
            name = roomName,
            password = roomPassword,
            roomProto = (clientProto client)
            }

    processAction (clID, serverInfo, clients, rooms) $ AnswerLobby ["ROOM", "ADD", roomName]

    processAction (
        clID,
        newServerInfo,
        adjust (\cl -> cl{isMaster = True}) clID clients,
        insert newID room rooms
        ) $ RoomAddThisClient newID
    where
        newID = (nextRoomID serverInfo) - 1
        client = clients ! clID


processAction (clID, serverInfo, clients, rooms) (RemoveRoom) = do
    processAction (clID, serverInfo, clients, rooms) $ AnswerLobby ["ROOM", "DEL", name room]
    processAction (clID, serverInfo, clients, rooms) $ AnswerOthersInRoom ["ROOMABANDONED", name room]
    return (clID,
        serverInfo,
        Data.IntMap.map (\cl -> if roomID cl == rID then cl{roomID = 0, isMaster = False, isReady = False, teamsInGame = undefined} else cl) clients,
        delete rID $ adjust (\r -> r{playersIDs = IntSet.union (playersIDs room) (playersIDs r)}) 0 rooms
        )
    where
        room = rooms ! rID
        rID = roomID client
        client = clients ! clID


processAction (clID, serverInfo, clients, rooms) (UnreadyRoomClients) = do
    processAction (clID, serverInfo, clients, rooms) $ AnswerThisRoom ("NOT_READY" : roomPlayers)
    return (clID,
        serverInfo,
        Data.IntMap.map (\cl -> if roomID cl == rID then cl{isReady = False} else cl) clients,
        adjust (\r -> r{readyPlayers = 0}) rID rooms)
    where
        room = rooms ! rID
        rID = roomID client
        client = clients ! clID
        roomPlayers = Prelude.map (nick . (clients !)) roomPlayersIDs
        roomPlayersIDs = IntSet.elems $ playersIDs room


processAction (clID, serverInfo, clients, rooms) (RemoveTeam teamName) = do
    newRooms <- if not $ gameinprogress room then
            do
            processAction (clID, serverInfo, clients, rooms) $ AnswerOthersInRoom ["REMOVE_TEAM", teamName]
            return $
                adjust (\r -> r{teams = Prelude.filter (\t -> teamName /= teamname t) $ teams r}) rID rooms
        else
            do
            processAction (clID, serverInfo, clients, rooms) $ AnswerOthersInRoom ["EM", rmTeamMsg]
            return $
                adjust (\r -> r{
                teams = Prelude.filter (\t -> teamName /= teamname t) $ teams r,
                leftTeams = teamName : leftTeams r,
                roundMsgs = roundMsgs r Seq.|> rmTeamMsg
                }) rID rooms
    return (clID, serverInfo, clients, newRooms)
    where
        room = rooms ! rID
        rID = roomID client
        client = clients ! clID
        rmTeamMsg = toEngineMsg $ 'F' : teamName


processAction (clID, serverInfo, clients, rooms) (CheckRegistered) = do
    writeChan (dbQueries serverInfo) $ CheckAccount (clientUID client) (nick client) (host client)
    return (clID, serverInfo, clients, rooms)
    where
        client = clients ! clID


processAction (clID, serverInfo, clients, rooms) (ClearAccountsCache) = do
    writeChan (dbQueries serverInfo) ClearCache
    return (clID, serverInfo, clients, rooms)
    where
        client = clients ! clID


processAction (clID, serverInfo, clients, rooms) (Dump) = do
    writeChan (sendChan $ clients ! clID) ["DUMP", show serverInfo, showTree clients, showTree rooms]
    return (clID, serverInfo, clients, rooms)


processAction (clID, serverInfo, clients, rooms) (ProcessAccountInfo info) =
    case info of
        HasAccount passwd isAdmin -> do
            infoM "Clients" $ show clID ++ " has account"
            writeChan (sendChan $ clients ! clID) ["ASKPASSWORD"]
            return (clID, serverInfo, adjust (\cl -> cl{webPassword = passwd, isAdministrator = isAdmin}) clID clients, rooms)
        Guest -> do
            infoM "Clients" $ show clID ++ " is guest"
            processAction (clID, serverInfo, adjust (\cl -> cl{logonPassed = True}) clID clients, rooms) MoveToLobby
        Admin -> do
            infoM "Clients" $ show clID ++ " is admin"
            foldM processAction (clID, serverInfo, adjust (\cl -> cl{logonPassed = True, isAdministrator = True}) clID clients, rooms) [MoveToLobby, AnswerThisClient ["ADMIN_ACCESS"]]


processAction (clID, serverInfo, clients, rooms) (MoveToLobby) =
    foldM processAction (clID, serverInfo, clients, rooms) $
        (RoomAddThisClient 0)
        : answerLobbyNicks
        ++ [SendServerMessage]

        -- ++ (answerServerMessage client clients)
    where
        lobbyNicks = Prelude.map nick $ Prelude.filter logonPassed $ elems clients
        answerLobbyNicks = [AnswerThisClient ("LOBBY:JOINED": lobbyNicks) | not $ Prelude.null lobbyNicks]


processAction (clID, serverInfo, clients, rooms) (KickClient kickID) = do
    let client = clients ! clID
    currentTime <- getCurrentTime
    liftM2 replaceID (return clID) (processAction (kickID, serverInfo{lastLogins = (host client, (addUTCTime 60 $ currentTime, "60 seconds ban")) : lastLogins serverInfo}, clients, rooms) $ ByeClient "Kicked")


processAction (clID, serverInfo, clients, rooms) (BanClient banNick) =
    return (clID, serverInfo, clients, rooms)


processAction (clID, serverInfo, clients, rooms) (KickRoomClient kickID) = do
    writeChan (sendChan $ clients ! kickID) ["KICKED"]
    liftM2 replaceID (return clID) (processAction (kickID, serverInfo, clients, rooms) $ RoomRemoveThisClient "kicked")


processAction (clID, serverInfo, clients, rooms) (RemoveClientTeams teamsClID) =
    liftM2 replaceID (return clID) $
        foldM processAction (teamsClID, serverInfo, clients, rooms) removeTeamsActions
    where
        client = clients ! teamsClID
        room = rooms ! (roomID client)
        teamsToRemove = Prelude.filter (\t -> teamowner t == nick client) $ teams room
        removeTeamsActions = Prelude.map (RemoveTeam . teamname) teamsToRemove


processAction (clID, serverInfo, clients, rooms) (AddClient client) = do
    let updatedClients = insert (clientUID client) client clients
    infoM "Clients" (show (clientUID client) ++ ": New client. Time: " ++ show (connectTime client))
    writeChan (sendChan client) ["CONNECTED", "Hedgewars server http://www.hedgewars.org/"]

    let newLogins = takeWhile (\(_ , (time, _)) -> (connectTime client) `diffUTCTime` time <= 0) $ lastLogins serverInfo

    let info = host client `Prelude.lookup` newLogins
    if isJust info then
        processAction (clID, serverInfo{lastLogins = newLogins}, updatedClients, rooms) $ ByeClient (snd .  fromJust $ info)
        else
        return (clID, serverInfo{lastLogins = (host client, (addUTCTime 10 $ connectTime client, "Reconnected too fast")) : newLogins}, updatedClients, rooms)


processAction (clID, serverInfo, clients, rooms) PingAll = do
    (_, _, newClients, newRooms) <- foldM kickTimeouted (clID, serverInfo, clients, rooms) $ elems clients
    processAction (clID,
        serverInfo,
        Data.IntMap.map (\cl -> cl{pingsQueue = pingsQueue cl + 1}) newClients,
        newRooms) $ AnswerAll ["PING"]
    where
        kickTimeouted (clID, serverInfo, clients, rooms) client =
            if pingsQueue client > 0 then
                processAction (clientUID client, serverInfo, clients, rooms) $ ByeClient "Ping timeout"
                else
                return (clID, serverInfo, clients, rooms)


processAction (clID, serverInfo, clients, rooms) (StatsAction) = do
    writeChan (dbQueries serverInfo) $ SendStats (size clients) (size rooms - 1)
    return (clID, serverInfo, clients, rooms)
