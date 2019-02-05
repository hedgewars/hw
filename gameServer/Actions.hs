{-
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 \-}

{-# LANGUAGE CPP, OverloadedStrings, ScopedTypeVariables #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
module Actions where

import Control.Concurrent
import qualified Data.Set as Set
import qualified Data.Map as Map
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
import Control.Exception as E
import System.Process
import Network.Socket
import System.Random
import qualified Data.Traversable as DT
import Text.Regex.TDFA
import qualified Text.Regex.TDFA as TDFA
import qualified Text.Regex.TDFA.ByteString as TDFAB
-----------------------------
#if defined(OFFICIAL_SERVER)
import OfficialServer.GameReplayStore
import qualified Data.Yaml as YAML
#endif
import CoreTypes
import Utils
import ClientIO
import ServerState
import Consts
import ConfigFile
import EngineInteraction
import FloodDetection
import HWProtoCore
import Votes

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
    loggedIn <- client's isVisible

    when (ri /= lobbyId) $ do
        processAction $ (MoveToLobby msg)
        return ()

    clientsChans <- liftM (Prelude.map sendChan . Prelude.filter isVisible) $! allClientsS
    io $
        infoM "Clients" (show ci ++ " quits: " ++ B.unpack msg)

    when loggedIn $ processAction $ AnswerClients clientsChans ["LOBBY:LEFT", clNick, msg]

    mapM_ processAction
        [
        AnswerClients [chan] ["BYE", msg]
        , ModifyClient (\c -> c{nick = "", isVisible = False}) -- this will effectively hide client from others while he isn't deleted from list
        ]

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

processAction (ModifyRoomClients f) = do
    rnc <- gets roomsClients
    ri <- clientRoomA
    roomClIDs <- io $ roomClientsIndicesM rnc ri
    io $ mapM_ (modifyClient rnc f) roomClIDs


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
        modifyClient rnc (
            \cl -> cl{teamsInGame = 0
                , isReady = False
                , isMaster = False
                , isInGame = False
                , isJoinedMidGame = False
                , clientClan = Nothing}) ci
        modifyRoom rnc (\r -> r{playersIn = playersIn r + 1}) ri
        moveClientToRoom rnc ri ci

    chans <- liftM (map sendChan) $ roomClientsS ri
    clNick <- client's nick
    allClientsChans <- liftM (Prelude.map sendChan . Prelude.filter isVisible) $! allClientsS

    mapM_ processAction [
        AnswerClients chans ["JOINED", clNick]
        , AnswerClients allClientsChans ["CLIENT_FLAGS", "+i", clNick]
        , RegisterEvent RoomJoin
        ]


processAction (MoveToLobby msg) = do
    (Just ci) <- gets clientIndex
    ri <- clientRoomA
    rnc <- gets roomsClients
    playersNum <- io $ room'sM rnc playersIn ri
    specialRoom <- io $ room'sM rnc isSpecial ri
    master <- client's isMaster
--    client <- client's id
    clNick <- client's nick
    chans <- othersChans

    if master then
        if (playersNum > 1) || specialRoom then
            mapM_ processAction [ChangeMaster Nothing, NoticeMessage AdminLeft, RemoveClientTeams, AnswerClients chans ["LEFT", clNick, msg]]
            else
            processAction RemoveRoom
        else
        mapM_ processAction [RemoveClientTeams, AnswerClients chans ["LEFT", clNick, msg]]

    allClientsChans <- liftM (Prelude.map sendChan . Prelude.filter isVisible) $! allClientsS
    processAction $ AnswerClients allClientsChans ["CLIENT_FLAGS", "-i", clNick]

    -- when not removing room
    ready <- client's isReady
    when (not master || playersNum > 1 || specialRoom) . io $ do
        modifyRoom rnc (\r -> r{
                playersIn = playersIn r - 1,
                readyPlayers = if ready then readyPlayers r - 1 else readyPlayers r
                }) ri
        moveClientToLobby rnc ci


processAction (ChangeMaster delegateId)= do
    (Just ci) <- gets clientIndex
    proto <- client's clientProto
    ri <- clientRoomA
    rnc <- gets roomsClients
    specialRoom <- io $ room'sM rnc isSpecial ri
    newMasterId <- if specialRoom then 
        return delegateId
        else
        liftM (\ids -> fromMaybe (listToMaybe . reverse . filter (/= ci) $ ids) $ liftM Just delegateId) . io $ roomClientsIndicesM rnc ri
    newMaster <- io $ client'sM rnc id `DT.mapM` newMasterId
    oldMasterId <- io $ room'sM rnc masterID ri
    oldRoomName <- io $ room'sM rnc name ri
    kicked <- client's isKickedFromServer
    thisRoomChans <- liftM (map sendChan) $ roomClientsS ri
    let newRoomName = if ((proto < 42) || kicked) && (not specialRoom) then maybeNick newMaster else oldRoomName

    when (isJust oldMasterId) $ do
        oldMasterNick <- io $ client'sM rnc nick (fromJust oldMasterId)
        mapM_ processAction [
            ModifyClient2 (fromJust oldMasterId) (\c -> c{isMaster = False})
            , AnswerClients thisRoomChans ["CLIENT_FLAGS", "-h", oldMasterNick]
            ]

    when (isJust newMasterId) $
        mapM_ processAction [
          ModifyClient2 (fromJust newMasterId) (\c -> c{isMaster = True})
        , AnswerClients [sendChan $ fromJust newMaster] ["ROOM_CONTROL_ACCESS", "1"]
        , AnswerClients thisRoomChans ["CLIENT_FLAGS", "+h", nick $ fromJust newMaster]
        -- TODO: Send message to other clients, too (requires proper localization, however)
        , AnswerClients [sendChan $ fromJust newMaster] ["CHAT", nickServer, loc "You're the new room master!"]
        ]

    processAction $
        ModifyRoom (\r -> r{masterID = newMasterId
                , name = newRoomName
                , isRestrictedJoins = False
                , isRestrictedTeams = False
                , isRegisteredOnly = isSpecial r}
                )

    newRoom' <- io $ room'sM rnc id ri
    chans <- liftM (map sendChan) $! sameProtoClientsS proto
    processAction $ AnswerClients chans ("ROOM" : "UPD" : oldRoomName : roomInfo proto (maybeNick newMaster) newRoom')


processAction (AddRoom roomName roomPassword) = do
    Just clId <- gets clientIndex
    rnc <- gets roomsClients
    proto <- client's clientProto
    n <- client's nick

    let rm = newRoom{
            masterID = Just clId,
            name = roomName,
            password = roomPassword,
            roomProto = proto
            }

    rId <- io $ addRoom rnc rm

    processAction $ MoveToRoom rId

    chans <- liftM (map sendChan) $! sameProtoClientsS proto

    mapM_ processAction [
      AnswerClients chans ("ROOM" : "ADD" : roomInfo proto n rm{playersIn = 1})
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


processAction SendUpdateOnThisRoom = do
    Just clId <- gets clientIndex
    proto <- client's clientProto
    rnc <- gets roomsClients
    ri <- io $ clientRoomM rnc clId
    rm <- io $ room'sM rnc id ri
    masterCl <- io $ client'sM rnc id `DT.mapM` (masterID rm)
    chans <- liftM (map sendChan) $! sameProtoClientsS proto
    processAction $ AnswerClients chans ("ROOM" : "UPD" : name rm : roomInfo proto (maybeNick masterCl) rm)


processAction UnreadyRoomClients = do
    ri <- clientRoomA
    roomPlayers <- roomClientsS ri
    pr <- client's clientProto
    mapM_ processAction [
        AnswerClients (map sendChan roomPlayers) $ notReadyMessage pr . map nick . filter (not . isMaster) $ roomPlayers
        , ModifyRoomClients (\cl -> cl{isReady = isMaster cl, isJoinedMidGame = False})
        , ModifyRoom (\r -> r{readyPlayers = 1})
        ]
    where
        notReadyMessage p nicks = if p < 38 then "NOT_READY" : nicks else "CLIENT_FLAGS" : "-r" : nicks


processAction FinishGame = do
    rnc <- gets roomsClients
    ri <- clientRoomA
    thisRoomChans <- liftM (map sendChan) $ roomClientsS ri
    joinedMidGame <- liftM (filter isJoinedMidGame) $ roomClientsS ri
    answerRemovedTeams <- io $
         room'sM rnc (\r -> let gi = fromJust $ gameInfo r in
                        concatMap (\c ->
                            (answerFullConfigParams c (mapParams r) (params r))
                            ++
                            (map (\t -> AnswerClients [sendChan c] ["REMOVE_TEAM", t]) $ leftTeams gi)
                        ) joinedMidGame
                     ) ri

    rteams <- io $ room'sM rnc (L.nub . rejoinedTeams . fromJust . gameInfo) ri
    mapM_ (processAction . RemoveTeam) rteams

    mapM_ processAction $ (
        SaveReplay
        : ModifyRoom
            (\r -> r{
                gameInfo = Nothing,
                readyPlayers = 0
                }
            )
        : SendUpdateOnThisRoom
        : AnswerClients thisRoomChans ["ROUND_FINISHED"]
        : answerRemovedTeams
        )
        ++ [UnreadyRoomClients]


processAction (SendTeamRemovalMessage teamName) = do
    chans <- othersChans
    mapM_ processAction [
        AnswerClients chans ["EM", rmTeamMsg],
        ModifyRoom (\r -> r{
                gameInfo = liftM (\g -> g{
                    teamsInGameNumber = teamsInGameNumber g - 1
                    , lastFilteredTimedMsg = Nothing
                    , roundMsgs = (if isJust $ lastFilteredTimedMsg g then ((:) rmTeamMsg . (:) (fromJust $ lastFilteredTimedMsg g)) else ((:) rmTeamMsg)) 
                        $ roundMsgs g
                }) $ gameInfo r
            })
        ]

    rnc <- gets roomsClients
    ri <- clientRoomA
    gi <- io $ room'sM rnc gameInfo ri
    when (0 == teamsInGameNumber (fromJust gi)) $
        processAction FinishGame
    where
        rmTeamMsg = toEngineMsg $ 'F' `B.cons` teamName


processAction (RemoveTeam teamName) = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients
    ri <- clientRoomA
    inGame <- io $ do
        r <- room'sM rnc (isJust . gameInfo) ri
        c <- client'sM rnc isInGame ci
        return $ r && c
    chans <- othersChans
    mapM_ processAction $
        ModifyRoom (\r -> r{
            teams = Prelude.filter (\t -> teamName /= teamname t) $ teams r
            , gameInfo = liftM (\g -> g{leftTeams = teamName : leftTeams g}) $ gameInfo r
            })
        : SendUpdateOnThisRoom
        : AnswerClients chans ["REMOVE_TEAM", teamName]
        : [SendTeamRemovalMessage teamName | inGame]


processAction RemoveClientTeams = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients
    n <- client's nick

    removeTeamActions <- io $ do
        rId <- clientRoomM rnc ci
        roomTeams <- room'sM rnc teams rId
        return . Prelude.map (RemoveTeam . teamname) . Prelude.filter (\t -> teamowner t == n) $ roomTeams

    mapM_ processAction removeTeamActions


processAction SetRandomSeed = do
    ri <- clientRoomA
    thisRoomChans <- liftM (map sendChan) $ roomClientsS ri
    seed <- liftM showB $ io $ (randomRIO (0, 10^9) :: IO Int)
    mapM_ processAction [
        ModifyRoom (\r -> r{mapParams = Map.insert "SEED" seed $ mapParams r})
        , AnswerClients thisRoomChans ["CFG", "SEED", seed]
        ]


processAction CheckRegistered = do
    (Just ci) <- gets clientIndex
    n <- client's nick
    h <- client's host
    p <- client's clientProto
    checker <- client's isChecker
    uid <- client's clUID
    -- allow multiple checker logins
    haveSameNick <- liftM (not . null . tail . filter (\c -> (not $ isChecker c) && caseInsensitiveCompare (nick c) n)) allClientsS
    if (not checker) && haveSameNick then
        if p < 38 then
            processAction $ ByeClient $ loc "Nickname is already in use"
            else
            mapM_ processAction [NoticeMessage NickAlreadyInUse, ModifyClient $ \c -> c{nick = B.empty}]
        else
        do
        db <- gets (dbQueries . serverInfo)
        io $ writeChan db $ CheckAccount ci (hashUnique uid) n h
        return ()

processAction ClearAccountsCache = do
    dbq <- gets (dbQueries . serverInfo)
    io $ writeChan dbq ClearCache
    return ()


processAction (ProcessAccountInfo info) = do
    si <- gets serverInfo
    case info of
        HasAccount passwd isAdmin isContr -> do
            b <- isBanned
            c <- client's isChecker
            when (not b) $ (if c then checkerLogin else playerLogin) passwd isAdmin isContr
        Guest | isRegisteredUsersOnly si -> do
            processAction $ ByeClient $ loc "This server only allows registered users to join."
            | otherwise -> do
            b <- isBanned
            c <- client's isChecker
            when (not b) $
                if c then
                    checkerLogin "" False False
                    else
                    processAction JoinLobby
        Admin ->
            mapM_ processAction [ModifyClient (\cl -> cl{isAdministrator = True}), JoinLobby]
        ReplayName fn -> processAction $ ShowReplay fn
    where
    isBanned = do
        processAction $ CheckBanned False
        liftM B.null $ client's nick
    checkerLogin _ False _ = processAction $ ByeClient $ loc "No checker rights"
    checkerLogin p True _ = do
        wp <- client's webPassword
        chan <- client's sendChan
        mapM_ processAction $
            if wp == p then
                [ModifyClient $ \c -> c{logonPassed = True}
                , AnswerClients [chan] ["LOGONPASSED"]
                ]
                else
                [ByeClient $ loc "Authentication failed"]
    playerLogin p a contr = do
        cl <- client's id
        mapM_ processAction [
            AnswerClients [sendChan cl] $ ("ASKPASSWORD") : if clientProto cl < 48 then [] else [serverSalt cl]
            , ModifyClient (\c -> c{webPassword = p, isAdministrator = a, isContributor = contr})
            ]

processAction JoinLobby = do
    chan <- client's sendChan
    rnc <- gets roomsClients
    clientNick <- client's nick
    clProto <- client's clientProto
    isAuthenticated <- client's isRegistered
    isAdmin <- client's isAdministrator
    isContr <- client's isContributor
    loggedInClients <- liftM (Prelude.filter isVisible) $! allClientsS
    let (lobbyNicks, clientsChans) = unzip . L.map (nick &&& sendChan) $ loggedInClients
    let authenticatedNicks = L.map nick . L.filter isRegistered $ loggedInClients
    let adminsNicks = L.map nick . L.filter isAdministrator $ loggedInClients
    let contrNicks = L.map nick . L.filter isContributor $ loggedInClients
    inRoomNicks <- io $
        allClientsM rnc
        >>= filterM (liftM ((/=) lobbyId) . clientRoomM rnc)
        >>= mapM (client'sM rnc nick)
    let clFlags = B.concat . L.concat $ [["u" | isAuthenticated], ["a" | isAdmin], ["c" | isContr]]

    roomsInfoList <- io $ do
        rooms <- roomsM rnc
        mapM (\r -> (mapM (client'sM rnc id) $ masterID r)
            >>= \cn -> return $ roomInfo clProto (maybeNick cn) r)
            $ filter (\r -> (roomProto r == clProto)) rooms

    mapM_ processAction . concat $ [
        [AnswerClients clientsChans ["LOBBY:JOINED", clientNick]]
        , [AnswerClients [chan] ("LOBBY:JOINED" : clientNick : lobbyNicks)]
        , [AnswerClients [chan] ("CLIENT_FLAGS" : "+u" : authenticatedNicks) | not $ null authenticatedNicks]
        , [AnswerClients [chan] ("CLIENT_FLAGS" : "+a" : adminsNicks) | not $ null adminsNicks]
        , [AnswerClients [chan] ("CLIENT_FLAGS" : "+c" : contrNicks) | not $ null contrNicks]
        , [AnswerClients [chan] ("CLIENT_FLAGS" : "+i" : inRoomNicks) | not $ null inRoomNicks]
        , [AnswerClients (chan : clientsChans) ["CLIENT_FLAGS",  B.concat["+" , clFlags], clientNick] | not $ B.null clFlags]
        , [ModifyClient (\cl -> cl{logonPassed = True, isVisible = True})]
        , [SendServerMessage]
        , [AnswerClients [chan] ("ROOMS" : concat roomsInfoList)]
        ]


processAction (KickClient kickId) = do
    modify (\s -> s{clientIndex = Just kickId})
    clHost <- client's host
    currentTime <- io getCurrentTime
    mapM_ processAction [
        AddIP2Bans clHost (loc "60 seconds cooldown after kick") (addUTCTime 60 currentTime)
        , ModifyClient (\c -> c{isKickedFromServer = True})
        , ByeClient $ loc "Kicked"
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


processAction (BanNick n seconds reason) = do
    currentTime <- io getCurrentTime
    let msg =
            if seconds > 60 * 60 * 24 * 365 then
                B.concat ["Permanent ban (", reason, ")"]
                else
                B.concat ["Ban for ", B.pack . show $ seconds, " (", reason, ")"]
    processAction $
        AddNick2Bans n msg (addUTCTime seconds currentTime)


processAction BanList = do
    time <- io $ getCurrentTime
    ch <- client's sendChan
    b <- gets (B.intercalate "\n" . concatMap (ban2Str time) . bans . serverInfo)
    processAction $
        AnswerClients [ch] ["BANLIST", b]
    where
        ban2Str time (BanByIP b r t) = ["I", b, r, B.pack . show $ t `diffUTCTime` time]
        ban2Str time (BanByNick b r t) = ["N", b, r, B.pack . show $ t `diffUTCTime` time]


processAction (Unban entry) = do
    processAction $ ModifyServerInfo (\s -> s{bans = filter (not . f) $ bans s})
    where
        f (BanByIP bip _ _) = bip == entry
        f (BanByNick bn _ _) = bn == entry


processAction (KickRoomClient kickId) = do
    modify (\s -> s{clientIndex = Just kickId})
    ch <- client's sendChan
    mapM_ processAction [AnswerClients [ch] ["KICKED"], MoveToLobby $ loc "kicked"]


processAction (AddClient cl) = do
    rnc <- gets roomsClients
    si <- gets serverInfo
    newClId <- io $ do
        ci <- addClient rnc cl
        _ <- Exception.mask (\x -> forkIO $ clientRecvLoop (clientSocket cl) (coreChan si) (sendChan cl) ci x)

        infoM "Clients" (show ci ++ ": New client. Time: " ++ show (connectTime cl))

        return ci

    modify (\s -> s{clientIndex = Just newClId})

    jm <- gets joinsMonitor
    pass <- io $ joinsSentry jm (host cl) (connectTime cl)

    if pass then
        mapM_ processAction
            [
                CheckBanned True
                , AnswerClients [sendChan cl] ["CONNECTED", "Hedgewars server https://www.hedgewars.org/", serverVersion]
            ]
        else
        processAction $ ByeClient $ loc "Reconnected too fast"

processAction (AddNick2Bans n reason expiring) = do
    processAction $ ModifyServerInfo (\s -> s{bans = BanByNick n reason expiring : bans s})

processAction (AddIP2Bans ip reason expiring) = do
    (Just ci) <- gets clientIndex
    rc <- gets removedClients
    when (not $ ci `Set.member` rc)
        $ processAction $ ModifyServerInfo (\s -> s{bans = BanByIP ip reason expiring : bans s})


processAction (CheckBanned byIP) = do
    clTime <- client's connectTime
    clNick <- client's nick
    clHost <- client's host
    si <- gets serverInfo
    let (validBans, expiredBans) = L.partition (checkNotExpired clTime) $ bans si
    let ban = L.find (checkBan byIP clHost clNick) $ validBans
    mapM_ processAction $
        [ModifyServerInfo (\s -> s{bans = validBans}) | not $ null expiredBans]
        ++ [ByeClient (getBanReason $ fromJust ban) | isJust ban]
    where
        checkNotExpired testTime (BanByIP _ _ time) = testTime `diffUTCTime` time <= 0
        checkNotExpired testTime (BanByNick _ _ time) = testTime `diffUTCTime` time <= 0
        checkBan True ip _ (BanByIP bip _ _) = isMatch bip ip
        checkBan False _ n (BanByNick bn _ _) = isMatch bn n
        checkBan _ _ _ _ = False
        isMatch :: B.ByteString -> B.ByteString -> Bool
        isMatch rexp src = case B.uncons rexp of 
            Nothing -> False
            Just ('^', rexp') -> (==) (Just True) $ mrexp rexp' >>= flip matchM src
            Just _ -> rexp == src
        mrexp :: B.ByteString -> Maybe TDFAB.Regex
        mrexp = makeRegexOptsM TDFA.defaultCompOpt{TDFA.caseSensitive = False} TDFA.defaultExecOpt
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
            when (pq > 0) $ do
                withStateT (\as -> as{clientIndex = Just ci}) $
                    processAction (ByeClient $ loc "Ping timeout")
--                when (pq > 1) $
--                    processAction $ DeleteClient ci -- smth went wrong with client io threads, issue DeleteClient here


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


processAction Stats = do
    cls <- allClientsS
    rms <- allRoomsS
    let clientsMap = Map.fromListWith (+) . map (\c -> (clientProto c, 1 :: Int)) $ cls
    let roomsMap = Map.fromListWith (+) . map (\c -> (roomProto c, 1 :: Int)) . filter ((/=) 0 . roomProto) $ rms
    let keys = Map.keysSet clientsMap `Set.union` Map.keysSet roomsMap
    let versionsStats = B.concat . ((:) "<table border=1>") . (flip (++) ["</table>"])
            . concatMap (\p -> [
                    "<tr><td>", protoNumber2ver p
                    , "</td><td>", showB $ Map.findWithDefault 0 p clientsMap
                    , "</td><td>", showB $ Map.findWithDefault 0 p roomsMap
                    , "</td></tr>"])
            . Set.toList $ keys
    processAction $ Warning versionsStats


processAction (Random chans items) = do
    let i = if null items then [loc "heads", loc "tails"] else items
    n <- io $ randomRIO (0, length i - 1)
    processAction $ AnswerClients chans ["CHAT", if null items then nickRandomCoin else nickRandomCustom, i !! n]


processAction (LoadGhost location) = do
    ri <- clientRoomA
    rnc <- gets roomsClients
    thisRoomChans <- liftM (map sendChan) $ roomClientsS ri
#if defined(OFFICIAL_SERVER)
    rm <- io $ room'sM rnc id ri
    points <- io $ loadFile (B.unpack $ "ghosts/" `B.append` sanitizeName location)
    when (roomProto rm > 51) $ do
        processAction $ ModifyRoom $ \r -> r{params = Map.insert "DRAWNMAP" [prependGhostPoints (toP points) $ head $ (params r) Map.! "DRAWNMAP"] (params r)}
#endif
    cl <- client's id
    rm <- io $ room'sM rnc id ri
    mapM_ processAction $ map (replaceChans thisRoomChans) $ answerFullConfigParams cl (mapParams rm) (params rm)
    where
    loadFile :: String -> IO [Int]
    loadFile fileName = E.handle (\(e :: SomeException) -> return []) $ do
        points <- liftM read $ readFile fileName
        return (points `deepseq` points)
    replaceChans chans (AnswerClients _ msg) = AnswerClients chans msg
    replaceChans _ a = a
    toP [] = []
    toP (p1:p2:ps) = (fromIntegral p1, fromIntegral p2) : toP ps
{-
        let a = map (replaceChans chans) $ answerFullConfigParams cl mp p
-}
#if defined(OFFICIAL_SERVER)
processAction SaveReplay = do
    ri <- clientRoomA
    rnc <- gets roomsClients

    readyCheckersIds <- io $ do
        r <- room'sM rnc id ri
        saveReplay r
        allci <- allClientsM rnc
        filterM (client'sM rnc isReadyChecker) allci

    when (not $ null readyCheckersIds) $ do
        oldci <- gets clientIndex
        withStateT (\s -> s{clientIndex = Just $ head readyCheckersIds})
            $ processAction CheckRecord
        modify (\s -> s{clientIndex = oldci})
    where
        isReadyChecker cl = isChecker cl && isReady cl


processAction CheckRecord = do
    p <- client's clientProto
    c <- client's sendChan
    ri <- clientRoomA
    rnc <- gets roomsClients

    blackList <- liftM (map (recordFileName . fromJust . checkInfo) . filter (isJust . checkInfo)) allClientsS

    (cinfo, l) <- io $ loadReplay (fromIntegral p) blackList
    when (isJust cinfo) $
        mapM_ processAction [
            AnswerClients [c] ("REPLAY" : l)
            , ModifyClient $ \c -> c{checkInfo = cinfo, isReady = False}
            ]


processAction (CheckFailed msg) = do
    Just (CheckInfo fileName _ _) <- client's checkInfo
    io $ moveFailedRecord fileName


processAction (CheckSuccess info) = do
    Just (CheckInfo fileName teams gameDetails) <- client's checkInfo
    p <- client's clientProto
    si <- gets serverInfo
    when (isJust gameDetails)
        $ io $ writeChan (dbQueries si) $ StoreAchievements p (B.pack fileName) (map toPair teams) (fromJust gameDetails) info
    io $ moveCheckedRecord fileName
    where
        toPair t = (teamname t, teamowner t)

processAction (QueryReplay rname) = do
    (Just ci) <- gets clientIndex
    si <- gets serverInfo
    uid <- client's clUID
    io $ writeChan (dbQueries si) $ GetReplayName ci (hashUnique uid) rname

processAction (ShowReplay rname) = do
    c <- client's sendChan
    cl <- client's id

    let fileName = B.concat ["checked/", if B.isPrefixOf "replays/" rname then B.drop 8 rname else rname]

    cInfo <- liftIO $ E.handle (\(e :: SomeException) ->
                    warningM "REPLAYS" (B.unpack $ B.concat ["Problems reading ", fileName, ": ", B.pack $ show e]) >> return Nothing) $ do
            (t, p1, p2, msgs) <- liftM read $ readFile (B.unpack fileName)
            return $ Just (t, Map.fromList p1, Map.fromList p2, reverse msgs)

    let (teams', params1, params2, roundMsgs') = fromJust cInfo

    when (isJust cInfo) $ do
        mapM_ processAction $ concat [
            [AnswerClients [c] ["JOINED", nick cl]]
            , answerFullConfigParams cl params1 params2
            , answerAllTeams cl teams'
            , [AnswerClients [c]  ["RUN_GAME"]]
            , [AnswerClients [c] $ "EM" : roundMsgs']
            , [AnswerClients [c] ["KICKED"]]
            ]

processAction (SaveRoom rname) = do
    rnc <- gets roomsClients
    ri <- clientRoomA
    rm <- io $ room'sM rnc id ri
    liftIO $ YAML.encodeFile (B.unpack rname) (greeting rm, roomSaves rm)

processAction (LoadRoom rname) = do
    Right (g, rs) <- io $ YAML.decodeFileEither (B.unpack rname)
    processAction $ ModifyRoom $ \r -> r{greeting = g, roomSaves = rs}

#else
processAction SaveReplay = return ()
processAction CheckRecord = return ()
processAction (CheckFailed _) = return ()
processAction (CheckSuccess _) = return ()
processAction (QueryReplay _) = processAction $ Warning $ loc "This server does not support replays!"
processAction (ShowReplay rname) = return ()
processAction (SaveRoom rname) = return ()
processAction (LoadRoom rname) = return ()
#endif

processAction Cleanup = do
    jm <- gets joinsMonitor

    io $ do
        t <- getCurrentTime
        cleanup jm t


processAction (RegisterEvent e) = do
    actions <- registerEvent e
    mapM_ processAction actions


processAction (ReactCmd cmd) = do
    (Just ci) <- gets clientIndex
    rnc <- gets roomsClients
    actions <- liftIO $ withRoomsAndClients rnc (\irnc -> runReader (handleCmd cmd) (ci, irnc))
    forM_ (actions `deepseq` actions) processAction

processAction CheckVotes =
    checkVotes >>= mapM_ processAction

processAction (ShowRegisteredOnlyState chans) = do
    si <- gets serverInfo
    processAction $ AnswerClients chans
        ["CHAT", nickServer,
        if isRegisteredUsersOnly si then
            loc "This server no longer allows unregistered players to join."
        else
            loc "This server now allows unregistered players to join."
        ]
