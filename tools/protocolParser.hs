module Main where

import Text.PrettyPrint.HughesPJ

data HWProtocol = Command String [CmdParam]
data CmdParam = Skip
              | SS
              | LS
              | IntP
              | Many [CmdParam]
data ClientStates = NotConnected
                  | JustConnected
                  | ServerAuth
                  | Lobby

data ParseTree = PTChar Char [ParseTree]
               | PTCommand HWProtocol

cmd = Command
cmd1 s p = Command s [p]
cmd2 s p1 p2 = Command s [p1, p2]

breakCmd (Command (c:cs) params) = (c, Command cs params)

commands = [
        cmd "CONNECTED" [Skip, IntP]
        , cmd1 "NICK" SS
        , cmd1 "PROTO" IntP
        , cmd1 "ASKPASSWORD" SS
        , cmd1 "SERVER_AUTH" SS
        , cmd1 "LOBBY:JOINED" $ Many [SS]
        , cmd2 "LOBBY:LEFT" $ SS SS
        , cmd2 "CLIENT_FLAGS" $ SS $ Many [SS]
        , cmd1 "SERVER_MESSAGE" LS
    ]



pas = 
    
main = putStrLn $ render pas
