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

{-# LANGUAGE OverloadedStrings #-}
module HWProtoInRoomState where

import qualified Data.Map as Map
import Data.List as L
import Data.Maybe
import qualified Data.ByteString.Char8 as B
import Control.Monad
import Control.Monad.Reader
--------------------------------------
import CoreTypes
import Consts
import Utils
import HandlerUtils
import RoomsAndClients
import EngineInteraction
import Votes
import CommandHelp

startGame :: Reader (ClientIndex, IRnC) [Action]
startGame = do
    (ci, rnc) <- ask
    cl <- thisClient
    rm <- thisRoom
    chans <- roomClientsChans

    let nicks = map (nick . client rnc) . roomClients rnc $ clientRoom rnc ci
    let allPlayersRegistered = all isOwnerRegistered $ teams rm

    if (playersIn rm == readyPlayers rm || clientProto cl > 43) && not (isJust $ gameInfo rm) then
        if enoughClans rm then
            return [
                ModifyRoom
                    (\r -> r{
                        gameInfo = Just $ newGameInfo (teams rm) (length $ teams rm) allPlayersRegistered (mapParams rm) (params rm) False
                        }
                    )
                , AnswerClients chans ["RUN_GAME"]
                , SendUpdateOnThisRoom
                , AnswerClients chans $ "CLIENT_FLAGS" : "+g" : nicks
                , ModifyRoomClients (\c -> c{isInGame = True, teamIndexes = map snd . filter (\(t, _) -> teamowner t == nick c) $ zip (teams rm) [0..]})
                ]
            else
            return [Warning $ loc "The game can't be started with less than two clans!"]
        else
        return []
    where
        enoughClans = not . null . drop 1 . group . map teamcolor . teams



handleCmd_inRoom :: CmdHandler

handleCmd_inRoom ["CHAT", msg] = do
    n <- clientNick
    s <- roomOthersChans
    return [AnswerClients s ["CHAT", n, msg]]

-- Leave room normally
handleCmd_inRoom ["PART"] = return [MoveToLobby ""]
-- Leave room with custom quit message by player
-- "part: " is a special marker string to be detected by the frontend. Not translated for obvious reasons
handleCmd_inRoom ["PART", msg] = return [MoveToLobby $ "part: " `B.append` msg]


handleCmd_inRoom ("CFG" : paramName : paramStrs)
    | null paramStrs = return [ProtocolError $ loc "Empty config entry."]
    | otherwise = do
        chans <- roomOthersChans
        cl <- thisClient
        rm <- thisRoom

        if isSpecial rm then
            return [Warning $ loc "Access denied."]
        else if isMaster cl then
           return [
                ModifyRoom $ f (clientProto cl),
                AnswerClients chans ("CFG" : paramName : paramStrs)]
            else
            return [ProtocolError $ loc "You're not the room master!"]
    where
        f clproto r = if paramName `Map.member` (mapParams r) then
                r{mapParams = Map.insert paramName (head paramStrs) (mapParams r)}
                else
                r{params = Map.insert paramName (fixedParamStr clproto) (params r)}
        fixedParamStr clproto
            | clproto /= 49 = paramStrs
            | paramName /= "SCHEME" = paramStrs
            | otherwise = L.init paramStrs ++ [B.replicate 50 'X' `B.append` L.last paramStrs]


handleCmd_inRoom ("ADD_TEAM" : tName : color : grave : fort : voicepack : flag : difStr : hhsInfo)
    | length hhsInfo /= 16 = return [ProtocolError $ loc "Corrupted hedgehogs info!"]
    | otherwise = do
        rm <- thisRoom
        cl <- thisClient
        clNick <- clientNick
        clChan <- thisClientChans
        othChans <- roomOthersChans
        roomChans <- roomClientsChans
        teamColor <-
            if clientProto cl < 42 then
                return color
                else
                liftM (head . (L.\\) (map B.singleton ['0'..]) . map teamcolor . teams) thisRoom
        let roomTeams = teams rm
        let hhNum = newTeamHHNum roomTeams $
                if not $ null roomTeams then
                    minimum [hhnum $ head roomTeams, canAddNumber roomTeams]
                else
                    defaultHedgehogsNumber rm
        let newTeam = clNick `seq` TeamInfo clNick tName teamColor grave fort voicepack flag (isRegistered cl) dif hhNum (hhsList hhsInfo)
        return $
            if not . null . drop (teamsNumberLimit rm - 1) $ roomTeams then
                [Warning $ loc "Too many teams!"]
            else if canAddNumber roomTeams <= 0 then
                [Warning $ loc "Too many hedgehogs!"]
            else if isJust $ findTeam rm then
                [Warning $ loc "There's already a team with same name in the list."]
            else if isJust $ gameInfo rm then
                [Warning $ loc "Joining not possible: Round is in progress."]
            else if isRestrictedTeams rm then
                [Warning $ loc "This room currently does not allow adding new teams."]
            else
                [ModifyRoom (\r -> r{teams = teams r ++ [newTeam]}),
                SendUpdateOnThisRoom,
                ModifyClient (\c -> c{teamsInGame = teamsInGame c + 1, clientClan = Just teamColor}),
                AnswerClients clChan ["TEAM_ACCEPTED", tName],
                AnswerClients othChans $ teamToNet $ newTeam,
                AnswerClients roomChans ["TEAM_COLOR", tName, teamColor],
                AnswerClients roomChans ["HH_NUM", tName, showB $ hhnum newTeam]
                ]
        where
        canAddNumber rt = (cMaxHHs) - (sum $ map hhnum rt)
        findTeam = find (\t -> tName == teamname t) . teams
        dif = readInt_ difStr
        hhsList [] = []
        hhsList [_] = error "Hedgehogs list with odd elements number"
        hhsList (n:h:hhs) = HedgehogInfo n h : hhsList hhs
        newTeamHHNum rt p = min p (canAddNumber rt)
        maxTeams r
            | roomProto r < 38 = 6
            | otherwise = cMaxTeams


handleCmd_inRoom ["REMOVE_TEAM", tName] = do
        (ci, _) <- ask
        r <- thisRoom
        clNick <- clientNick

        let maybeTeam = findTeam r
        let team = fromJust maybeTeam

        return $
            if isNothing $ maybeTeam then
                [Warning $ loc "Error: The team you tried to remove does not exist."]
            else if clNick /= teamowner team then
                [ProtocolError $ loc "You can't remove a team you don't own."]
            else
                [RemoveTeam tName,
                ModifyClient
                    (\c -> c{
                        teamsInGame = teamsInGame c - 1,
                        clientClan = if teamsInGame c == 1 then Nothing else anotherTeamClan clNick team r
                    })
                ]
    where
        anotherTeamClan clNick team = liftM teamcolor . find (\t -> (teamowner t == clNick) && (t /= team)) . teams
        findTeam = find (\t -> tName == teamname t) . teams


handleCmd_inRoom ["HH_NUM", teamName, numberStr] = do
    cl <- thisClient
    r <- thisRoom
    clChan <- thisClientChans
    others <- roomOthersChans

    let maybeTeam = findTeam r
    let team = fromJust maybeTeam

    return $
        if not $ isMaster cl then
            [ProtocolError $ loc "You're not the room master!"]
        else if isNothing maybeTeam then
            []
        else if hhNumber < 1 || hhNumber > cHogsPerTeam || hhNumber > canAddNumber r + hhnum team then
            [AnswerClients clChan ["HH_NUM", teamName, showB $ hhnum team]]
        else
            [ModifyRoom $ modifyTeam team{hhnum = hhNumber},
            AnswerClients others ["HH_NUM", teamName, showB hhNumber]]
    where
        hhNumber = readInt_ numberStr
        findTeam = find (\t -> teamName == teamname t) . teams
        canAddNumber = (-) cMaxHHs . sum . map hhnum . teams



handleCmd_inRoom ["TEAM_COLOR", teamName, newColor] = do
    cl <- thisClient
    others <- roomOthersChans
    r <- thisRoom

    let maybeTeam = findTeam r
    let team = fromJust maybeTeam
    maybeClientId <- clientByNick $ teamowner team
    let teamOwnerId = fromJust maybeClientId

    return $
        if not $ isMaster cl then
            [ProtocolError $ loc "You're not the room master!"]
        else if isNothing maybeTeam || isNothing maybeClientId then
            []
        else
            [ModifyRoom $ modifyTeam team{teamcolor = newColor},
            AnswerClients others ["TEAM_COLOR", teamName, newColor],
            ModifyClient2 teamOwnerId (\c -> c{clientClan = Just newColor})]
    where
        findTeam = find (\t -> teamName == teamname t) . teams


handleCmd_inRoom ["TOGGLE_READY"] = do
    cl <- thisClient
    rm <- thisRoom
    chans <- roomClientsChans

    (ci, rnc) <- ask
    let ri = clientRoom rnc ci
    let unreadyClients = filter (not . isReady) . map (client rnc) $ roomClients rnc ri

    gs <- if (not $ isReady cl) && (isSpecial rm) && (unreadyClients == [cl]) then startGame else return []

    return $
        ModifyRoom (\r -> r{readyPlayers = readyPlayers r + (if isReady cl then -1 else 1)})
        : ModifyClient (\c -> c{isReady = not $ isReady cl})
        : (AnswerClients chans $ if clientProto cl < 38 then
                [if isReady cl then "NOT_READY" else "READY", nick cl]
                else
                ["CLIENT_FLAGS", if isReady cl then "-r" else "+r", nick cl])
        : gs


handleCmd_inRoom ["START_GAME"] = roomAdminOnly startGame

handleCmd_inRoom ["EM", msg] = do
    cl <- thisClient
    rm <- thisRoom
    chans <- roomOthersChans

    let (legalMsgs, nonEmptyMsgs, lastFTMsg) = checkNetCmd (teamIndexes cl) msg

    if teamsInGame cl > 0 && (isJust $ gameInfo rm) && (not $ B.null legalMsgs) then
        return $ AnswerClients chans ["EM", legalMsgs]
            : [ModifyRoom (\r -> r{gameInfo = liftM
                (\g -> g{
                    roundMsgs = if B.null nonEmptyMsgs then roundMsgs g else nonEmptyMsgs : roundMsgs g
                    , lastFilteredTimedMsg = fromMaybe (lastFilteredTimedMsg g) lastFTMsg})
                $ gameInfo r}), RegisterEvent EngineMessage]
        else
        return []


handleCmd_inRoom ["ROUNDFINISHED", _] = do
    cl <- thisClient
    rm <- thisRoom
    chans <- roomClientsChans

    let clTeams = map teamname . filter (\t -> teamowner t == nick cl) . teams $ rm
    let unsetInGameState = [AnswerClients chans ["CLIENT_FLAGS", "-g", nick cl], ModifyClient (\c -> c{isInGame = False})]

    if isInGame cl then
        if isJust $ gameInfo rm then
            return $ unsetInGameState ++ map SendTeamRemovalMessage clTeams
            else
            return unsetInGameState
        else
        return [] -- don't accept this message twice
    where
--        isCorrect = correctly == "1"

-- compatibility with clients with protocol < 38
handleCmd_inRoom ["ROUNDFINISHED"] =
    handleCmd_inRoom ["ROUNDFINISHED", "1"]

handleCmd_inRoom ["TOGGLE_RESTRICT_JOINS"] = roomAdminOnly $
    return [ModifyRoom (\r -> r{isRestrictedJoins = not $ isRestrictedJoins r}), SendUpdateOnThisRoom]


handleCmd_inRoom ["TOGGLE_RESTRICT_TEAMS"] = roomAdminOnly $
    return [ModifyRoom (\r -> r{isRestrictedTeams = not $ isRestrictedTeams r})]


handleCmd_inRoom ["TOGGLE_REGISTERED_ONLY"] = roomAdminOnly $
    return [ModifyRoom (\r -> r{isRegisteredOnly = not $ isRegisteredOnly r}), SendUpdateOnThisRoom]


handleCmd_inRoom ["ROOM_NAME", newName] = roomAdminOnly $ do
    cl <- thisClient
    rs <- allRoomInfos
    rm <- thisRoom
    chans <- sameProtoChans

    return $
        if illegalName newName then
            [Warning $ loc "Illegal room name! The room name must be between 1-40 characters long, must not have a trailing or leading space and must not have any of these characters: $()*+?[]^{|}"]
        else
        if isSpecial rm then
            [Warning $ loc "Access denied."]
        else
        if isJust $ find (\r -> newName == name r) rs then
            [Warning $ loc "A room with the same name already exists."]
        else
            [ModifyRoom roomUpdate,
            AnswerClients chans ("ROOM" : "UPD" : name rm : roomInfo (clientProto cl) (nick cl) (roomUpdate rm))]
    where
        roomUpdate r = r{name = newName}


handleCmd_inRoom ["KICK", kickNick] = roomAdminOnly $ do
    (thisClientId, rnc) <- ask
    maybeClientId <- clientByNick kickNick
    rm <- thisRoom
    let kickId = fromJust maybeClientId
    let kickCl = rnc `client` kickId
    let sameRoom = clientRoom rnc thisClientId == clientRoom rnc kickId
    let notOnly2Players = (length . group . sort . map teamowner . teams $ rm) > 2
    return
        [KickRoomClient kickId |
            isJust maybeClientId
            && (kickId /= thisClientId)
            && sameRoom
            && (not $ hasSuperPower kickCl)
            && ((isNothing $ gameInfo rm) || notOnly2Players || teamsInGame kickCl == 0)
        ]


handleCmd_inRoom ["DELEGATE", newAdmin] = do
    (thisClientId, rnc) <- ask
    maybeClientId <- clientByNick newAdmin
    master <- liftM isMaster thisClient
    serverAdmin <- liftM isAdministrator thisClient
    thisRoomMasterId <- liftM masterID thisRoom
    let newAdminId = fromJust maybeClientId
    let sameRoom = clientRoom rnc thisClientId == clientRoom rnc newAdminId
    return
        [ChangeMaster (Just newAdminId) |
            (master || serverAdmin)
                && isJust maybeClientId
                && (Just newAdminId /= thisRoomMasterId)
                && sameRoom]


handleCmd_inRoom ["TEAMCHAT", msg] = do
    cl <- thisClient
    chans <- roomSameClanChans
    return [AnswerClients chans ["EM", engineMsg cl]]
    where
        engineMsg cl = toEngineMsg $ B.concat ["b", nick cl, " (team): ", msg, "\x20\x20"]


handleCmd_inRoom ["BAN", banNick] = do
    (thisClientId, rnc) <- ask
    maybeClientId <- clientByNick banNick
    master <- liftM isMaster thisClient
    let banId = fromJust maybeClientId
    let sameRoom = clientRoom rnc thisClientId == clientRoom rnc banId
    if master && isJust maybeClientId && (banId /= thisClientId) && sameRoom then
        return [
--                ModifyRoom (\r -> r{roomBansList = let h = host $ rnc `client` banId in h `deepseq` h : roomBansList r})
                KickRoomClient banId
            ]
        else
        return []

handleCmd_inRoom ("RND":rs) = do
    n <- clientNick
    s <- roomClientsChans
    return [AnswerClients s ["CHAT", n, B.unwords $ "/rnd" : rs], Random s rs]


handleCmd_inRoom ["MAXTEAMS", n] = roomAdminOnly $ do
    cl <- thisClient
    let m = readInt_ n
    if m < 2 || m > cMaxTeams then
        return [AnswerClients [sendChan cl] ["CHAT", nickServer, loc "/maxteams: specify number from 2 to 8"]]
    else
        return [ModifyRoom (\r -> r{teamsNumberLimit = m})]

handleCmd_inRoom ["FIX"] = serverAdminOnly $
    return [ModifyRoom (\r -> r{isSpecial = True})]

handleCmd_inRoom ["UNFIX"] = serverAdminOnly $
    return [ModifyRoom (\r -> r{isSpecial = False})]

handleCmd_inRoom ["HELP"] = do
    cl <- thisClient
    if isAdministrator cl then
        return (cmdHelpActionList [sendChan cl] cmdHelpRoomAdmin)
    else
        return (cmdHelpActionList [sendChan cl] cmdHelpRoomPlayer)

handleCmd_inRoom ["GREETING", msg] = do
    cl <- thisClient
    rm <- thisRoom
    return [ModifyRoom (\r -> r{greeting = msg}) | isAdministrator cl || (isMaster cl && (not $ isSpecial rm))]


handleCmd_inRoom ["CALLVOTE"] = do
    cl <- thisClient
    return [AnswerClients [sendChan cl]
        ["CHAT", nickServer, loc "Available callvote commands: kick <nickname>, map <name>, pause, newseed, hedgehogs"]
        ]

handleCmd_inRoom ["CALLVOTE", "KICK"] = do
    cl <- thisClient
    return [AnswerClients [sendChan cl] ["CHAT", nickServer, loc "/callvote kick: You need to specify a nickname."]]

handleCmd_inRoom ["CALLVOTE", "KICK", nickname] = do
    (thisClientId, rnc) <- ask
    cl <- thisClient
    rm <- thisRoom
    maybeClientId <- clientByNick nickname
    let kickId = fromJust maybeClientId
    let sameRoom = clientRoom rnc thisClientId == clientRoom rnc kickId

    if isJust $ masterID rm then
        return []
        else
        if isJust maybeClientId && sameRoom then
            startVote $ VoteKick nickname
            else
            return [AnswerClients [sendChan cl] ["CHAT", nickServer, loc "/callvote kick: No such user!"]]


handleCmd_inRoom ["CALLVOTE", "MAP"] = do
    cl <- thisClient
    s <- liftM (Map.keys . roomSaves) thisRoom
    return [AnswerClients [sendChan cl] ["CHAT", nickServer, B.concat ["callvote map: ", B.intercalate ", " s]]]


handleCmd_inRoom ["CALLVOTE", "MAP", roomSave] = do
    cl <- thisClient
    rm <- thisRoom

    if Map.member roomSave $ roomSaves rm then
        startVote $ VoteMap roomSave
        else
        return [AnswerClients [sendChan cl] ["CHAT", nickServer, loc "/callvote map: No such map!"]]


handleCmd_inRoom ["CALLVOTE", "PAUSE"] = do
    cl <- thisClient
    rm <- thisRoom

    if isJust $ gameInfo rm then
        startVote VotePause
        else 
        return [AnswerClients [sendChan cl] ["CHAT", nickServer, loc "/callvote pause: No game in progress!"]]


handleCmd_inRoom ["CALLVOTE", "NEWSEED"] = do
    startVote VoteNewSeed


handleCmd_inRoom ["CALLVOTE", "HEDGEHOGS"] = do
    cl <- thisClient
    return [AnswerClients [sendChan cl] ["CHAT", nickServer, loc "/callvote hedgehogs: Specify number from 1 to 8."]]


handleCmd_inRoom ["CALLVOTE", "HEDGEHOGS", hhs] = do
    cl <- thisClient
    let h = readInt_ hhs

    if h > 0 && h <= cHogsPerTeam then
        startVote $ VoteHedgehogsPerTeam h
        else
        return [AnswerClients [sendChan cl] ["CHAT", nickServer, loc "/callvote hedgehogs: Specify number from 1 to 8."]]


handleCmd_inRoom ("VOTE" : m : p) = do
    cl <- thisClient
    let b = if m == "YES" then Just True else if m == "NO" then Just False else Nothing
    if isJust b then
        voted (p == ["FORCE"]) (fromJust b)
    else
        return [AnswerClients [sendChan cl] ["CHAT", nickServer,
            if (p == ["FORCE"]) then
                loc "/force: Please use 'yes' or 'no'."
            else
                loc "/vote: Please use 'yes' or 'no'."
        ]]


handleCmd_inRoom ["SAVE", stateName, location] = serverAdminOnly $ do
    return [ModifyRoom $ \r -> r{roomSaves = Map.insert stateName (location, mapParams r, params r) (roomSaves r)}]

handleCmd_inRoom ["DELETE", stateName] = serverAdminOnly $ do
    return [ModifyRoom $ \r -> r{roomSaves = Map.delete stateName (roomSaves r)}]

handleCmd_inRoom ["SAVEROOM", fileName] = serverAdminOnly $ do
    return [SaveRoom fileName]

handleCmd_inRoom ["LOADROOM", fileName] = serverAdminOnly $ do
    return [LoadRoom fileName]

handleCmd_inRoom ["LIST"] = return [] -- for old clients (<= 0.9.17)

handleCmd_inRoom (s:_) = return [ProtocolError $ "Incorrect command '" `B.append` s `B.append` "' (state: in room)"]

handleCmd_inRoom [] = return [ProtocolError "Empty command (state: in room)"]
