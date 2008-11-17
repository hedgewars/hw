module Main where

import IO
import System.IO
import Control.Concurrent
import Network
import Control.Exception
import Control.Monad
import System.Random

session1 nick room = ["NICK", nick, "", "PROTO", "20", "", "CREATE", room, "", "CHAT_STRING", "Hi", ""]
session2 nick room = ["NICK", nick, "", "PROTO", "20", "",   "JOIN", room, "", "CHAT_STRING", "Hello", ""]

emulateSession sock s = do
	mapM_ (\x -> hPutStrLn sock x >> randomRIO (70000::Int, 120000) >>= threadDelay) s
	hFlush sock
	threadDelay 250000

testing = Control.Exception.handle (\e -> putStrLn $ show e) $ do
	putStrLn "Start"
	sock <- connectTo "127.0.0.1" (PortNumber 46631)

	num1 <- randomRIO (70000::Int, 70100)
	num2 <- randomRIO (70000::Int, 70100)
	num3 <- randomRIO (0::Int, 7)
	num4 <- randomRIO (0::Int, 7)
	let nick1 = show $ num1
	let nick2 = show $ num2
	let room1 = show $ num3
	let room2 = show $ num4
	emulateSession sock $ session1 nick1 room1
	emulateSession sock $ session2 nick2 room2
	emulateSession sock $ session2 nick1 room1
	hClose sock
	putStrLn "Finish"

forks = forever $ do
	delay <- randomRIO (40000::Int, 70000)
	threadDelay delay
	forkIO testing

main = withSocketsDo $ do
	forks