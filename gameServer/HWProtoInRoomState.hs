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
import Actions
import Utils
import HandlerUtils
import RoomsAndClients
import EngineInteraction

handleCmd_inRoom :: CmdHandler

handleCmd_inRoom ["CHAT", msg] = do
    n <- clientNick
    s <- roomOthersChans
    return [AnswerClients s ["CHAT", n, msg]]

handleCmd_inRoom ["PART"] = return [MoveToLobby "part"]
handleCmd_inRoom ["PART", msg] = return [MoveToLobby $ "part: " `B.append` msg]


handleCmd_inRoom ("CFG" : paramName : paramStrs)
    | null paramStrs = return [ProtocolError $ loc "Empty config entry"]
    | otherwise = do
        chans <- roomOthersChans
        cl <- thisClient
        if isMaster cl then
           return [
                ModifyRoom f,
                AnswerClients chans ("CFG" : paramName : paramStrs)]
            else
            return [ProtocolError $ loc "Not room master"]
    where
        f r = if paramName `Map.member` (mapParams r) then
                r{mapParams = Map.insert paramName (head paramStrs) (mapParams r)}
                else
                r{params = Map.insert paramName paramStrs (params r)}

handleCmd_inRoom ("ADD_TEAM" : tName : color : grave : fort : voicepack : flag : difStr : hhsInfo)
    | length hhsInfo /= 16 = return [ProtocolError $ loc "Corrupted hedgehogs info"]
    | otherwise = do
        (ci, _) <- ask
        rm <- thisRoom
        clNick <- clientNick
        clChan <- thisClientChans
        othChans <- roomOthersChans
        roomChans <- roomClientsChans
        cl <- thisClient
        teamColor <-
            if clientProto cl < 42 then 
                return color
                else
                liftM (head . (L.\\) (map B.singleton ['0'..]) . map teamcolor . teams) thisRoom
        let roomTeams = teams rm
        let hhNum = let p = if not $ null roomTeams then hhnum $ head roomTeams else 4 in newTeamHHNum roomTeams p
        let newTeam = clNick `seq` TeamInfo ci clNick tName teamColor grave fort voicepack flag dif hhNum (hhsList hhsInfo)
        return $
            if not . null . drop (maxTeams rm - 1) $ roomTeams then
                [Warning $ loc "too many teams"]
            else if canAddNumber roomTeams <= 0 then
                [Warning $ loc "too many hedgehogs"]
            else if isJust $ findTeam rm then
                [Warning $ loc "There's already a team with same name in the list"]
            else if isJust $ gameInfo rm then
                [Warning $ loc "round in progress"]
            else if isRestrictedTeams rm then
                [Warning $ loc "restricted"]
            else
                [ModifyRoom (\r -> r{teams = teams r ++ [newTeam]}),
                SendUpdateOnThisRoom,
                ModifyClient (\c -> c{teamsInGame = teamsInGame c + 1, clientClan = Just teamColor}),
                AnswerClients clChan ["TEAM_ACCEPTED", tName],
                AnswerClients clChan ["HH_NUM", tName, showB $ hhnum newTeam],
                AnswerClients othChans $ teamToNet $ newTeam,
                AnswerClients roomChans ["TEAM_COLOR", tName, teamColor]
                ]
        where
        canAddNumber rt = (48::Int) - (sum $ map hhnum rt)
        findTeam = find (\t -> tName == teamname t) . teams
        dif = readInt_ difStr
        hhsList [] = []
        hhsList [_] = error "Hedgehogs list with odd elements number"
        hhsList (n:h:hhs) = HedgehogInfo n h : hhsList hhs
        newTeamHHNum rt p = min p (canAddNumber rt)
        maxTeams r
            | roomProto r < 38 = 6
            | otherwise = 8


handleCmd_inRoom ["REMOVE_TEAM", tName] = do
        (ci, _) <- ask
        r <- thisRoom

        let maybeTeam = findTeam r
        let team = fromJust maybeTeam

        return $
            if isNothing $ maybeTeam then
                [Warning $ loc "REMOVE_TEAM: no such team"]
            else if ci /= teamownerId team then
                [ProtocolError $ loc "Not team owner!"]
            else
                [RemoveTeam tName,
                ModifyClient
                    (\c -> c{
                        teamsInGame = teamsInGame c - 1,
                        clientClan = if teamsInGame c == 1 then Nothing else Just $ anotherTeamClan ci team r
                    })
                ]
    where
        anotherTeamClan ci team = teamcolor . fromMaybe (error "CHECKPOINT 011") . find (\t -> (teamownerId t == ci) && (t /= team)) . teams
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
            [ProtocolError $ loc "Not room master"]
        else if isNothing maybeTeam then
            []
        else if hhNumber < 1 || hhNumber > 8 || hhNumber > canAddNumber r + hhnum team then
            [AnswerClients clChan ["HH_NUM", teamName, showB $ hhnum team]]
        else
            [ModifyRoom $ modifyTeam team{hhnum = hhNumber},
            AnswerClients others ["HH_NUM", teamName, showB hhNumber]]
    where
        hhNumber = readInt_ numberStr
        findTeam = find (\t -> teamName == teamname t) . teams
        canAddNumber = (-) 48 . sum . map hhnum . teams



handleCmd_inRoom ["TEAM_COLOR", teamName, newColor] = do
    cl <- thisClient
    others <- roomOthersChans
    r <- thisRoom

    let maybeTeam = findTeam r
    let team = fromJust maybeTeam

    return $
        if not $ isMaster cl then
            [ProtocolError $ loc "Not room master"]
        else if isNothing maybeTeam then
            []
        else
            [ModifyRoom $ modifyTeam team{teamcolor = newColor},
            AnswerClients others ["TEAM_COLOR", teamName, newColor],
            ModifyClient2 (teamownerId team) (\c -> c{clientClan = Just newColor})]
    where
        findTeam = find (\t -> teamName == teamname t) . teams


handleCmd_inRoom ["TOGGLE_READY"] = do
    cl <- thisClient
    chans <- roomClientsChans
    if isMaster cl then
        return []
        else
        return [
            ModifyRoom (\r -> r{readyPlayers = readyPlayers r + (if isReady cl then -1 else 1)}),
            ModifyClient (\c -> c{isReady = not $ isReady cl}),
            AnswerClients chans $ if clientProto cl < 38 then
                    [if isReady cl then "NOT_READY" else "READY", nick cl]
                    else
                    ["CLIENT_FLAGS", if isReady cl then "-r" else "+r", nick cl]
            ]


handleCmd_inRoom ["START_GAME"] = do
    (ci, rnc) <- ask
    cl <- thisClient
    rm <- thisRoom
    chans <- roomClientsChans

    let nicks = map (nick . client rnc) . roomClients rnc $ clientRoom rnc ci
    let allPlayersRegistered = all ((<) 0 . B.length . webPassword . client rnc . teamownerId) $ teams rm

    if isMaster cl && (playersIn rm == readyPlayers rm || clientProto cl > 43) && not (isJust $ gameInfo rm) then
        if enoughClans rm then
            return [
                ModifyRoom
                    (\r -> r{
                        gameInfo = Just $ newGameInfo (teams rm) (length $ teams rm) allPlayersRegistered (mapParams rm) (params rm)
                        }
                    )
                , AnswerClients chans ["RUN_GAME"]
                , SendUpdateOnThisRoom
                , AnswerClients chans $ "CLIENT_FLAGS" : "+g" : nicks
                , ModifyRoomClients (\c -> c{isInGame = True})
                ]
            else
            return [Warning $ loc "Less than two clans!"]
        else
        return []
    where
        enoughClans = not . null . drop 1 . group . map teamcolor . teams


handleCmd_inRoom ["EM", msg] = do
    cl <- thisClient
    rm <- thisRoom
    chans <- roomOthersChans

    if teamsInGame cl > 0 && (isJust $ gameInfo rm) && (not $ B.null legalMsgs) then
        return $ AnswerClients chans ["EM", legalMsgs]
            : [ModifyRoom (\r -> r{gameInfo = liftM (\g -> g{roundMsgs = nonEmptyMsgs : roundMsgs g}) $ gameInfo r}) | not $ B.null nonEmptyMsgs]
        else
        return []
    where
        (legalMsgs, nonEmptyMsgs) = checkNetCmd msg


handleCmd_inRoom ["ROUNDFINISHED", correctly] = do
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
        isCorrect = correctly == "1"

-- compatibility with clients with protocol < 38
handleCmd_inRoom ["ROUNDFINISHED"] =
    handleCmd_inRoom ["ROUNDFINISHED", "1"]

handleCmd_inRoom ["TOGGLE_RESTRICT_JOINS"] = do
    cl <- thisClient
    return $
        if not $ isMaster cl then
            [ProtocolError $ loc "Not room master"]
        else
            [ModifyRoom (\r -> r{isRestrictedJoins = not $ isRestrictedJoins r})]


handleCmd_inRoom ["TOGGLE_RESTRICT_TEAMS"] = do
    cl <- thisClient
    return $
        if not $ isMaster cl then
            [ProtocolError $ loc "Not room master"]
        else
            [ModifyRoom (\r -> r{isRestrictedTeams = not $ isRestrictedTeams r})]


handleCmd_inRoom ["TOGGLE_REGISTERED_ONLY"] = do
    cl <- thisClient
    return $
        if not $ isMaster cl then
            [ProtocolError $ loc "Not room master"]
        else
            [ModifyRoom (\r -> r{isRegisteredOnly = not $ isRegisteredOnly r})]


handleCmd_inRoom ["ROOM_NAME", newName] = do
    cl <- thisClient
    rs <- allRoomInfos
    rm <- thisRoom
    chans <- sameProtoChans

    return $
        if not $ isMaster cl then
            [ProtocolError $ loc "Not room master"]
        else
        if isJust $ find (\r -> newName == name r) rs then
            [Warning $ loc "Room with such name already exists"]
        else
            [ModifyRoom roomUpdate,
            AnswerClients chans ("ROOM" : "UPD" : name rm : roomInfo (nick cl) (roomUpdate rm))]
    where
        roomUpdate r = r{name = newName}


handleCmd_inRoom ["KICK", kickNick] = do
    (thisClientId, rnc) <- ask
    maybeClientId <- clientByNick kickNick
    master <- liftM isMaster thisClient
    rm <- thisRoom
    let kickId = fromJust maybeClientId
    let kickCl = rnc `client` kickId
    let sameRoom = clientRoom rnc thisClientId == clientRoom rnc kickId
    let notOnly2Clans = (length . group . sort . map teamcolor . teams $ rm) > 2
    return
        [KickRoomClient kickId |
            master
            && isJust maybeClientId
            && (kickId /= thisClientId)
            && sameRoom
            && ((isNothing $ gameInfo rm) || notOnly2Clans || teamsInGame kickCl = 0)
        ]


handleCmd_inRoom ["DELEGATE", newAdmin] = do
    (thisClientId, rnc) <- ask
    maybeClientId <- clientByNick newAdmin
    master <- liftM isMaster thisClient
    serverAdmin <- liftM isAdministrator thisClient
    let newAdminId = fromJust maybeClientId
    let sameRoom = clientRoom rnc thisClientId == clientRoom rnc newAdminId
    return
        [ChangeMaster (Just newAdminId) |
            (master || serverAdmin)
                && isJust maybeClientId
                && ((newAdminId /= thisClientId) || (serverAdmin && not master))
                && sameRoom]


handleCmd_inRoom ["TEAMCHAT", msg] = do
    cl <- thisClient
    chans <- roomSameClanChans
    return [AnswerClients chans ["EM", engineMsg cl]]
    where
        engineMsg cl = toEngineMsg $ B.concat ["b", nick cl, "(team): ", msg, "\x20\x20"]


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


handleCmd_inRoom ["LIST"] = return [] -- for old clients (<= 0.9.17)

handleCmd_inRoom (s:_) = return [ProtocolError $ "Incorrect command '" `B.append` s `B.append` "' (state: in room)"]

handleCmd_inRoom [] = return [ProtocolError "Empty command (state: in room)"]
