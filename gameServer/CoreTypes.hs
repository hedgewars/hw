module CoreTypes where

import System.IO
import Control.Concurrent.Chan
import Control.Concurrent.STM
import Data.Word
import qualified Data.Map as Map
import qualified Data.IntMap as IntMap
import qualified Data.IntSet as IntSet
import Data.Sequence(Seq, empty)
import Network


data ClientInfo =
 ClientInfo
	{
		clientUID :: Int,
		sendChan :: Chan [String],
		clientHandle :: Handle,
		host :: String,
		nick :: String,
		clientProto :: Word16,
		roomID :: Int,
		isMaster :: Bool,
		isReady :: Bool,
		forceQuit :: Bool,
		partRoom :: Bool
	}

instance Show ClientInfo where
	show ci = show $ clientUID ci

instance Eq ClientInfo where
	a1 == a2 = clientHandle a1 == clientHandle a2

data HedgehogInfo =
	HedgehogInfo String String

data TeamInfo =
	TeamInfo
	{
		teamowner :: String,
		teamname :: String,
		teamcolor :: String,
		teamgrave :: String,
		teamfort :: String,
		teamvoicepack :: String,
		difficulty :: Int,
		hhnum :: Int,
		hedgehogs :: [HedgehogInfo]
	}

data RoomInfo =
	RoomInfo
	{
		roomUID :: Int,
		name :: String,
		password :: String,
		roomProto :: Word16,
		teams :: [TeamInfo],
		gameinprogress :: Bool,
		playersIn :: !Int,
		readyPlayers :: Int,
		playersIDs :: IntSet.IntSet,
		isRestrictedJoins :: Bool,
		isRestrictedTeams :: Bool,
		roundMsgs :: Seq String,
		leftTeams :: [String],
		teamsAtStart :: [TeamInfo],
		params :: Map.Map String [String]
	}

instance Show RoomInfo where
	show ri = (show $ roomUID ri)
			++ ", players ids: " ++ (show $ IntSet.size $ playersIDs ri)
			++ ", players: " ++ (show $ playersIn ri)
			++ ", ready: " ++ (show $ readyPlayers ri)

instance Eq RoomInfo where
	a1 == a2 = roomUID a1 == roomUID a2

newRoom = (
	RoomInfo
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
		listenPort :: PortNumber,
		loginsNumber :: Int,
		nextRoomID :: Int,
		dbHost :: String,
		dbLogin :: String,
		dbPassword :: String,
		stats :: TMVar StatisticsInfo,
		coreChan :: Chan CoreMessage,
		dbQueries :: Chan DBQuery
	}

instance Show ServerInfo where
	show si = "Logins: " ++ (show $ loginsNumber si)

newServerInfo = (
	ServerInfo
		True
		"<h2><p align=center><a href=\"http://www.hedgewars.org/\">http://www.hedgewars.org/</a></p></h2>"
		46631
		0
		0
		""
		""
		""
	)

data AccountInfo =
	HasAccount
	| LogonPassed
	| Guest

data CoreMessage =
	Accept ClientInfo
	| ClientMessage (Int, [String])
	| ClientAccountInfo Int AccountInfo
	-- | CoreMessage String
	-- | TimerTick

data DBQuery =
	CheckAccount Int String
	| CheckPassword String


type Clients = IntMap.IntMap ClientInfo
type Rooms = IntMap.IntMap RoomInfo

--type ClientsTransform = [ClientInfo] -> [ClientInfo]
--type RoomsTransform = [RoomInfo] -> [RoomInfo]
--type HandlesSelector = ClientInfo -> [ClientInfo] -> [RoomInfo] -> [ClientInfo]
--type Answer = ServerInfo -> (HandlesSelector, [String])

type ClientsSelector = Clients -> Rooms -> [Int]
