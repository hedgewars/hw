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

data ParseTree = PTPrefix String [ParseTree]
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
        , cmd1 "INFO" $ Many [SS]
        , cmd "KICKED" []
    ]

groupByFirstChar :: [HWProtocol] -> [(Char, [HWProtocol])]
groupByFirstChar = MM.assocs . MM.fromList . map breakCmd

buildParseTree cmds = if isJust emptyNamed then cmdLeaf $ fromJust emptyNamed else subtree
    where
        emptyNamed = find (\(_, (Command n _:_)) -> null n) assocs
        assocs = groupByFirstChar cmds
        subtree = map buildsub assocs
        buildsub (c, cmds) = let st = buildParseTree cmds in if null $ drop 1 st then maybeMerge c st else PTPrefix [c] st
        maybeMerge c cmd@[PTCommand _] = PTPrefix [c] cmd
        maybeMerge c cmd@[PTPrefix s ss] = PTPrefix (c:s) ss
        cmdLeaf (c, (hwc:_)) = [PTPrefix [c] [PTCommand hwc]]

dumpTree = vcat . map dt
    where
    dt (PTPrefix s st) = text s $$ (nest 1 $ vcat $ map dt st)
    dt _ = empty

pas2 = buildSwitch $ buildParseTree commands
    where
        buildSwitch cmds = text "case getNextChar of" $$ (nest 4 . vcat $ map buildCase cmds) $$ elsePart
        buildCase (PTCommand _ ) = text "#10: <call cmd handler>;"
        buildCase (PTPrefix (s:ss) cmds) = quotes (char s) <> text ": " <> consumePrefix ss (buildSwitch cmds)
        consumePrefix "" = id
        consumePrefix str = (text "consume" <> (parens . quotes $ text str) <> semi $$)
        zeroChar = text "#0: state:= pstDisconnected;"
        elsePart = text "else <unknown cmd> end;"

pas = text $ show $ buildTables $ buildParseTree commands
    where
        buildTables cmds = let (_, _, t1, t2) = foldl walk (0, 0, [], []) cmds in (reverse t1, reverse t2)
        walk (lc, cc, tbl1, tbl2) (PTCommand _ ) = (lc, cc + 1, ("#10"):tbl1, (show $ -10 - cc):(tbl2))
        walk lct (PTPrefix prefix cmds) = foldl walk (foldl fpf lct prefix) cmds
        fpf (lc, cc, tbl1, tbl2) c = (lc + 1, cc, [c]:tbl1, (show lc):tbl2)

main = putStrLn $ render pas
