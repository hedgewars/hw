{-# LANGUAGE OverloadedStrings, DeriveDataTypeable #-}
module CoreTypes where

import Control.Concurrent
import Data.Word
import qualified Data.Map as Map
import Data.Sequence(Seq, empty)
import Data.Time
import Network
import Data.Function
import Data.ByteString.Char8 as B
import Data.Unique
import Control.Exception
import Data.Typeable
import Data.TConfig
-----------------------
import RoomsAndClients

type ClientChan = Chan [B.ByteString]

data ClientInfo =
    ClientInfo
    {
        clUID :: Unique,
        sendChan :: ClientChan,
        clientSocket :: Socket,
        host :: B.ByteString,
        connectTime :: UTCTime,
        nick :: B.ByteString,
        webPassword :: B.ByteString,
        logonPassed :: Bool,
        clientProto :: !Word16,
        roomID :: RoomIndex,
        pingsQueue :: !Word,
        isMaster :: Bool,
        isReady :: !Bool,
        isInGame :: Bool,
        isAdministrator :: Bool,
        clientClan :: Maybe B.ByteString,
        teamsInGame :: Word
    }

instance Eq ClientInfo where
    (==) = (==) `on` clientSocket

data HedgehogInfo =
    HedgehogInfo B.ByteString B.ByteString
    deriving (Show, Read)

data TeamInfo =
    TeamInfo
    {
        teamownerId :: ClientIndex,
        teamowner :: B.ByteString,
        teamname :: B.ByteString,
        teamcolor :: B.ByteString,
        teamgrave :: B.ByteString,
        teamfort :: B.ByteString,
        teamvoicepack :: B.ByteString,
        teamflag :: B.ByteString,
        difficulty :: Int,
        hhnum :: Int,
        hedgehogs :: [HedgehogInfo]
    }
    deriving (Show, Read)

data GameInfo =
    GameInfo
    {
        roundMsgs :: Seq B.ByteString,
        leftTeams :: [B.ByteString],
        teamsAtStart :: [TeamInfo],
        teamsInGameNumber :: Int,
        allPlayersHaveRegisteredAccounts :: Bool,
        giMapParams :: Map.Map B.ByteString B.ByteString,
        giParams :: Map.Map B.ByteString [B.ByteString]
    } deriving (Show, Read)

--newGameInfo ::  -> GameInfo
newGameInfo =
    GameInfo
        Data.Sequence.empty
        []

data RoomInfo =
    RoomInfo
    {
        masterID :: ClientIndex,
        name :: B.ByteString,
        password :: B.ByteString,
        roomProto :: Word16,
        teams :: [TeamInfo],
        gameInfo :: Maybe GameInfo,
        playersIn :: !Int,
        readyPlayers :: !Int,
        isRestrictedJoins :: Bool,
        isRestrictedTeams :: Bool,
        roomBansList :: [B.ByteString],
        mapParams :: Map.Map B.ByteString B.ByteString,
        params :: Map.Map B.ByteString [B.ByteString]
    }

newRoom :: RoomInfo
newRoom =
    RoomInfo
        (error "No room master defined")
        ""
        ""
        0
        []
        Nothing
        0
        0
        False
        False
        []
        (
            Map.fromList $ Prelude.zipWith (,)
                ["MAP", "MAPGEN", "MAZE_SIZE", "SEED", "TEMPLATE"]
                ["+rnd+", "0", "0", "seed", "0"]
        )
        (Map.singleton "SCHEME" ["Default"])

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
        --nextRoomID :: Int,
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
        "<font color=yellow><h3 align=center>Hedgewars 0.9.17 is out! Please update.</h3><p align=center><a href=http://hedgewars.org/download.html>Download page here</a></font>"
        41
        43 -- 0.9.18
        46631
        --0
        ""
        ""
        ""
        ""
        []
        False
        []

data AccountInfo =
    HasAccount B.ByteString Bool
    | Guest
    | Admin
    deriving (Show, Read)

data DBQuery =
    CheckAccount ClientIndex Int B.ByteString B.ByteString
    | ClearCache
    | SendStats Int Int
    deriving (Show, Read)

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
