{-# LANGUAGE OverloadedStrings #-}
module CoreTypes where

import System.IO
import Control.Concurrent.Chan
import Control.Concurrent.STM
import Data.Word
import qualified Data.Map as Map
import qualified Data.IntSet as IntSet
import Data.Sequence(Seq, empty)
import Data.Time
import Network
import Data.Function
import Data.ByteString.Char8 as B

import RoomsAndClients

type ClientChan = Chan [B.ByteString]

data ClientInfo =
    ClientInfo
    {
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
        isAdministrator :: Bool,
        clientClan :: B.ByteString,
        teamsInGame :: Word
    }

instance Show ClientInfo where
    show ci = " nick: " ++ (unpack $ nick ci) ++ " host: " ++ (unpack $ host ci)

instance Eq ClientInfo where
    (==) = (==) `on` clientSocket

data HedgehogInfo =
    HedgehogInfo B.ByteString B.ByteString

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

instance Show TeamInfo where
    show ti = "owner: " ++ (unpack $ teamowner ti)
            ++ "name: " ++ (unpack $ teamname ti)
            ++ "color: " ++ (unpack $ teamcolor ti)

data RoomInfo =
    RoomInfo
    {
        masterID :: ClientIndex,
        name :: B.ByteString,
        password :: B.ByteString,
        roomProto :: Word16,
        teams :: [TeamInfo],
        gameinprogress :: Bool,
        playersIn :: !Int,
        readyPlayers :: !Int,
        playersIDs :: IntSet.IntSet,
        isRestrictedJoins :: Bool,
        isRestrictedTeams :: Bool,
        roundMsgs :: Seq B.ByteString,
        leftTeams :: [B.ByteString],
        teamsAtStart :: [TeamInfo],
        params :: Map.Map B.ByteString [B.ByteString]
    }

instance Show RoomInfo where
    show ri = ", players ids: " ++ show (IntSet.size $ playersIDs ri)
            ++ ", players: " ++ show (playersIn ri)
            ++ ", ready: " ++ show (readyPlayers ri)
            ++ ", teams: " ++ show (teams ri)

newRoom :: RoomInfo
newRoom = (
    RoomInfo
        undefined
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
        serverMessage :: B.ByteString,
        serverMessageForOldVersions :: B.ByteString,
        latestReleaseVersion :: Word16,
        listenPort :: PortNumber,
        nextRoomID :: Int,
        dbHost :: B.ByteString,
        dbLogin :: B.ByteString,
        dbPassword :: B.ByteString,
        lastLogins :: [(B.ByteString, UTCTime)],
        stats :: TMVar StatisticsInfo,
        coreChan :: Chan CoreMessage,
        dbQueries :: Chan DBQuery
    }

instance Show ServerInfo where
    show _ = "Server Info"

newServerInfo :: TMVar StatisticsInfo -> Chan CoreMessage -> Chan DBQuery -> ServerInfo
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
    HasAccount B.ByteString Bool
    | Guest
    | Admin
    deriving (Show, Read)

data DBQuery =
    CheckAccount ClientIndex B.ByteString B.ByteString
    | ClearCache
    | SendStats Int Int
    deriving (Show, Read)

data CoreMessage =
    Accept ClientInfo
    | ClientMessage (ClientIndex, [B.ByteString])
    | ClientAccountInfo (ClientIndex, AccountInfo)
    | TimerAction Int
    | Remove ClientIndex

instance Show CoreMessage where
    show (Accept _) = "Accept"
    show (ClientMessage _) = "ClientMessage"
    show (ClientAccountInfo _) = "ClientAccountInfo"
    show (TimerAction _) = "TimerAction"
    show (Remove _) = "Remove"
    
type MRnC = MRoomsAndClients RoomInfo ClientInfo
type IRnC = IRoomsAndClients RoomInfo ClientInfo

