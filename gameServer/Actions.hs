{-# LANGUAGE OverloadedStrings #-}
module Actions where

import Control.Concurrent
import Control.Concurrent.Chan
import qualified Data.IntSet as IntSet
import qualified Data.Set as Set
import qualified Data.Sequence as Seq
import System.Log.Logger
import Monad
import Data.Time
import Maybe
import Control.Monad.Reader
import Control.Monad.State
import qualified Data.ByteString.Char8 as B
-----------------------------
import CoreTypes
import Utils
import ClientIO
import ServerState

data Action =
    AnswerClients ![ClientChan] ![B.ByteString]
    | SendServerMessage
    | SendServerVars
    | MoveToRoom RoomIndex
    | MoveToLobby B.ByteString
    | RemoveTeam B.ByteString
    | RemoveRoom
    | UnreadyRoomClients
    | JoinLobby
    | ProtocolError B.ByteString
    | Warning B.ByteString
    | ByeClient B.ByteString
    | KickClient ClientIndex
    | KickRoomClient ClientIndex
    | BanClient B.ByteString -- nick
    | RemoveClientTeams ClientIndex
    | ModifyClient (ClientInfo -> ClientInfo)
    | ModifyClient2 ClientIndex (ClientInfo -> ClientInfo)
    | ModifyRoom (RoomInfo -> RoomInfo)
    | ModifyServerInfo (ServerInfo -> ServerInfo)
    | AddRoom B.ByteString B.ByteString
    | CheckRegistered
    | ClearAccountsCache
    | ProcessAccountInfo AccountInfo
    | Dump
    | AddClient ClientInfo
    | DeleteClient ClientIndex
    | PingAll
    | StatsAction

type CmdHandler = [B.ByteString] -> Reader (ClientIndex, IRnC) [Action]


processAction :: Action -> StateT ServerState IO ()


processAction (AnswerClients chans msg) = 
    liftIO $ mapM_ (flip writeChan msg) chans


processAction SendServerMessage = do
    chan <- client's sendChan
    protonum <- client's clientProto
    si <- liftM serverInfo get
    let message = if protonum < latestReleaseVersion si then
            serverMessageForOldVersions si
            else
            serverMessage si
    liftIO $ writeChan chan ["SERVER_MESSAGE", message]
{-

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


-}

processAction (ProtocolError msg) = do
    chan <- client's sendChan
    liftIO $ writeChan chan ["ERROR", msg]


processAction (Warning msg) = do
    chan <- client's sendChan
    liftIO $ writeChan chan ["WARNING", msg]

processAction (ByeClient msg) = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients
    ri <- clientRoomA
    when (ri /= lobbyId) $ do
        processAction $ MoveToLobby ("quit: " `B.append` msg)
        return ()

    chan <- client's sendChan
    ready <- client's isReady

    liftIO $ do
        infoM "Clients" (show ci ++ " quits: " ++ (B.unpack msg))

        --mapM_ (processAction (ci, serverInfo, rnc)) $ answerOthersQuit ++ answerInformRoom
        writeChan chan ["BYE", msg]
        modifyRoom rnc (\r -> r{
                        --playersIDs = IntSet.delete ci (playersIDs r)
                        playersIn = (playersIn r) - 1,
                        readyPlayers = if ready then readyPlayers r - 1 else readyPlayers r
                        }) ri

        removeClient rnc ci

    modify (\s -> s{removedClients = ci `Set.insert` removedClients s})

processAction (DeleteClient ci) = do
    modify (\s -> s{removedClients = ci `Set.delete` removedClients s})

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

processAction (ModifyClient2 ci f) = do
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

-}

processAction (MoveToRoom ri) = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients
    liftIO $ do
        modifyClient rnc (\cl -> cl{teamsInGame = 0}) ci
        modifyRoom rnc (\r -> r{playersIn = (playersIn r) + 1}) ri

    liftIO $ moveClientToRoom rnc ri ci

    chans <- liftM (map sendChan) $ roomClientsS ri
    clNick <- client's nick

    processAction $ AnswerClients chans ["JOINED", clNick]

processAction (MoveToLobby msg) = do
    (Just ci) <- gets clientIndex
    --ri <- clientRoomA
    rnc <- gets roomsClients

    liftIO $ moveClientToLobby rnc ci

{-
    (_, _, newClients, newRooms) <-
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
-}

processAction (AddRoom roomName roomPassword) = do
    Just clId <- gets clientIndex
    rnc <- gets roomsClients
    proto <- liftIO $ client'sM rnc clientProto clId

    let room = newRoom{
            masterID = clId,
            name = roomName,
            password = roomPassword,
            roomProto = proto
            }

    rId <- liftIO $ addRoom rnc room

    processAction $ MoveToRoom rId

    chans <- liftM (map sendChan) $ roomClientsS lobbyId

    mapM_ processAction [
        AnswerClients chans ["ROOM", "ADD", roomName]
        , ModifyClient (\cl -> cl{isMaster = True})
        ]

{-
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

-}
processAction (UnreadyRoomClients) = do
    rnc <- gets roomsClients
    ri <- clientRoomA
    roomPlayers <- roomClientsS ri
    roomClIDs <- liftIO $ roomClientsIndicesM rnc ri
    processAction $ AnswerClients (map sendChan roomPlayers) ("NOT_READY" : map nick roomPlayers)
    liftIO $ mapM_ (modifyClient rnc (\cl -> cl{isReady = False})) roomClIDs
    processAction $ ModifyRoom (\r -> r{readyPlayers = 0})


processAction (RemoveTeam teamName) = do
    rnc <- gets roomsClients
    cl <- client's id
    ri <- clientRoomA
    inGame <- liftIO $ room'sM rnc gameinprogress ri
    chans <- liftM (map sendChan . filter (/= cl)) $ roomClientsS ri
    if inGame then
            mapM_ processAction [
                AnswerClients chans ["REMOVE_TEAM", teamName],
                ModifyRoom (\r -> r{teams = Prelude.filter (\t -> teamName /= teamname t) $ teams r})
                ]
        else
            mapM_ processAction [
                AnswerClients chans ["EM", rmTeamMsg],
                ModifyRoom (\r -> r{
                    teams = Prelude.filter (\t -> teamName /= teamname t) $ teams r,
                    leftTeams = teamName : leftTeams r,
                    roundMsgs = roundMsgs r Seq.|> rmTeamMsg
                    })
                ]
    where
        rmTeamMsg = toEngineMsg $ (B.singleton 'F') `B.append` teamName

processAction CheckRegistered = do
    (Just ci) <- gets clientIndex
    n <- client's nick
    h <- client's host
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
-}

processAction (ProcessAccountInfo info) =
    case info of
        HasAccount passwd isAdmin -> do
            chan <- client's sendChan
            liftIO $ writeChan chan ["ASKPASSWORD"]
        Guest -> do
            processAction JoinLobby
        Admin -> do
            mapM processAction [ModifyClient (\cl -> cl{isAdministrator = True}), JoinLobby]
            chan <- client's sendChan
            liftIO $ writeChan chan ["ADMIN_ACCESS"]


processAction JoinLobby = do
    chan <- client's sendChan
    clientNick <- client's nick
    (lobbyNicks, clientsChans) <- liftM (unzip . Prelude.map (\c -> (nick c, sendChan c)) . Prelude.filter logonPassed) $! allClientsS
    mapM_ processAction $
        (AnswerClients clientsChans ["LOBBY:JOINED", clientNick])
        : [AnswerClients [chan] ("LOBBY:JOINED" : clientNick : lobbyNicks)]
        ++ [ModifyClient (\cl -> cl{logonPassed = True}), SendServerMessage]

{-
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
        forkIO $ clientRecvLoop (clientSocket client) (coreChan si) ci
        forkIO $ clientSendLoop (clientSocket client) (coreChan si) (sendChan client) ci

        infoM "Clients" (show ci ++ ": New client. Time: " ++ show (connectTime client))
        writeChan (sendChan client) ["CONNECTED", "Hedgewars server http://www.hedgewars.org/"]

{-        let newLogins = takeWhile (\(_ , time) -> (connectTime client) `diffUTCTime` time <= 11) $ lastLogins serverInfo

        if False && (isJust $ host client `Prelude.lookup` newLogins) then
            processAction (ci, serverInfo{lastLogins = newLogins}, rnc) $ ByeClient "Reconnected too fast"
            else
            return (ci, serverInfo)
-}



processAction PingAll = do
    rnc <- gets roomsClients
    cis <- liftIO $ allClientsM rnc
    mapM_ (kickTimeouted rnc) $ cis
    chans <- liftIO $ mapM (client'sM rnc sendChan) cis
    liftIO $ mapM_ (modifyClient rnc (\cl -> cl{pingsQueue = pingsQueue cl + 1})) cis
    processAction $ AnswerClients chans ["PING"]
    where
        kickTimeouted rnc ci = do
            pq <- liftIO $ client'sM rnc pingsQueue ci
            when (pq > 0) $
                withStateT (\as -> as{clientIndex = Just ci}) $
                    processAction (ByeClient "Ping timeout")


processAction (StatsAction) = do
    rnc <- gets roomsClients
    si <- gets serverInfo
    (roomsNum, clientsNum) <- liftIO $ withRoomsAndClients rnc stats
    liftIO $ writeChan (dbQueries si) $ SendStats clientsNum (roomsNum - 1)
    where
          stats irnc = (length $ allRooms irnc, length $ allClients irnc)

