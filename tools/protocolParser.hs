module Main where

import Text.PrettyPrint.HughesPJ
import qualified Data.MultiMap as MM
import Data.Maybe
import Data.List

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
        , cmd1 "JOINING" SS
        , cmd1 "BANLIST" $ Many [SS]
        , cmd1 "JOINED" $ Many [SS]
        , cmd1 "LOBBY:JOINED" $ Many [SS]
        , cmd2 "LOBBY:LEFT" SS LS
        , cmd2 "CLIENT_FLAGS" SS $ Many [SS]
        , cmd2 "LEFT" SS $ Many [SS]
        , cmd1 "SERVER_MESSAGE" LS
        , cmd1 "EM" $ Many [LS]
        , cmd1 "PING" $ Many [SS]
        , cmd2 "CHAT" SS LS
        , cmd2 "SERVER_VARS" SS LS
        , cmd2 "BYE" SS LS
        , cmd "INFO" [SS, SS, SS, SS]
        , cmd "KICKED" []
    ]

groupByFirstChar :: [HWProtocol] -> [(Char, [HWProtocol])]
groupByFirstChar = MM.assocs . MM.fromList . map breakCmd

buildParseTree cmds = if isJust emptyNamed then cmdLeaf $ fromJust emptyNamed else subtree
    where
        emptyNamed = find (\(_, (Command n _:_)) -> null n) assocs
        assocs = groupByFirstChar cmds
        subtree = map (\(c, cmds) -> PTChar c $ buildParseTree cmds) assocs
        cmdLeaf (c, (hwc:_)) = [PTChar c [PTCommand hwc]]

dumpTree (PTChar c st) = char c $$ (nest 2 $ vcat $ map dumpTree st)
dumpTree _ = empty

pas = vcat . map dumpTree $ buildParseTree commands
    
main = putStrLn $ render pas
