
module Actions where

import Control.Concurrent
import Control.Concurrent.Chan
import qualified Data.IntSet as IntSet
import qualified Data.Sequence as Seq
import System.Log.Logger
import Monad
import Data.Time
import Maybe
import Control.Monad.Reader
import Control.Monad.State

-----------------------------
import CoreTypes
import Utils
import ClientIO
import ServerState

data Action =
    AnswerClients [ClientChan] [String]
    | SendServerMessage
    | SendServerVars
    | RoomAddThisClient RoomIndex -- roomID
    | RoomRemoveThisClient String
    | RemoveTeam String
    | RemoveRoom
    | UnreadyRoomClients
    | MoveToLobby
    | ProtocolError String
    | Warning String
    | ByeClient String
    | KickClient ClientIndex -- clID
    | KickRoomClient ClientIndex -- clID
    | BanClient String -- nick
    | RemoveClientTeams ClientIndex -- clID
    | ModifyClient (ClientInfo -> ClientInfo)
    | ModifyClient2 ClientIndex (ClientInfo -> ClientInfo)
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

type CmdHandler = [String] -> Reader (ClientIndex, IRnC) [Action]


processAction :: Action -> StateT ServerState IO ()


processAction (AnswerClients chans msg) = 
    liftIO $ mapM_ (flip writeChan msg) chans


{-
processAction (clID, serverInfo, rnc) SendServerMessage = do
    writeChan (sendChan $ clients ! clID) ["SERVER_MESSAGE", message serverInfo]
    return (clID, serverInfo, rnc)
    where
        client = clients ! clID
        message si = if clientProto client < latestReleaseVersion si then
            serverMessageForOldVersions si
            else
            serverMessage si

processAction (clID, serverInfo, rnc) SendServerVars = do
    writeChan (sendChan $ clients ! clID) ("SERVER_VARS" : vars)
    return (clID, serverInfo, rnc)
    where
        client = clients ! clID
        vars = [
            "MOTD_NEW", serverMessage serverInfo,
            "MOTD_OLD", serverMessageForOldVersions serverInfo,
            "LATEST_PROTO", show $ latestReleaseVersion serverInfo
            ]


processAction (clID, serverInfo, rnc) (ProtocolError msg) = do
    writeChan (sendChan $ clients ! clID) ["ERROR", msg]
    return (clID, serverInfo, rnc)


processAction (clID, serverInfo, rnc) (Warning msg) = do
    writeChan (sendChan $ clients ! clID) ["WARNING", msg]
    return (clID, serverInfo, rnc)
-}

processAction (ByeClient msg) = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients
    ri <- clientRoomA
    when (ri /= lobbyId) $ do
        processAction $ RoomRemoveThisClient ("quit: " ++ msg)
        return ()

    chan <- clients sendChan

    liftIO $ do
        infoM "Clients" (show ci ++ " quits: " ++ msg)

        
        --mapM_ (processAction (ci, serverInfo, rnc)) $ answerOthersQuit ++ answerInformRoom
        writeChan chan ["BYE", msg]
        modifyRoom rnc (\r -> r{
                        --playersIDs = IntSet.delete ci (playersIDs r)
                        playersIn = (playersIn r) - 1
                        --readyPlayers = if isReady client then readyPlayers r - 1 else readyPlayers r
                        }) ri
    
{-
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
-}

processAction (ModifyClient f) = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients
    liftIO $ modifyClient rnc f ci
    return ()
    

processAction (ModifyRoom f) = do
    rnc <- gets roomsClients
    ri <- clientRoomA
    liftIO $ modifyRoom rnc f ri
    return ()

{-

processAction (clID, serverInfo, rnc) (ModifyServerInfo func) =
    return (clID, func serverInfo, rnc)


processAction (clID, serverInfo, rnc) (RoomAddThisClient rID) =
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


processAction (clID, serverInfo, rnc) (RoomRemoveThisClient msg) = do
    (_, _, newClients, newRooms) <-
        if roomID client /= 0 then
            if isMaster client then
                if (gameinprogress room) && (playersIn room > 1) then
                    (changeMaster >>= (\state -> foldM processAction state
                        [AnswerOthersInRoom ["LEFT", nick client, msg],
                        AnswerOthersInRoom ["WARNING", "Admin left the room"],
                        RemoveClientTeams clID]))
                else -- not in game
                    processAction (clID, serverInfo, rnc) RemoveRoom
            else -- not master
                foldM
                    processAction
                        (clID, serverInfo, rnc)
                        [AnswerOthersInRoom ["LEFT", nick client, msg],
                        RemoveClientTeams clID]
        else -- in lobby
            return (clID, serverInfo, rnc)

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
            processAction (newMasterId, serverInfo, rnc) $ AnswerThisClient ["ROOM_CONTROL_ACCESS", "1"]
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


processAction (clID, serverInfo, rnc) (AddRoom roomName roomPassword) = do
    let newServerInfo = serverInfo {nextRoomID = newID}
    let room = newRoom{
            roomUID = newID,
            masterID = clID,
            name = roomName,
            password = roomPassword,
            roomProto = (clientProto client)
            }

    processAction (clID, serverInfo, rnc) $ AnswerLobby ["ROOM", "ADD", roomName]

    processAction (
        clID,
        newServerInfo,
        adjust (\cl -> cl{isMaster = True}) clID clients,
        insert newID room rooms
        ) $ RoomAddThisClient newID
    where
        newID = (nextRoomID serverInfo) - 1
        client = clients ! clID


processAction (clID, serverInfo, rnc) (RemoveRoom) = do
    processAction (clID, serverInfo, rnc) $ AnswerLobby ["ROOM", "DEL", name room]
    processAction (clID, serverInfo, rnc) $ AnswerOthersInRoom ["ROOMABANDONED", name room]
    return (clID,
        serverInfo,
        Data.IntMap.map (\cl -> if roomID cl == rID then cl{roomID = 0, isMaster = False, isReady = False, teamsInGame = undefined} else cl) clients,
        delete rID $ adjust (\r -> r{playersIDs = IntSet.union (playersIDs room) (playersIDs r)}) 0 rooms
        )
    where
        room = rooms ! rID
        rID = roomID client
        client = clients ! clID


processAction (clID, serverInfo, rnc) (UnreadyRoomClients) = do
    processAction (clID, serverInfo, rnc) $ AnswerThisRoom ("NOT_READY" : roomPlayers)
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


processAction (clID, serverInfo, rnc) (RemoveTeam teamName) = do
    newRooms <- if not $ gameinprogress room then
            do
            processAction (clID, serverInfo, rnc) $ AnswerOthersInRoom ["REMOVE_TEAM", teamName]
            return $
                adjust (\r -> r{teams = Prelude.filter (\t -> teamName /= teamname t) $ teams r}) rID rooms
        else
            do
            processAction (clID, serverInfo, rnc) $ AnswerOthersInRoom ["EM", rmTeamMsg]
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
-}

processAction CheckRegistered = do
    (Just ci) <- gets clientIndex
    n <- clients nick
    h <- clients host
    db <- gets (dbQueries . serverInfo)
    liftIO $ writeChan db $ CheckAccount ci n h
    return ()

{-
processAction (clID, serverInfo, rnc) (ClearAccountsCache) = do
    writeChan (dbQueries serverInfo) ClearCache
    return (clID, serverInfo, rnc)
    where
        client = clients ! clID


processAction (clID, serverInfo, rnc) (Dump) = do
    writeChan (sendChan $ clients ! clID) ["DUMP", show serverInfo, showTree clients, showTree rooms]
    return (clID, serverInfo, rnc)


processAction (clID, serverInfo, rnc) (ProcessAccountInfo info) =
    case info of
        HasAccount passwd isAdmin -> do
            infoM "Clients" $ show clID ++ " has account"
            writeChan (sendChan $ clients ! clID) ["ASKPASSWORD"]
            return (clID, serverInfo, adjust (\cl -> cl{webPassword = passwd, isAdministrator = isAdmin}) clID rnc)
        Guest -> do
            infoM "Clients" $ show clID ++ " is guest"
            processAction (clID, serverInfo, adjust (\cl -> cl{logonPassed = True}) clID rnc) MoveToLobby
        Admin -> do
            infoM "Clients" $ show clID ++ " is admin"
            foldM processAction (clID, serverInfo, adjust (\cl -> cl{logonPassed = True, isAdministrator = True}) clID rnc) [MoveToLobby, AnswerThisClient ["ADMIN_ACCESS"]]


processAction (clID, serverInfo, rnc) (MoveToLobby) =
    foldM processAction (clID, serverInfo, rnc) $
        (RoomAddThisClient 0)
        : answerLobbyNicks
        ++ [SendServerMessage]

        -- ++ (answerServerMessage client clients)
    where
        lobbyNicks = Prelude.map nick $ Prelude.filter logonPassed $ elems clients
        answerLobbyNicks = [AnswerThisClient ("LOBBY:JOINED": lobbyNicks) | not $ Prelude.null lobbyNicks]


processAction (clID, serverInfo, rnc) (KickClient kickID) =
    liftM2 replaceID (return clID) (processAction (kickID, serverInfo, rnc) $ ByeClient "Kicked")


processAction (clID, serverInfo, rnc) (BanClient banNick) =
    return (clID, serverInfo, rnc)


processAction (clID, serverInfo, rnc) (KickRoomClient kickID) = do
    writeChan (sendChan $ clients ! kickID) ["KICKED"]
    liftM2 replaceID (return clID) (processAction (kickID, serverInfo, rnc) $ RoomRemoveThisClient "kicked")


processAction (clID, serverInfo, rnc) (RemoveClientTeams teamsClID) =
    liftM2 replaceID (return clID) $
        foldM processAction (teamsClID, serverInfo, rnc) removeTeamsActions
    where
        client = clients ! teamsClID
        room = rooms ! (roomID client)
        teamsToRemove = Prelude.filter (\t -> teamowner t == nick client) $ teams room
        removeTeamsActions = Prelude.map (RemoveTeam . teamname) teamsToRemove
-}

processAction (AddClient client) = do
    rnc <- gets roomsClients
    si <- gets serverInfo
    liftIO $ do
        ci <- addClient rnc client
        forkIO $ clientRecvLoop (clientHandle client) (coreChan si) ci
        forkIO $ clientSendLoop (clientHandle client) (coreChan si) (sendChan client) ci

        infoM "Clients" (show ci ++ ": New client. Time: " ++ show (connectTime client))
        writeChan (sendChan client) ["CONNECTED", "Hedgewars server http://www.hedgewars.org/"]

{-        let newLogins = takeWhile (\(_ , time) -> (connectTime client) `diffUTCTime` time <= 11) $ lastLogins serverInfo

        if False && (isJust $ host client `Prelude.lookup` newLogins) then
            processAction (ci, serverInfo{lastLogins = newLogins}, rnc) $ ByeClient "Reconnected too fast"
            else
            return (ci, serverInfo)
-}

    


{-
processAction (clID, serverInfo, rnc) PingAll = do
    (_, _, newClients, newRooms) <- foldM kickTimeouted (clID, serverInfo, rnc) $ elems clients
    processAction (clID,
        serverInfo,
        Data.IntMap.map (\cl -> cl{pingsQueue = pingsQueue cl + 1}) newClients,
        newRooms) $ AnswerAll ["PING"]
    where
        kickTimeouted (clID, serverInfo, rnc) client =
            if pingsQueue client > 0 then
                processAction (clientUID client, serverInfo, rnc) $ ByeClient "Ping timeout"
                else
                return (clID, serverInfo, rnc)


processAction (clID, serverInfo, rnc) (StatsAction) = do
    writeChan (dbQueries serverInfo) $ SendStats (size clients) (size rooms - 1)
    return (clID, serverInfo, rnc)

-}
