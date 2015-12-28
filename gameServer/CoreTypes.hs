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

{-# LANGUAGE CPP, OverloadedStrings, DeriveDataTypeable, GeneralizedNewtypeDeriving #-}
module CoreTypes where

import Control.Concurrent
import Data.Word
import qualified Data.Map as Map
import Data.Time
import Network
import Data.Function
import Data.ByteString.Char8 as B
import Data.Unique
import Control.Exception
import Data.Typeable
import Data.TConfig
import Control.DeepSeq
-----------------------
import RoomsAndClients

#if __GLASGOW_HASKELL__ < 706
instance NFData B.ByteString
#endif

instance NFData (Chan a) where rnf a  = a `seq` ()

instance NFData Action where
    rnf (AnswerClients chans msg) = chans `deepseq` msg `deepseq` ()
    rnf a = a `seq` ()

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
    | BanNick B.ByteString NominalDiffTime B.ByteString
    | BanList
    | Unban B.ByteString
    | ChangeMaster (Maybe ClientIndex)
    | RemoveClientTeams
    | ModifyClient (ClientInfo -> ClientInfo)
    | ModifyClient2 ClientIndex (ClientInfo -> ClientInfo)
    | ModifyRoomClients (ClientInfo -> ClientInfo)
    | ModifyRoom (RoomInfo -> RoomInfo)
    | ModifyServerInfo (ServerInfo -> ServerInfo)
    | AddRoom B.ByteString B.ByteString
    | SendUpdateOnThisRoom
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
    | CheckBanned Bool
    | SaveReplay
    | Stats
    | CheckRecord
    | CheckFailed B.ByteString
    | CheckSuccess [B.ByteString]
    | Random [ClientChan] [B.ByteString]
    | QueryReplay B.ByteString
    | ShowReplay B.ByteString
    | Cleanup
    | RegisterEvent Event
    | SaveRoom B.ByteString
    | LoadRoom B.ByteString
    | ReactCmd [B.ByteString]
    | CheckVotes
    | SetRandomSeed


data Event = LobbyChatMessage
           | EngineMessage
           | RoomJoin

type EventsInfo = [(Int, UTCTime)]

newEventsInfo :: EventsInfo
newEventsInfo = []

type ClientChan = Chan [B.ByteString]

data CheckInfo =
    CheckInfo
    {
        recordFileName :: String,
        recordTeams :: [TeamInfo],
        details :: Maybe GameDetails
    }

data ClientInfo =
    ClientInfo
    {
        clUID :: !Unique,
        sendChan :: !ClientChan,
        clientSocket :: !Socket,
        host :: !B.ByteString,
        connectTime :: !UTCTime,
        nick :: !B.ByteString,
        webPassword :: !B.ByteString,
        serverSalt :: !B.ByteString,
        logonPassed :: !Bool,
        isVisible :: !Bool,
        clientProto :: !Word16,
        pingsQueue :: !Word,
        isMaster :: !Bool,
        isReady :: !Bool,
        isInGame :: !Bool,
        isAdministrator :: !Bool,
        isChecker :: !Bool,
        isContributor :: !Bool,
        isKickedFromServer :: !Bool,
        isJoinedMidGame :: !Bool,
        hasAskedList :: !Bool,
        clientClan :: !(Maybe B.ByteString),
        checkInfo :: !(Maybe CheckInfo),
        eiLobbyChat,
        eiEM,
        eiJoin :: !EventsInfo,
        teamsInGame :: !Word
    }

instance Eq ClientInfo where
    (==) = (==) `on` clientSocket

data HedgehogInfo =
    HedgehogInfo B.ByteString B.ByteString
    deriving (Show, Read)

data TeamInfo =
    TeamInfo
    {
        teamowner :: !B.ByteString,
        teamname :: !B.ByteString,
        teamcolor :: !B.ByteString,
        teamgrave :: !B.ByteString,
        teamfort :: !B.ByteString,
        teamvoicepack :: !B.ByteString,
        teamflag :: !B.ByteString,
        isOwnerRegistered :: !Bool,
        difficulty :: !Int,
        hhnum :: !Int,
        hedgehogs :: ![HedgehogInfo]
    }
    deriving (Show, Read)

instance Eq TeamInfo where
    (==) = (==) `on` teamname

data GameInfo =
    GameInfo
    {
        roundMsgs :: [B.ByteString],
        lastFilteredTimedMsg :: Maybe B.ByteString,
        leftTeams :: [B.ByteString],
        rejoinedTeams :: [B.ByteString], -- for 0.9.21 frontend workaround
        teamsAtStart :: [TeamInfo],
        teamsInGameNumber :: Int,
        allPlayersHaveRegisteredAccounts :: !Bool,
        giMapParams :: Map.Map B.ByteString B.ByteString,
        giParams :: Map.Map B.ByteString [B.ByteString],
        isPaused :: Bool
    } deriving (Show, Read)

newGameInfo :: [TeamInfo]
                -> Int
                -> Bool
                -> Map.Map ByteString ByteString
                -> Map.Map ByteString [ByteString]
                -> Bool
                -> GameInfo
newGameInfo =
    GameInfo
        []
        Nothing
        []
        []


data RoomInfo =
    RoomInfo
    {
        masterID :: !(Maybe ClientIndex),
        name :: !B.ByteString,
        password :: !B.ByteString,
        roomProto :: !Word16,
        teams :: ![TeamInfo],
        gameInfo :: !(Maybe GameInfo),
        playersIn :: !Int,
        readyPlayers :: !Int,
        isRestrictedJoins :: !Bool,
        isRestrictedTeams :: !Bool,
        isRegisteredOnly :: !Bool,
        isSpecial :: !Bool,
        defaultHedgehogsNumber :: !Int,
        teamsNumberLimit :: !Int,
        greeting :: !B.ByteString,
        voting :: !(Maybe Voting),
        roomBansList :: ![B.ByteString],
        mapParams :: !(Map.Map B.ByteString B.ByteString),
        params :: !(Map.Map B.ByteString [B.ByteString]),
        roomSaves :: !(Map.Map B.ByteString (Map.Map B.ByteString B.ByteString, Map.Map B.ByteString [B.ByteString]))
    }

newRoom :: RoomInfo
newRoom =
    RoomInfo
        Nothing
        ""
        ""
        0
        []
        Nothing
        0
        0
        False
        False
        False
        False
        4
        8
        ""
        Nothing
        []
        (
            Map.fromList $ Prelude.zip
                ["FEATURE_SIZE", "MAP", "MAPGEN", "MAZE_SIZE", "SEED", "TEMPLATE"]
                ["12", "+rnd+", "0", "0", "seed", "0"]
        )
        (
            Map.fromList $ Prelude.zip
                ["AMMO", "SCHEME", "SCRIPT", "THEME"]
                [["Default"], ["Default"], ["Normal"], ["avematan"]]
        )
        Map.empty


data StatisticsInfo =
    StatisticsInfo
    {
        playersNumber :: Int,
        roomsNumber :: Int
    }

data ServerInfo =
    ServerInfo
    {
        isDedicated :: Bool,
        serverMessage :: B.ByteString,
        serverMessageForOldVersions :: B.ByteString,
        latestReleaseVersion :: Word16,
        earliestCompatibleVersion :: Word16,
        listenPort :: PortNumber,
        dbHost :: B.ByteString,
        dbName :: B.ByteString,
        dbLogin :: B.ByteString,
        dbPassword :: B.ByteString,
        bans :: [BanInfo],
        shutdownPending :: Bool,
        runArgs :: [String],
        coreChan :: Chan CoreMessage,
        dbQueries :: Chan DBQuery,
        serverSocket :: Maybe Socket,
        serverConfig :: Maybe Conf
    }


newServerInfo :: Chan CoreMessage -> Chan DBQuery -> Maybe Socket -> Maybe Conf -> ServerInfo
newServerInfo =
    ServerInfo
        True
        "<h2><p align=center><a href=\"http://www.hedgewars.org/\">http://www.hedgewars.org/</a></p></h2>"
        "<font color=yellow><h3 align=center>Hedgewars 0.9.22 is out! Please update.</h3><p align=center><a href=http://hedgewars.org/download.html>Download page here</a></font>"
        51 -- latestReleaseVersion
        41 -- earliestCompatibleVersion
        46631
        ""
        ""
        ""
        ""
        []
        False
        []

data Voting = Voting {
        voteTTL :: Int,
        entitledToVote :: [Unique],
        votes :: [(Unique, Bool)],
        voteType :: VoteType
    }


data VoteType = VoteKick B.ByteString
              | VoteMap B.ByteString
              | VotePause
              | VoteNewSeed
              | VoteHedgehogsPerTeam Int


newVoting :: VoteType -> Voting
newVoting = Voting 2 [] []


data AccountInfo =
    HasAccount B.ByteString Bool Bool
    | Guest
    | Admin
    | ReplayName B.ByteString
    deriving (Show, Read)

data DBQuery =
    CheckAccount ClientIndex Int B.ByteString B.ByteString
    | ClearCache
    | SendStats Int Int
    | StoreAchievements Word16 B.ByteString [(B.ByteString, B.ByteString)] GameDetails [B.ByteString]
    | GetReplayName ClientIndex Int B.ByteString
    deriving (Show, Read)

data GameDetails =
    GameDetails {
        gameScript :: B.ByteString
        , infRope
        , isVamp
        , infAttacks :: Bool
    } deriving (Show, Read)

instance NFData GameDetails where
    rnf (GameDetails a b c d) = a `deepseq` b `deepseq` c `deepseq` d `deepseq` ()

data CoreMessage =
    Accept ClientInfo
    | ClientMessage (ClientIndex, [B.ByteString])
    | ClientAccountInfo ClientIndex Int AccountInfo
    | TimerAction Int
    | Remove ClientIndex

type MRnC = MRoomsAndClients RoomInfo ClientInfo
type IRnC = IRoomsAndClients RoomInfo ClientInfo

data Notice =
    NickAlreadyInUse
    | AdminLeft
    | WrongPassword
    deriving Enum

data ShutdownException =
    ShutdownException
     deriving (Show, Typeable)

instance Exception ShutdownException

data ShutdownThreadException = ShutdownThreadException String
     deriving Typeable

instance Show ShutdownThreadException where
    show (ShutdownThreadException s) = s
instance Exception ShutdownThreadException

data BanInfo =
    BanByIP B.ByteString B.ByteString UTCTime
    | BanByNick B.ByteString B.ByteString UTCTime
    deriving (Show, Read)
