{-# LANGUAGE CPP, OverloadedStrings #-}
module Actions where

import Control.Concurrent
import qualified Data.Set as Set
import qualified Data.Sequence as Seq
import qualified Data.List as L
import qualified Control.Exception as Exception
import System.Log.Logger
import Control.Monad
import Data.Time
import Data.Maybe
import Control.Monad.Reader
import Control.Monad.State.Strict
import qualified Data.ByteString.Char8 as B
import Control.DeepSeq
import Data.Unique
import Control.Arrow
import Control.Exception
import System.Process
import Network.Socket
-----------------------------
import OfficialServer.GameReplayStore
import CoreTypes
import Utils
import ClientIO
import ServerState
import Consts
import ConfigFile
import EngineInteraction

data Action =
    AnswerClients ![ClientChan] ![B.ByteString]
    | SendServerMessage
    | SendServerVars
    | MoveToRoom RoomIndex
    | MoveToLobby B.ByteString
    | RemoveTeam B.ByteString
    | SendTeamRemovalMessage B.ByteString
    | RemoveRoom
    | FinishGame
    | UnreadyRoomClients
    | JoinLobby
    | ProtocolError B.ByteString
    | Warning B.ByteString
    | NoticeMessage Notice
    | ByeClient B.ByteString
    | KickClient ClientIndex
    | KickRoomClient ClientIndex
    | BanClient NominalDiffTime B.ByteString ClientIndex
    | BanIP B.ByteString NominalDiffTime B.ByteString
    | BanList
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
    | RestartServer
    | AddNick2Bans B.ByteString B.ByteString UTCTime
    | AddIP2Bans B.ByteString B.ByteString UTCTime
    | CheckBanned
    | SaveReplay


type CmdHandler = [B.ByteString] -> Reader (ClientIndex, IRnC) [Action]

instance NFData Action where
    rnf (AnswerClients chans msg) = chans `deepseq` msg `deepseq` ()
    rnf a = a `seq` ()

instance NFData B.ByteString
instance NFData (Chan a)


othersChans :: StateT ServerState IO [ClientChan]
othersChans = do
    cl <- client's id
    ri <- clientRoomA
    liftM (map sendChan . filter (/= cl)) $ roomClientsS ri

processAction :: Action -> StateT ServerState IO ()


processAction (AnswerClients chans msg) =
    io $ mapM_ (`writeChan` (msg `deepseq` msg)) (chans `deepseq` chans)


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
            "LATEST_PROTO", showB $ latestReleaseVersion si
            ]


processAction (ProtocolError msg) = do
    chan <- client's sendChan
    processAction $ AnswerClients [chan] ["ERROR", msg]


processAction (Warning msg) = do
    chan <- client's sendChan
    processAction $ AnswerClients [chan] ["WARNING", msg]

processAction (NoticeMessage n) = do
    chan <- client's sendChan
    processAction $ AnswerClients [chan] ["NOTICE", showB . fromEnum $ n]

processAction (ByeClient msg) = do
    (Just ci) <- gets clientIndex
    ri <- clientRoomA

    chan <- client's sendChan
    clNick <- client's nick
    loggedIn <- client's logonPassed

    when (ri /= lobbyId) $ do
        processAction $ MoveToLobby ("quit: " `B.append` msg)
        return ()

    clientsChans <- liftM (Prelude.map sendChan . Prelude.filter logonPassed) $! allClientsS
    io $
        infoM "Clients" (show ci ++ " quits: " ++ B.unpack msg)

    processAction $ AnswerClients [chan] ["BYE", msg]
    when loggedIn $ processAction $ AnswerClients clientsChans ["LOBBY:LEFT", clNick, msg]

    s <- get
    put $! s{removedClients = ci `Set.insert` removedClients s}

processAction (DeleteClient ci) = do
    io $ debugM "Clients"  $ "DeleteClient: " ++ show ci

    rnc <- gets roomsClients
    io $ removeClient rnc ci

    s <- get
    put $! s{removedClients = ci `Set.delete` removedClients s}
    
    sp <- gets (shutdownPending . serverInfo)
    cls <- allClientsS
    io $ when (sp && null cls) $ throwIO ShutdownException

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


processAction (ModifyServerInfo f) = do
    modify (\s -> s{serverInfo = f $ serverInfo s})
    si <- gets serverInfo
    io $ writeServerConfig si


processAction (MoveToRoom ri) = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients

    io $ do
        modifyClient rnc (\cl -> cl{teamsInGame = 0, isReady = False, isMaster = False}) ci
        modifyRoom rnc (\r -> r{playersIn = playersIn r + 1}) ri
        moveClientToRoom rnc ri ci

    chans <- liftM (map sendChan) $ roomClientsS ri
    clNick <- client's nick

    processAction $ AnswerClients chans ["JOINED", clNick]


processAction (MoveToLobby msg) = do
    (Just ci) <- gets clientIndex
    ri <- clientRoomA
    rnc <- gets roomsClients
    (gameProgress, playersNum) <- io $ room'sM rnc ((isJust . gameInfo) &&& playersIn) ri
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

    -- when not removing room
    when (not master || (gameProgress && playersNum > 1)) . io $ do
        modifyRoom rnc (\r -> r{
                playersIn = playersIn r - 1,
                readyPlayers = if ready then readyPlayers r - 1 else readyPlayers r
                }) ri
        moveClientToLobby rnc ci

processAction ChangeMaster = do
    (Just ci) <- gets clientIndex
    ri <- clientRoomA
    rnc <- gets roomsClients
    newMasterId <- liftM (head . filter (/= ci)) . io $ roomClientsIndicesM rnc ri
    newMaster <- io $ client'sM rnc id newMasterId
    oldRoomName <- io $ room'sM rnc name ri
    let newRoomName = nick newMaster
    mapM_ processAction [
        ModifyRoom (\r -> r{masterID = newMasterId, name = newRoomName}),
        ModifyClient2 newMasterId (\c -> c{isMaster = True}),
        AnswerClients [sendChan newMaster] ["ROOM_CONTROL_ACCESS", "1"]
        ]

    proto <- client's clientProto
    newRoom <- io $ room'sM rnc id ri
    chans <- liftM (map sendChan) $! sameProtoClientsS proto
    processAction $ AnswerClients chans ("ROOM" : "UPD" : oldRoomName : roomInfo (nick newMaster) newRoom)

    
processAction (AddRoom roomName roomPassword) = do
    Just clId <- gets clientIndex
    rnc <- gets roomsClients
    proto <- client's clientProto
    n <- client's nick

    let rm = newRoom{
            masterID = clId,
            name = roomName,
            password = roomPassword,
            roomProto = proto
            }

    rId <- io $ addRoom rnc rm

    processAction $ MoveToRoom rId

    chans <- liftM (map sendChan) $! sameProtoClientsS proto

    mapM_ processAction [
        AnswerClients chans ("ROOM" : "ADD" : roomInfo n rm)
        , ModifyClient (\cl -> cl{isMaster = True})
        ]


processAction RemoveRoom = do
    Just clId <- gets clientIndex
    rnc <- gets roomsClients
    ri <- io $ clientRoomM rnc clId
    roomName <- io $ room'sM rnc name ri
    others <- othersChans
    proto <- client's clientProto
    chans <- liftM (map sendChan) $! sameProtoClientsS proto

    mapM_ processAction [
            AnswerClients chans ["ROOM", "DEL", roomName],
            AnswerClients others ["ROOMABANDONED", roomName]
        ]

    io $ removeRoom rnc ri


processAction UnreadyRoomClients = do
    rnc <- gets roomsClients
    ri <- clientRoomA
    roomPlayers <- roomClientsS ri
    roomClIDs <- io $ roomClientsIndicesM rnc ri
    pr <- client's clientProto
    processAction $ AnswerClients (map sendChan roomPlayers) $ notReadyMessage pr (map nick roomPlayers)
    io $ mapM_ (modifyClient rnc (\cl -> cl{isReady = False})) roomClIDs
    processAction $ ModifyRoom (\r -> r{readyPlayers = 0})
    where
        notReadyMessage p nicks = if p < 38 then "NOT_READY" : nicks else "CLIENT_FLAGS" : "-r" : nicks

        
processAction FinishGame = do
    rnc <- gets roomsClients
    ri <- clientRoomA
    thisRoomChans <- liftM (map sendChan) $ roomClientsS ri
    clNick <- client's nick
    answerRemovedTeams <- io $ 
         room'sM rnc (map (\t -> AnswerClients thisRoomChans ["REMOVE_TEAM", t]) . leftTeams . fromJust . gameInfo) ri
         
    mapM_ processAction $ 
        SaveReplay
        : ModifyRoom
            (\r -> r{
                gameInfo = Nothing,
                readyPlayers = 0
                }
            )
        : UnreadyRoomClients
        : answerRemovedTeams

        
processAction (SendTeamRemovalMessage teamName) = do
    chans <- othersChans
    mapM_ processAction [
        AnswerClients chans ["EM", rmTeamMsg],
        ModifyRoom (\r -> r{
                gameInfo = liftM (\g -> g{
                    teamsInGameNumber = teamsInGameNumber g - 1
                    , roundMsgs = roundMsgs g Seq.|> rmTeamMsg
                }) $ gameInfo r
            })
        ]
        
    rnc <- gets roomsClients
    ri <- clientRoomA
    gi <- io $ room'sM rnc gameInfo ri
    when (isJust gi && 0 == teamsInGameNumber (fromJust gi)) $
        processAction FinishGame        
    where
        rmTeamMsg = toEngineMsg $ 'F' `B.cons` teamName
    
    
processAction (RemoveTeam teamName) = do
    rnc <- gets roomsClients
    ri <- clientRoomA
    inGame <- io $ room'sM rnc (isJust . gameInfo) ri
    chans <- othersChans
    mapM_ processAction $ 
        ModifyRoom (\r -> r{
            teams = Prelude.filter (\t -> teamName /= teamname t) $ teams r
            , gameInfo = liftM (\g -> g{leftTeams = teamName : leftTeams g}) $ gameInfo r
            })
        : AnswerClients chans ["REMOVE_TEAM", teamName]
        : [SendTeamRemovalMessage teamName | inGame]


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
    p <- client's clientProto
    uid <- client's clUID
    haveSameNick <- liftM (not . null . tail . filter (\c -> caseInsensitiveCompare (nick c) n)) allClientsS
    if haveSameNick then
        if p < 38 then
            mapM_ processAction [ByeClient "Nickname is already in use", removeNick]
            else
            mapM_ processAction [NoticeMessage NickAlreadyInUse, removeNick]
        else
        do
        db <- gets (dbQueries . serverInfo)
        io $ writeChan db $ CheckAccount ci (hashUnique uid) n h
        return ()
   where
       removeNick = ModifyClient (\c -> c{nick = ""})


processAction ClearAccountsCache = do
    dbq <- gets (dbQueries . serverInfo)
    io $ writeChan dbq ClearCache
    return ()


processAction (ProcessAccountInfo info) =
    case info of
        HasAccount passwd isAdmin -> do
            chan <- client's sendChan
            mapM_ processAction [AnswerClients [chan] ["ASKPASSWORD"], ModifyClient (\c -> c{webPassword = passwd, isAdministrator = isAdmin})]
        Guest ->
            processAction JoinLobby
        Admin -> do
            mapM_ processAction [ModifyClient (\cl -> cl{isAdministrator = True}), JoinLobby]
            chan <- client's sendChan
            processAction $ AnswerClients [chan] ["ADMIN_ACCESS"]


processAction JoinLobby = do
    chan <- client's sendChan
    clientNick <- client's nick
    (lobbyNicks, clientsChans) <- liftM (unzip . Prelude.map (nick &&& sendChan) . Prelude.filter logonPassed) $! allClientsS
    mapM_ processAction $
        AnswerClients clientsChans ["LOBBY:JOINED", clientNick]
        : AnswerClients [chan] ("LOBBY:JOINED" : clientNick : lobbyNicks)
        : [ModifyClient (\cl -> cl{logonPassed = True}), SendServerMessage]


processAction (KickClient kickId) = do
    modify (\s -> s{clientIndex = Just kickId})
    clHost <- client's host
    currentTime <- io getCurrentTime
    mapM_ processAction [
        AddIP2Bans clHost "60 seconds cooldown after kick" (addUTCTime 60 currentTime),
        ByeClient "Kicked"
        ]


processAction (BanClient seconds reason banId) = do
    modify (\s -> s{clientIndex = Just banId})
    clHost <- client's host
    currentTime <- io getCurrentTime
    let msg = B.concat ["Ban for ", B.pack . show $ seconds, " (", reason, ")"]
    mapM_ processAction [
        AddIP2Bans clHost msg (addUTCTime seconds currentTime)
        , KickClient banId
        ]

processAction (BanIP ip seconds reason) = do
    currentTime <- io getCurrentTime
    let msg = B.concat ["Ban for ", B.pack . show $ seconds, " (", reason, ")"]
    processAction $
        AddIP2Bans ip msg (addUTCTime seconds currentTime)

processAction BanList = do
    ch <- client's sendChan
    bans <- gets (bans . serverInfo)
    processAction $
        AnswerClients [ch] ["BANLIST", B.pack $ show bans]
    


processAction (KickRoomClient kickId) = do
    modify (\s -> s{clientIndex = Just kickId})
    ch <- client's sendChan
    mapM_ processAction [AnswerClients [ch] ["KICKED"], MoveToLobby "kicked"]


processAction (AddClient cl) = do
    rnc <- gets roomsClients
    si <- gets serverInfo
    newClId <- io $ do
        ci <- addClient rnc cl
        _ <- Exception.mask (forkIO . clientRecvLoop (clientSocket cl) (coreChan si) (sendChan cl) ci)

        infoM "Clients" (show ci ++ ": New client. Time: " ++ show (connectTime cl))

        return ci

    modify (\s -> s{clientIndex = Just newClId})
    mapM_ processAction
        [
            AnswerClients [sendChan cl] ["CONNECTED", "Hedgewars server http://www.hedgewars.org/", serverVersion]
            , CheckBanned
            , AddIP2Bans (host cl) "Reconnected too fast" (addUTCTime 10 $ connectTime cl)
        ]


processAction (AddNick2Bans n reason expiring) = do
    processAction $ ModifyServerInfo (\s -> s{bans = BanByNick n reason expiring : bans s})

processAction (AddIP2Bans ip reason expiring) = do
    (Just ci) <- gets clientIndex
    rc <- gets removedClients
    when (not $ ci `Set.member` rc)
        $ processAction $ ModifyServerInfo (\s -> s{bans = BanByIP ip reason expiring : bans s})

processAction CheckBanned = do
    clTime <- client's connectTime
    clNick <- client's nick
    clHost <- client's host
    si <- gets serverInfo
    let validBans = filter (checkNotExpired clTime) $ bans si
    let ban = L.find (checkBan clHost clNick) $ validBans
    mapM_ processAction $
        ModifyServerInfo (\s -> s{bans = validBans})
        : [ByeClient (getBanReason $ fromJust ban) | isJust ban]
    where
        checkNotExpired testTime (BanByIP _ _ time) = testTime `diffUTCTime` time <= 0
        checkNotExpired testTime (BanByNick _ _ time) = testTime `diffUTCTime` time <= 0
        checkBan ip _ (BanByIP bip _ _) = bip `B.isPrefixOf` ip
        checkBan _ n (BanByNick bn _ _) = bn == n
        getBanReason (BanByIP _ msg _) = msg
        getBanReason (BanByNick _ msg _) = msg

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


processAction StatsAction = do
    si <- gets serverInfo
    when (not $ shutdownPending si) $ do
        rnc <- gets roomsClients
        (roomsNum, clientsNum) <- io $ withRoomsAndClients rnc st
        io $ writeChan (dbQueries si) $ SendStats clientsNum (roomsNum - 1)
    where
          st irnc = (length $ allRooms irnc, length $ allClients irnc)

processAction RestartServer = do 
    sp <- gets (shutdownPending . serverInfo)
    when (not sp) $ do
        sock <- gets (fromJust . serverSocket . serverInfo)
        args <- gets (runArgs . serverInfo)
        io $ do
            noticeM "Core" "Closing listening socket"
            sClose sock
            noticeM "Core" "Spawning new server"
            _ <- createProcess (proc "./hedgewars-server" args)
            return ()
        processAction $ ModifyServerInfo (\s -> s{shutdownPending = True})

#if defined(OFFICIAL_SERVER)
processAction SaveReplay = do
    ri <- clientRoomA
    rnc <- gets roomsClients
    io $ do
        r <- room'sM rnc id ri
        saveReplay r
#else
processAction SaveReplay = return ()
#endif
