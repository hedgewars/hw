module HWProtoInRoomState where

import qualified Data.Foldable as Foldable
import qualified Data.IntMap as IntMap
import qualified Data.Map as Map
import Data.Sequence(Seq, (|>), (><), fromList, empty)
import Data.List
import Maybe
import qualified Codec.Binary.UTF8.String as UTF8
--------------------------------------
import CoreTypes
import Actions
import Utils


handleCmd_inRoom :: CmdHandler

handleCmd_inRoom clID clients _ ["CHAT", msg] =
    [AnswerOthersInRoom ["CHAT", clientNick, msg]]
    where
        clientNick = nick $ clients IntMap.! clID


handleCmd_inRoom clID clients _ ["TEAM_CHAT", msg] =
    [AnswerOthersInRoom ["TEAM_CHAT", clientNick, msg]]
    where
        clientNick = nick $ clients IntMap.! clID


handleCmd_inRoom clID clients rooms ["PART"] =
    [RoomRemoveThisClient "part"]
    where
        client = clients IntMap.! clID


handleCmd_inRoom clID clients rooms ("CFG" : paramName : paramStrs)
    | null paramStrs = [ProtocolError "Empty config entry"]
    | isMaster client =
        [ModifyRoom (\r -> r{params = Map.insert paramName paramStrs (params r)}),
        AnswerOthersInRoom ("CFG" : paramName : paramStrs)]
    | otherwise = [ProtocolError "Not room master"]
    where
        client = clients IntMap.! clID

handleCmd_inRoom clID clients rooms ("ADD_TEAM" : name : color : grave : fort : voicepack : flag : difStr : hhsInfo)
    | length hhsInfo == 15 && clientProto client < 30 = handleCmd_inRoom clID clients rooms ("ADD_TEAM" : name : color : grave : fort : voicepack : " " : flag : difStr : hhsInfo)
    | length hhsInfo /= 16 = [ProtocolError "Corrupted hedgehogs info"]
    | length (teams room) == 6 = [Warning "too many teams"]
    | canAddNumber <= 0 = [Warning "too many hedgehogs"]
    | isJust findTeam = [Warning "There's already a team with same name in the list"]
    | gameinprogress room = [Warning "round in progress"]
    | isRestrictedTeams room = [Warning "restricted"]
    | otherwise =
        [ModifyRoom (\r -> r{teams = teams r ++ [newTeam]}),
        ModifyClient (\c -> c{teamsInGame = teamsInGame c + 1, clientClan = color}),
        AnswerThisClient ["TEAM_ACCEPTED", name],
        AnswerOthersInRoom $ teamToNet (clientProto client) newTeam,
        AnswerOthersInRoom ["TEAM_COLOR", name, color]
        ]
    where
        client = clients IntMap.! clID
        room = rooms IntMap.! (roomID client)
        canAddNumber = 48 - (sum . map hhnum $ teams room)
        findTeam = find (\t -> name == teamname t) $ teams room
        newTeam = (TeamInfo clID (nick client) name color grave fort voicepack flag difficulty newTeamHHNum (hhsList hhsInfo))
        difficulty = fromMaybe 0 (maybeRead difStr :: Maybe Int)
        hhsList [] = []
        hhsList (n:h:hhs) = HedgehogInfo n h : hhsList hhs
        newTeamHHNum = min 4 canAddNumber

handleCmd_inRoom clID clients rooms ["REMOVE_TEAM", teamName]
    | noSuchTeam = [Warning "REMOVE_TEAM: no such team"]
    | nick client /= teamowner team = [ProtocolError "Not team owner!"]
    | otherwise =
            [RemoveTeam teamName,
            ModifyClient (\c -> c{teamsInGame = teamsInGame c - 1})
            ]
    where
        client = clients IntMap.! clID
        room = rooms IntMap.! (roomID client)
        noSuchTeam = isNothing findTeam
        team = fromJust findTeam
        findTeam = find (\t -> teamName == teamname t) $ teams room


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


handleCmd_inRoom clID clients rooms ["TOGGLE_READY"] =
    [ModifyClient (\c -> c{isReady = not $ isReady client}),
    ModifyRoom (\r -> r{readyPlayers = readyPlayers r + (if isReady client then -1 else 1)}),
    AnswerThisRoom [if isReady client then "NOT_READY" else "READY", nick client]]
    where
        client = clients IntMap.! clID


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
    if (teamsInGame client > 0) then
        [AnswerSameClan ["EM", engineMsg]]
    else
        []
    where
        client = clients IntMap.! clID
        -- FIXME: why are those decoded* function used? 
        -- it would be better to use ByteString instead of String
        engineMsg = toEngineMsg $ 'b' : (decodedNick ++ "(team): " ++ decodedMsg ++ "\x20\x20")
        decodedMsg = UTF8.decodeString msg
        decodedNick = UTF8.decodeString $ nick client

handleCmd_inRoom clID _ _ _ = [ProtocolError "Incorrect command (state: in room)"]
