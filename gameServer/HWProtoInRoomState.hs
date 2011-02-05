{-# LANGUAGE OverloadedStrings #-}
module HWProtoInRoomState where

import qualified Data.Map as Map
import Data.Sequence((|>), empty)
import Data.List
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

handleCmd_inRoom :: CmdHandler

handleCmd_inRoom ["CHAT", msg] = do
    n <- clientNick
    s <- roomOthersChans
    return [AnswerClients s ["CHAT", n, msg]]

handleCmd_inRoom ["PART"] = return [MoveToLobby "part"]
handleCmd_inRoom ["PART", msg] = return [MoveToLobby $ "part: " `B.append` msg]


handleCmd_inRoom ("CFG" : paramName : paramStrs)
    | null paramStrs = return [ProtocolError "Empty config entry"]
    | otherwise = do
        chans <- roomOthersChans
        cl <- thisClient
        if isMaster cl then
           return [
                ModifyRoom (\r -> r{params = Map.insert paramName paramStrs (params r)}),
                AnswerClients chans ("CFG" : paramName : paramStrs)]
            else
            return [ProtocolError "Not room master"]

handleCmd_inRoom ("ADD_TEAM" : name : color : grave : fort : voicepack : flag : difStr : hhsInfo)
    | length hhsInfo /= 16 = return [ProtocolError "Corrupted hedgehogs info"]
    | otherwise = do
        (ci, rnc) <- ask
        r <- thisRoom
        clNick <- clientNick
        clChan <- thisClientChans
        othersChans <- roomOthersChans
        return $
            if not . null . drop 5 $ teams r then
                [Warning "too many teams"]
            else if canAddNumber r <= 0 then
                [Warning "too many hedgehogs"]
            else if isJust $ findTeam r then
                [Warning "There's already a team with same name in the list"]
            else if gameinprogress r then
                [Warning "round in progress"]
            else if isRestrictedTeams r then
                [Warning "restricted"]
            else
                [ModifyRoom (\r -> r{teams = teams r ++ [newTeam ci clNick r]}),
                ModifyClient (\c -> c{teamsInGame = teamsInGame c + 1, clientClan = color}),
                AnswerClients clChan ["TEAM_ACCEPTED", name],
                AnswerClients othersChans $ teamToNet $ newTeam ci clNick r,
                AnswerClients othersChans ["TEAM_COLOR", name, color]
                ]
        where
        canAddNumber r = 48 - (sum . map hhnum $ teams r)
        findTeam = find (\t -> name == teamname t) . teams
        newTeam ci clNick r = (TeamInfo ci clNick name color grave fort voicepack flag difficulty (newTeamHHNum r) (hhsList hhsInfo))
        difficulty = case B.readInt difStr of
                           Just (i, t) | B.null t -> fromIntegral i
                           otherwise -> 0
        hhsList [] = []
        hhsList [_] = error "Hedgehogs list with odd elements number"
        hhsList (n:h:hhs) = HedgehogInfo n h : hhsList hhs
        newTeamHHNum r = min 4 (canAddNumber r)

handleCmd_inRoom ["REMOVE_TEAM", name] = do
        (ci, rnc) <- ask
        r <- thisRoom
        clNick <- clientNick

        let maybeTeam = findTeam r
        let team = fromJust maybeTeam

        return $
            if isNothing $ findTeam r then
                [Warning "REMOVE_TEAM: no such team"]
            else if clNick /= teamowner team then
                [ProtocolError "Not team owner!"]
            else
                [RemoveTeam name,
                ModifyClient
                    (\c -> c{
                        teamsInGame = teamsInGame c - 1,
                        clientClan = if teamsInGame c == 1 then undefined else anotherTeamClan ci r
                        })
                ]
    where
        anotherTeamClan ci = teamcolor . fromJust . find (\t -> teamownerId t == ci) . teams
        findTeam = find (\t -> name == teamname t) . teams


handleCmd_inRoom ["HH_NUM", teamName, numberStr] = do
    cl <- thisClient
    others <- roomOthersChans
    r <- thisRoom

    let maybeTeam = findTeam r
    let team = fromJust maybeTeam

    return $
        if not $ isMaster cl then
            [ProtocolError "Not room master"]
        else if hhNumber < 1 || hhNumber > 8 || isNothing maybeTeam || hhNumber > (canAddNumber r) + (hhnum team) then
            []
        else
            [ModifyRoom $ modifyTeam team{hhnum = hhNumber},
            AnswerClients others ["HH_NUM", teamName, B.pack $ show hhNumber]]
    where
        hhNumber = case B.readInt numberStr of
                           Just (i, t) | B.null t -> fromIntegral i
                           otherwise -> 0
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
            [ProtocolError "Not room master"]
        else if isNothing maybeTeam then
            []
        else
            [ModifyRoom $ modifyTeam team{teamcolor = newColor},
            AnswerClients others ["TEAM_COLOR", teamName, newColor],
            ModifyClient2 (teamownerId team) (\c -> c{clientClan = newColor})]
    where
        findTeam = find (\t -> teamName == teamname t) . teams


handleCmd_inRoom ["TOGGLE_READY"] = do
    cl <- thisClient
    chans <- roomClientsChans
    return [
        ModifyClient (\c -> c{isReady = not $ isReady cl}),
        ModifyRoom (\r -> r{readyPlayers = readyPlayers r + (if isReady cl then -1 else 1)}),
        AnswerClients chans ["CLIENT_FLAGS", if isReady cl then "-r" else "+r", nick cl]
        ]

handleCmd_inRoom ["START_GAME"] = do
    cl <- thisClient
    r <- thisRoom
    chans <- roomClientsChans

    if isMaster cl && (playersIn r == readyPlayers r) && (not $ gameinprogress r) then
        if enoughClans r then
            return [
                ModifyRoom
                    (\r -> r{
                        gameinprogress = True,
                        roundMsgs = empty,
                        leftTeams = [],
                        teamsAtStart = teams r}
                    ),
                AnswerClients chans ["RUN_GAME"]
                ]
            else
            return [Warning "Less than two clans!"]
        else
        return []
    where
        enoughClans = not . null . drop 1 . group . map teamcolor . teams


handleCmd_inRoom ["EM", msg] = do
    cl <- thisClient
    r <- thisRoom
    chans <- roomOthersChans
    
    if (teamsInGame cl > 0) && isLegal then
        return $ (AnswerClients chans ["EM", msg]) : [ModifyRoom (\r -> r{roundMsgs = roundMsgs r |> msg}) | not isKeepAlive]
        else
        return []
    where
        (isLegal, isKeepAlive) = checkNetCmd msg


handleCmd_inRoom ["ROUNDFINISHED", _] = do
    cl <- thisClient
    r <- thisRoom
    chans <- roomClientsChans

    if isMaster cl && (gameinprogress r) then
        return $ (ModifyRoom
                (\r -> r{
                    gameinprogress = False,
                    readyPlayers = 0,
                    roundMsgs = empty,
                    leftTeams = [],
                    teamsAtStart = []}
                ))
            : UnreadyRoomClients
            : answerRemovedTeams chans r
        else
        return []
    where
        answerRemovedTeams chans = map (\t -> AnswerClients chans ["REMOVE_TEAM", t]) . leftTeams

handleCmd_inRoom ["TOGGLE_RESTRICT_JOINS"] = do
    cl <- thisClient
    return $
        if not $ isMaster cl then
            [ProtocolError "Not room master"]
        else
            [ModifyRoom (\r -> r{isRestrictedJoins = not $ isRestrictedJoins r})]


handleCmd_inRoom ["TOGGLE_RESTRICT_TEAMS"] = do
    cl <- thisClient
    return $
        if not $ isMaster cl then
            [ProtocolError "Not room master"]
        else
            [ModifyRoom (\r -> r{isRestrictedTeams = not $ isRestrictedTeams r})]


handleCmd_inRoom ["KICK", kickNick] = do
    (thisClientId, rnc) <- ask
    maybeClientId <- clientByNick kickNick
    master <- liftM isMaster thisClient
    let kickId = fromJust maybeClientId
    let sameRoom = (clientRoom rnc thisClientId) == (clientRoom rnc kickId)
    return
        [KickRoomClient kickId | master && isJust maybeClientId && (kickId /= thisClientId) && sameRoom]


handleCmd_inRoom ["TEAMCHAT", msg] = do
    cl <- thisClient
    chans <- roomSameClanChans
    return [AnswerClients chans ["EM", engineMsg cl]]
    where
        engineMsg cl = toEngineMsg $ "b" `B.append` (nick cl) `B.append` "(team): " `B.append` msg `B.append` "\x20\x20"

handleCmd_inRoom _ = return [ProtocolError "Incorrect command (state: in room)"]
