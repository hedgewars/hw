module CoreTypes where

import System.IO
import Control.Concurrent.Chan
import Control.Concurrent.STM
import Data.Word
import qualified Data.Map as Map
import qualified Data.IntMap as IntMap
import qualified Data.IntSet as IntSet
import Data.Sequence(Seq, empty)
import Data.Time
import Network
import Data.Function

import RoomsAndClients

data ClientInfo =
    ClientInfo
    {
        clientUID :: !Int,
        sendChan :: Chan [String],
        clientHandle :: Handle,
        host :: String,
        connectTime :: UTCTime,
        nick :: String,
        webPassword :: String,
        logonPassed :: Bool,
        clientProto :: !Word16,
        roomID :: !Int,
        pingsQueue :: !Word,
        isMaster :: Bool,
        isReady :: Bool,
        isAdministrator :: Bool,
        clientClan :: String,
        teamsInGame :: Word
    }

instance Show ClientInfo where
    show ci = show (clientUID ci)
            ++ " nick: " ++ (nick ci)
            ++ " host: " ++ (host ci)

instance Eq ClientInfo where
    (==) = (==) `on` clientHandle

data HedgehogInfo =
    HedgehogInfo String String

data TeamInfo =
    TeamInfo
    {
        teamownerId :: !Int,
        teamowner :: String,
        teamname :: String,
        teamcolor :: String,
        teamgrave :: String,
        teamfort :: String,
        teamvoicepack :: String,
        teamflag :: String,
        difficulty :: Int,
        hhnum :: Int,
        hedgehogs :: [HedgehogInfo]
    }

instance Show TeamInfo where
    show ti = "owner: " ++ (teamowner ti)
            ++ "name: " ++ (teamname ti)
            ++ "color: " ++ (teamcolor ti)

data RoomInfo =
    RoomInfo
    {
        roomUID :: !Int,
        masterID :: !Int,
        name :: String,
        password :: String,
        roomProto :: Word16,
        teams :: [TeamInfo],
        gameinprogress :: Bool,
        playersIn :: !Int,
        readyPlayers :: !Int,
        playersIDs :: IntSet.IntSet,
        isRestrictedJoins :: Bool,
        isRestrictedTeams :: Bool,
        roundMsgs :: Seq String,
        leftTeams :: [String],
        teamsAtStart :: [TeamInfo],
        params :: Map.Map String [String]
    }

instance Show RoomInfo where
    show ri = show (roomUID ri)
            ++ ", players ids: " ++ show (IntSet.size $ playersIDs ri)
            ++ ", players: " ++ show (playersIn ri)
            ++ ", ready: " ++ show (readyPlayers ri)
            ++ ", teams: " ++ show (teams ri)

instance Eq RoomInfo where
    (==) = (==) `on` roomUID

newRoom = (
    RoomInfo
        0
        0
        ""
        ""
        0
        []
        False
        0
        0
        IntSet.empty
        False
        False
        Data.Sequence.empty
        []
        []
        (Map.singleton "MAP" ["+rnd+"])
    )

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
        serverMessage :: String,
        serverMessageForOldVersions :: String,
        latestReleaseVersion :: Word16,
        listenPort :: PortNumber,
        nextRoomID :: Int,
        dbHost :: String,
        dbLogin :: String,
        dbPassword :: String,
        lastLogins :: [(String, UTCTime)],
        stats :: TMVar StatisticsInfo,
        coreChan :: Chan CoreMessage,
        dbQueries :: Chan DBQuery
    }

instance Show ServerInfo where
    show si = "Server Info"

newServerInfo = (
    ServerInfo
        True
        "<h2><p align=center><a href=\"http://www.hedgewars.org/\">http://www.hedgewars.org/</a></p></h2>"
        "<font color=yellow><h3 align=center>Hedgewars 0.9.13 is out! Please update.</h3><p align=center><a href=http://hedgewars.org/download.html>Download page here</a></font>"
        31
        46631
        0
        ""
        ""
        ""
        []
    )

data AccountInfo =
    HasAccount String Bool
    | Guest
    | Admin
    deriving (Show, Read)

data DBQuery =
    CheckAccount Int String String
    | ClearCache
    | SendStats Int Int
    deriving (Show, Read)

data CoreMessage =
    Accept ClientInfo
    | ClientMessage (Int, [String])
    | ClientAccountInfo (Int, AccountInfo)
    | TimerAction Int

type MRnC = MRoomsAndClients RoomInfo ClientInfo
type IRnC = IRoomsAndClients RoomInfo ClientInfo

--type ClientsTransform = [ClientInfo] -> [ClientInfo]
--type RoomsTransform = [RoomInfo] -> [RoomInfo]
--type HandlesSelector = ClientInfo -> [ClientInfo] -> [RoomInfo] -> [ClientInfo]
--type Answer = ServerInfo -> (HandlesSelector, [String])

--type ClientsSelector = Clients -> Rooms -> [Int]
