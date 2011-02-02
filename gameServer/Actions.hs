{-# LANGUAGE OverloadedStrings #-}
module Actions where

import Control.Concurrent
import Control.Concurrent.Chan
import qualified Data.IntSet as IntSet
import qualified Data.Set as Set
import qualified Data.Sequence as Seq
import System.Log.Logger
import Control.Monad
import Data.Time
import Data.Maybe
import Control.Monad.Reader
import Control.Monad.State.Strict
import qualified Data.ByteString.Char8 as B
import Control.DeepSeq
import Data.Time
import Text.Printf
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
    | NoticeMessage Notice
    | ByeClient B.ByteString
    | KickClient ClientIndex
    | KickRoomClient ClientIndex
    | BanClient NominalDiffTime B.ByteString ClientIndex
    | ChangeMaster
    | RemoveClientTeams ClientIndex
    | ModifyClient (ClientInfo -> ClientInfo)
    | ModifyClient2 ClientIndex (ClientInfo -> ClientInfo)
    | ModifyRoom (RoomInfo -> RoomInfo)
    | ModifyServerInfo (ServerInfo -> ServerInfo)
    | AddRoom B.ByteString B.ByteString
    | CheckRegistered
    | ClearAccountsCache
    | ProcessAccountInfo AccountInfo
    | AddClient ClientInfo
    | DeleteClient ClientIndex
    | PingAll
    | StatsAction

type CmdHandler = [B.ByteString] -> Reader (ClientIndex, IRnC) [Action]

instance NFData Action where
    rnf (AnswerClients chans msg) = chans `deepseq` msg `deepseq` ()
    rnf a = a `seq` ()

instance NFData B.ByteString
instance NFData (Chan a)

othersChans = do
    cl <- client's id
    ri <- clientRoomA
    liftM (map sendChan . filter (/= cl)) $ roomClientsS ri

processAction :: Action -> StateT ServerState IO ()


processAction (AnswerClients chans msg) = do
    io $ mapM_ (flip writeChan (msg `deepseq` msg)) (chans `deepseq` chans)


processAction SendServerMessage = do
    chan <- client's sendChan
    protonum <- client's clientProto
    si <- liftM serverInfo get
    let message = if protonum < latestReleaseVersion si then
            serverMessageForOldVersions si
            else
            serverMessage si
    processAction $ AnswerClients [chan] ["SERVER_MESSAGE", message]


processAction SendServerVars = do
    chan <- client's sendChan
    si <- gets serverInfo
    io $ writeChan chan ("SERVER_VARS" : vars si)
    where
        vars si = [
            "MOTD_NEW", serverMessage si,
            "MOTD_OLD", serverMessageForOldVersions si,
            "LATEST_PROTO", B.pack . show $ latestReleaseVersion si
            ]


processAction (ProtocolError msg) = do
    chan <- client's sendChan
    processAction $ AnswerClients [chan] ["ERROR", msg]


processAction (Warning msg) = do
    chan <- client's sendChan
    processAction $ AnswerClients [chan] ["WARNING", msg]

processAction (NoticeMessage n) = do
    chan <- client's sendChan
    processAction $ AnswerClients [chan] ["NOTICE", B.pack . show . fromEnum $ n]

processAction (ByeClient msg) = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients
    ri <- clientRoomA

    chan <- client's sendChan
    clNick <- client's nick

    when (ri /= lobbyId) $ do
        processAction $ MoveToLobby ("quit: " `B.append` msg)
        return ()

    clientsChans <- liftM (Prelude.map sendChan . Prelude.filter logonPassed) $! allClientsS
    io $ do
        infoM "Clients" (show ci ++ " quits: " ++ (B.unpack msg))

    processAction $ AnswerClients [chan] ["BYE", msg]
    processAction $ AnswerClients clientsChans ["LOBBY:LEFT", clNick, msg]

    s <- get
    put $! s{removedClients = ci `Set.insert` removedClients s}

processAction (DeleteClient ci) = do
    rnc <- gets roomsClients
    io $ removeClient rnc ci

    s <- get
    put $! s{removedClients = ci `Set.delete` removedClients s}

processAction (ModifyClient f) = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients
    io $ modifyClient rnc f ci
    return ()

processAction (ModifyClient2 ci f) = do
    rnc <- gets roomsClients
    io $ modifyClient rnc f ci
    return ()


processAction (ModifyRoom f) = do
    rnc <- gets roomsClients
    ri <- clientRoomA
    io $ modifyRoom rnc f ri
    return ()


processAction (ModifyServerInfo f) =
    modify (\s -> s{serverInfo = f $ serverInfo s})


processAction (MoveToRoom ri) = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients

    io $ do
        modifyClient rnc (\cl -> cl{teamsInGame = 0, isReady = False, isMaster = False}) ci
        modifyRoom rnc (\r -> r{playersIn = (playersIn r) + 1}) ri
        moveClientToRoom rnc ri ci

    chans <- liftM (map sendChan) $ roomClientsS ri
    clNick <- client's nick

    processAction $ AnswerClients chans ["JOINED", clNick]


processAction (MoveToLobby msg) = do
    (Just ci) <- gets clientIndex
    ri <- clientRoomA
    rnc <- gets roomsClients
    (gameProgress, playersNum) <- io $ room'sM rnc (\r -> (gameinprogress r, playersIn r)) ri
    ready <- client's isReady
    master <- client's isMaster
--    client <- client's id
    clNick <- client's nick
    chans <- othersChans

    if master then
        if gameProgress && playersNum > 1 then
            mapM_ processAction [ChangeMaster, AnswerClients chans ["LEFT", clNick, msg], NoticeMessage AdminLeft, RemoveClientTeams ci]
            else
            processAction RemoveRoom
        else
        mapM_ processAction [AnswerClients chans ["LEFT", clNick, msg], RemoveClientTeams ci]

    io $ do
            modifyRoom rnc (\r -> r{
                    playersIn = (playersIn r) - 1,
                    readyPlayers = if ready then readyPlayers r - 1 else readyPlayers r
                    }) ri
            moveClientToLobby rnc ci

processAction ChangeMaster = do
    ri <- clientRoomA
    rnc <- gets roomsClients
    newMasterId <- liftM head . io $ roomClientsIndicesM rnc ri
    newMaster <- io $ client'sM rnc id newMasterId
    let newRoomName = nick newMaster
    mapM_ processAction [
        ModifyRoom (\r -> r{masterID = newMasterId, name = newRoomName}),
        ModifyClient2 newMasterId (\c -> c{isMaster = True}),
        AnswerClients [sendChan newMaster] ["ROOM_CONTROL_ACCESS", "1"]
        ]

processAction (AddRoom roomName roomPassword) = do
    Just clId <- gets clientIndex
    rnc <- gets roomsClients
    proto <- io $ client'sM rnc clientProto clId

    let room = newRoom{
            masterID = clId,
            name = roomName,
            password = roomPassword,
            roomProto = proto
            }

    rId <- io $ addRoom rnc room

    processAction $ MoveToRoom rId

    chans <- liftM (map sendChan) $! roomClientsS lobbyId

    mapM_ processAction [
        AnswerClients chans ["ROOM", "ADD", roomName]
        , ModifyClient (\cl -> cl{isMaster = True})
        ]


processAction RemoveRoom = do
    Just clId <- gets clientIndex
    rnc <- gets roomsClients
    ri <- io $ clientRoomM rnc clId
    roomName <- io $ room'sM rnc name ri
    others <- othersChans
    lobbyChans <- liftM (map sendChan) $! roomClientsS lobbyId

    mapM_ processAction [
            AnswerClients lobbyChans ["ROOM", "DEL", roomName],
            AnswerClients others ["ROOMABANDONED", roomName]
        ]

    io $ removeRoom rnc ri


processAction (UnreadyRoomClients) = do
    rnc <- gets roomsClients
    ri <- clientRoomA
    roomPlayers <- roomClientsS ri
    roomClIDs <- io $ roomClientsIndicesM rnc ri
    processAction $ AnswerClients (map sendChan roomPlayers) ("NOT_READY" : map nick roomPlayers)
    io $ mapM_ (modifyClient rnc (\cl -> cl{isReady = False})) roomClIDs
    processAction $ ModifyRoom (\r -> r{readyPlayers = 0})


processAction (RemoveTeam teamName) = do
    rnc <- gets roomsClients
    cl <- client's id
    ri <- clientRoomA
    inGame <- io $ room'sM rnc gameinprogress ri
    chans <- othersChans
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


processAction (RemoveClientTeams clId) = do
    rnc <- gets roomsClients

    removeTeamActions <- io $ do
        clNick <- client'sM rnc nick clId
        rId <- clientRoomM rnc clId
        roomTeams <- room'sM rnc teams rId
        return . Prelude.map (RemoveTeam . teamname) . Prelude.filter (\t -> teamowner t == clNick) $ roomTeams

    mapM_ processAction removeTeamActions



processAction CheckRegistered = do
    (Just ci) <- gets clientIndex
    n <- client's nick
    h <- client's host
    db <- gets (dbQueries . serverInfo)
    io $ writeChan db $ CheckAccount ci n h
    return ()


processAction ClearAccountsCache = do
    dbq <- gets (dbQueries . serverInfo)
    io $ writeChan dbq ClearCache
    return ()


processAction (ProcessAccountInfo info) =
    case info of
        HasAccount passwd isAdmin -> do
            chan <- client's sendChan
            processAction $ AnswerClients [chan] ["ASKPASSWORD"]
        Guest -> do
            processAction JoinLobby
        Admin -> do
            mapM processAction [ModifyClient (\cl -> cl{isAdministrator = True}), JoinLobby]
            chan <- client's sendChan
            processAction $ AnswerClients [chan] ["ADMIN_ACCESS"]


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
                -}
processAction (KickClient kickId) = do
    modify (\s -> s{clientIndex = Just kickId})
    processAction $ ByeClient "Kicked"


processAction (BanClient seconds reason banId) = do
    modify (\s -> s{clientIndex = Just banId})
    clHost <- client's host
    currentTime <- io $ getCurrentTime
    let msg = "Ban for " `B.append` (B.pack . show $ seconds) `B.append` "seconds (" `B.append` msg` B.append` ")"
    mapM_ processAction [
        ModifyServerInfo (\s -> s{lastLogins = (clHost, (addUTCTime seconds $ currentTime, msg)) : lastLogins s})
        , KickClient banId
        ]


processAction (KickRoomClient kickId) = do
    modify (\s -> s{clientIndex = Just kickId})
    ch <- client's sendChan
    mapM_ processAction [AnswerClients [ch] ["KICKED"], MoveToLobby "kicked"]


processAction (AddClient cl) = do
    rnc <- gets roomsClients
    si <- gets serverInfo
    newClId <- io $ do
        ci <- addClient rnc cl
        t <- forkIO $ clientRecvLoop (clientSocket cl) (coreChan si) ci
        forkIO $ clientSendLoop (clientSocket cl) t (coreChan si) (sendChan cl) ci

        infoM "Clients" (show ci ++ ": New client. Time: " ++ show (connectTime cl))

        return ci

    modify (\s -> s{clientIndex = Just newClId})
    processAction $ AnswerClients [sendChan cl] ["CONNECTED", "Hedgewars server http://www.hedgewars.org/"]

    si <- gets serverInfo
    let newLogins = takeWhile (\(_ , (time, _)) -> (connectTime cl) `diffUTCTime` time <= 0) $ lastLogins si
    let info = host cl `Prelude.lookup` newLogins
    if isJust info then
        mapM_ processAction [ModifyServerInfo (\s -> s{lastLogins = newLogins}), ByeClient (snd .  fromJust $ info)]
        else
        processAction $ ModifyServerInfo (\s -> s{lastLogins = (host cl, (addUTCTime 10 $ connectTime cl, "Reconnected too fast")) : newLogins})


processAction PingAll = do
    rnc <- gets roomsClients
    io (allClientsM rnc) >>= mapM_ (kickTimeouted rnc)
    cis <- io $ allClientsM rnc
    chans <- io $ mapM (client'sM rnc sendChan) cis
    io $ mapM_ (modifyClient rnc (\cl -> cl{pingsQueue = pingsQueue cl + 1})) cis
    processAction $ AnswerClients chans ["PING"]
    where
        kickTimeouted rnc ci = do
            pq <- io $ client'sM rnc pingsQueue ci
            when (pq > 0) $
                withStateT (\as -> as{clientIndex = Just ci}) $
                    processAction (ByeClient "Ping timeout")


processAction (StatsAction) = do
    rnc <- gets roomsClients
    si <- gets serverInfo
    (roomsNum, clientsNum) <- io $ withRoomsAndClients rnc stats
    io $ writeChan (dbQueries si) $ SendStats clientsNum (roomsNum - 1)
    where
          stats irnc = (length $ allRooms irnc, length $ allClients irnc)

