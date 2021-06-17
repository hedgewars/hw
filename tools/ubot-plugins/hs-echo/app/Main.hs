{-# LANGUAGE OverloadedStrings #-}
module Main where

import Text.Megaparsec (Parsec, parseMaybe)
import Text.URI
import System.Environment (getEnv)
import Data.Text (Text, pack, unpack)
import Data.Maybe
import Control.Monad (when)
import Network.AMQP
import qualified Data.ByteString.Lazy.Char8 as BL

assert :: String -> Bool -> a -> a
assert message False x = error message
assert _ _ x = x

unRpack = unpack . unRText

main :: IO ()
main = do
    amqpUri <- getEnv "AMQP_URL"
    let uri = fromJust $ parseMaybe (parser :: Parsec Int Text URI) $ pack amqpUri
    when (uriScheme uri /= mkScheme "amqp") $ error "AMQP_URL environment variable scheme should be amqp"
    let Right (Authority (Just (UserInfo username (Just password))) rHost maybePort) = uriAuthority uri
 
    conn <- openConnection' (unRpack rHost) (fromInteger . toInteger $ fromMaybe 5672 maybePort) "/" (unRText username) (unRText password)
    chan <- openChannel conn

    (queueName, messageCount, consumerCount) <- declareQueue chan newQueue
    bindQueue chan queueName "irc" "cmd.echo.hedgewars"

    -- subscribe to the queue
    consumeMsgs chan queueName Ack (myCallback chan)

    getLine -- wait for keypress
    closeConnection conn
    putStrLn "connection closed"


myCallback :: Channel -> (Message,Envelope) -> IO ()
myCallback chan (msg, env) = do
    let message = BL.tail . BL.dropWhile (/= '\n') $ msgBody msg
    putStrLn $ "received message: " ++ (BL.unpack $ message)

    publishMsg chan "irc" "say.hedgewars"
        newMsg {msgBody = message}

    ackEnv env