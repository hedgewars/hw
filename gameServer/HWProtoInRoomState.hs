{-# LANGUAGE OverloadedStrings #-}
module HWProtoInRoomState where

import qualified Data.Foldable as Foldable
import qualified Data.Map as Map
import Data.Sequence(Seq, (|>), (><), fromList, empty)
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
        let r = room rnc $ clientRoom rnc ci
        clNick <- clientNick
        clChan <- thisClientChans
        othersChans <- roomOthersChans
        return $
            if null . drop 5 $ teams r then
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
        hhsList (n:h:hhs) = HedgehogInfo n h : hhsList hhs
        newTeamHHNum r = min 4 (canAddNumber r)

handleCmd_inRoom ["REMOVE_TEAM", name] = do
        (ci, rnc) <- ask
        let r = room rnc $ clientRoom rnc ci
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

{-

handleCmd_inRoom clID clients rooms ["HH_NUM", teamName, numberStr]
    | not $ isMaster client = [ProtocolError "Not room master"]
    | hhNumber < 1 || hhNumber > 8 || noSuchTeam || hhNumber > (canAddNumber + (hhnum team)) = []
    | otherwise =
        [ModifyRoom $ modifyTeam team{hhnum = hhNumber},
        AnswerOthersInRoom ["HH_NUM", teamName, show hhNumber]]
    where
        client = clients IntMap.! clID
        room = rooms IntMap.! (roomID client)
        hhNumber = fromMaybe 0 (maybeRead numberStr :: Maybe Int)
        noSuchTeam = isNothing findTeam
        team = fromJust findTeam
        findTeam = find (\t -> teamName == teamname t) $ teams room
        canAddNumber = 48 - (sum . map hhnum $ teams room)


handleCmd_inRoom clID clients rooms ["TEAM_COLOR", teamName, newColor]
    | not $ isMaster client = [ProtocolError "Not room master"]
    | noSuchTeam = []
    | otherwise = [ModifyRoom $ modifyTeam team{teamcolor = newColor},
            AnswerOthersInRoom ["TEAM_COLOR", teamName, newColor],
            ModifyClient2 (teamownerId team) (\c -> c{clientClan = newColor})]
    where
        noSuchTeam = isNothing findTeam
        team = fromJust findTeam
        findTeam = find (\t -> teamName == teamname t) $ teams room
        client = clients IntMap.! clID
        room = rooms IntMap.! (roomID client)
-}

handleCmd_inRoom ["TOGGLE_READY"] = do
    cl <- thisClient
    chans <- roomClientsChans
    return [
        ModifyClient (\c -> c{isReady = not $ isReady cl}),
        ModifyRoom (\r -> r{readyPlayers = readyPlayers r + (if isReady cl then -1 else 1)}),
        AnswerClients chans [if isReady cl then "NOT_READY" else "READY", nick cl]
        ]

{-
handleCmd_inRoom clID clients rooms ["START_GAME"] =
    if isMaster client && (playersIn room == readyPlayers room) && (not . gameinprogress) room then
        if enoughClans then
            [ModifyRoom
                    (\r -> r{
                        gameinprogress = True,
                        roundMsgs = empty,
                        leftTeams = [],
                        teamsAtStart = teams r}
                    ),
            AnswerThisRoom ["RUN_GAME"]]
        else
            [Warning "Less than two clans!"]
    else
        []
    where
        client = clients IntMap.! clID
        room = rooms IntMap.! (roomID client)
        enoughClans = not $ null $ drop 1 $ group $ map teamcolor $ teams room


handleCmd_inRoom clID clients rooms ["EM", msg] =
    if (teamsInGame client > 0) && isLegal then
        (AnswerOthersInRoom ["EM", msg]) : [ModifyRoom (\r -> r{roundMsgs = roundMsgs r |> msg}) | not isKeepAlive]
    else
        []
    where
        client = clients IntMap.! clID
        (isLegal, isKeepAlive) = checkNetCmd msg

handleCmd_inRoom clID clients rooms ["ROUNDFINISHED"] =
    if isMaster client then
        [ModifyRoom
                (\r -> r{
                    gameinprogress = False,
                    readyPlayers = 0,
                    roundMsgs = empty,
                    leftTeams = [],
                    teamsAtStart = []}
                ),
        UnreadyRoomClients
        ] ++ answerRemovedTeams
    else
        []
    where
        client = clients IntMap.! clID
        room = rooms IntMap.! (roomID client)
        answerRemovedTeams = map (\t -> AnswerThisRoom ["REMOVE_TEAM", t]) $ leftTeams room


handleCmd_inRoom clID clients _ ["TOGGLE_RESTRICT_JOINS"]
    | isMaster client = [ModifyRoom (\r -> r{isRestrictedJoins = not $ isRestrictedJoins r})]
    | otherwise = [ProtocolError "Not room master"]
    where
        client = clients IntMap.! clID


handleCmd_inRoom clID clients _ ["TOGGLE_RESTRICT_TEAMS"]
    | isMaster client = [ModifyRoom (\r -> r{isRestrictedTeams = not $ isRestrictedTeams r})]
    | otherwise = [ProtocolError "Not room master"]
    where
        client = clients IntMap.! clID

handleCmd_inRoom clID clients rooms ["KICK", kickNick] =
    [KickRoomClient kickID | isMaster client && not noSuchClient && (kickID /= clID) && (roomID client == roomID kickClient)]
    where
        client = clients IntMap.! clID
        maybeClient = Foldable.find (\cl -> kickNick == nick cl) clients
        noSuchClient = isNothing maybeClient
        kickClient = fromJust maybeClient
        kickID = clientUID kickClient


handleCmd_inRoom clID clients _ ["TEAMCHAT", msg] =
    [AnswerSameClan ["EM", engineMsg]]
    where
        client = clients IntMap.! clID
        engineMsg = toEngineMsg $ 'b' : ((nick client) ++ "(team): " ++ msg ++ "\x20\x20")
-}
handleCmd_inRoom _ = return [ProtocolError "Incorrect command (state: in room)"]
