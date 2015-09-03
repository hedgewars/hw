module Main where

import Text.PrettyPrint.HughesPJ
import qualified Data.MultiMap as MM
import Data.Maybe
import Data.List
import Data.Char
import qualified Data.Set as Set

data HWProtocol = Command String [CmdParam]

instance Ord HWProtocol where
    (Command a _) `compare` (Command b _) = a `compare` b    
instance Eq HWProtocol where
    (Command a _) == (Command b _) = a == b

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
               | PTCommand String HWProtocol

cmd = Command
cmd1 s p = Command s [p]
cmd2 s p1 p2 = Command s [p1, p2]

cmdParams2str (Command _ p) = "TCmdParam" ++ concatMap f p
    where
    f Skip = ""
    f SS = "S"
    f LS = "L"
    f IntP = "i"
    f (Many p) = ""

cmdParams2handlerType (Command _ p) = "handler_" ++ concatMap f p
    where
    f Skip = "_"
    f SS = "S"
    f LS = "L"
    f IntP = "i"
    f (Many p) = 'M' : concatMap f p

cmdParams2record cmd@(Command _ p) = renderStyle style{lineLength = 80} $ 
    text "type " <> text (cmdParams2str cmd)
    <> text " = record" $+$ nest 4 (
    vcat (map (uncurry f) $ zip [1..] $ filter isRendered p) 
    $+$ text "end;")
    where
    isRendered Skip = False
    isRendered (Many _) = False
    isRendered _ = True
    f n Skip = empty
    f n SS = text "str" <> int n <> text ": shortstring;"
    f n LS = text "str" <> int n <> text ": longstring;"
    f n IntP = text "param" <> int n <> text ": LongInt;"
    f _ (Many _) = empty

commandsDescription = [
        cmd "CONNECTED" [Skip, IntP]
        , cmd1 "NICK" SS
        , cmd1 "PROTO" IntP
        , cmd1 "ASKPASSWORD" SS
        , cmd1 "SERVER_AUTH" SS
        , cmd1 "JOINING" SS
        , cmd1 "TEAM_ACCEPTED" SS
        , cmd1 "HH_NUM" $ Many [SS]
        , cmd1 "TEAM_COLOR" $ Many [SS]
        , cmd1 "TEAM_ACCEPTED" SS
        , cmd1 "BANLIST" $ Many [SS]
        , cmd1 "JOINED" $ Many [SS]
        , cmd1 "LOBBY:JOINED" $ Many [SS]
        , cmd2 "LOBBY:LEFT" SS LS
        , cmd2 "CLIENT_FLAGS" SS $ Many [SS]
        , cmd2 "LEFT" SS $ Many [SS]
        , cmd1 "SERVER_MESSAGE" LS
        , cmd1 "ERROR" LS
        , cmd1 "NOTICE" LS
        , cmd1 "WARNING" LS
        , cmd1 "EM" $ Many [LS]
        , cmd1 "PING" $ Many [SS]
        , cmd2 "CHAT" SS LS
        , cmd2 "SERVER_VARS" SS LS
        , cmd2 "BYE" SS LS
        , cmd1 "INFO" $ Many [SS]
        , cmd1 "ROOMS" $ Many [SS]
        , cmd "KICKED" []
        , cmd "RUN_GAME" []
        , cmd "ROUND_FINISHED" []
    ]

unknowncmd = PTPrefix "$" [PTCommand "$" $ Command "__UNKNOWN__" [Many [SS]]]

groupByFirstChar :: [ParseTree] -> [(Char, [ParseTree])]
groupByFirstChar = MM.assocs . MM.fromList . map breakCmd
    where
    breakCmd (PTCommand (c:cs) params) = (c, PTCommand cs params)

makePT cmd@(Command n p) = PTCommand n cmd

buildParseTree cmds = [PTPrefix "!" $ (bpt $ map makePT cmds) ++ [unknowncmd]]
bpt cmds = if not . null $ fst emptyNamed then cmdLeaf emptyNamed else subtree
    where
        emptyNamed = partition (\(_, (PTCommand n _:_)) -> null n) assocs
        assocs = groupByFirstChar cmds
        subtree = map buildsub assocs
        buildsub (c, cmds) = let st = bpt cmds in if null $ drop 1 st then maybeMerge c st else PTPrefix [c] st
        maybeMerge c cmd@[PTCommand {}] = PTPrefix [c] cmd
        maybeMerge c cmd@[PTPrefix s ss] = PTPrefix (c:s) ss
        cmdLeaf ([(c, (hwc:_))], assocs2) = (PTPrefix [c] [hwc]) : map buildsub assocs2

dumpTree = vcat . map dt
    where
    dt (PTPrefix s st) = text s $$ (nest 1 $ vcat $ map dt st)
    dt _ = empty

pas2 = buildSwitch $ buildParseTree commandsDescription
    where
        buildSwitch cmds = text "case getNextChar of" $$ (nest 4 . vcat $ map buildCase cmds) $$ elsePart
        buildCase (PTCommand {}) = text "#10: <call cmd handler>;"
        buildCase (PTPrefix (s:ss) cmds) = quotes (char s) <> text ": " <> consumePrefix ss (buildSwitch cmds)
        consumePrefix "" = id
        consumePrefix str = (text "consume" <> (parens . quotes $ text str) <> semi $$)
        zeroChar = text "#0: state:= pstDisconnected;"
        elsePart = text "else <unknown cmd> end;"

renderArrays (letters, commands, handlers) = vcat $ punctuate (char '\n') [cmds, l, s, {-bodies, -}c, structs, realHandlers]
    where
        maybeQuotes "$" = text "#0"
        maybeQuotes s = if null $ tail s then quotes $ text s else text s
        l = text "const letters: array[0.." <> (int $ length letters - 1) <> text "] of char = "
            <> parens (hsep . punctuate comma $ map maybeQuotes letters) <> semi
        s = text "const commands: array[0.." <> (int $ length commands - 1) <> text "] of integer = "
            <> parens (hsep . punctuate comma $ map text commands) <> semi
        c = text "const handlers: array[0.." <> (int $ length fixedNames - 1) <> text "] of PHandler = "
            <> parens (hsep . punctuate comma $ map (text . (:) '@') handlerTypes) <> semi
        handlerTypes = map cmdParams2handlerType sortedCmdDescriptions
        sortedCmdDescriptions = reverse $ sort commandsDescription
        fixedNames = map fixName handlers
        fixName = map fixChar
        fixChar c | isLetter c = c
                  | otherwise = '_'
        bodies = vcat $ punctuate (char '\n') $ map handlerBody fixedNames
        handlerBody n = text "procedure handler_" <> text n <> semi
            $+$ text "begin" 
            $+$ text "end" <> semi
        cmds = text "type TCmdType = " <> parens (hsep $ punctuate comma $ map ((<>) (text "cmd_") . text) $ reverse fixedNames) <> semi
        structs = vcat (map text . Set.toList . Set.fromList $ map cmdParams2record commandsDescription)
        realHandlers = vcat $ punctuate (char '\n') $ map rh sortedCmdDescriptions
        rh cmd@(Command n _) = text "procedure handler_" <> text (fixName n) <> parens (text "var p: " <> text (cmdParams2str cmd)) <> semi
            $+$ text "begin" 
            $+$ text "end" <> semi

pas = renderArrays $ buildTables $ buildParseTree commandsDescription
    where
        buildTables cmds = let (_, _, _, t1, t2, t3) = foldr walk (0, [0], -10, [], [], [[]]) cmds in (tail t1, tail t2, concat t3)
        walk (PTCommand _ (Command n params)) (lc, s:sh, pc, tbl1, tbl2, (t3:tbl3)) =
            (lc, 1:sh, pc - 1, "#10":tbl1, show pc:tbl2, (n:t3):tbl3)
        walk (PTPrefix prefix cmds) l = lvldown $ foldr fpf (foldr walk (lvlup l) cmds) prefix
        lvlup (lc, sh, pc, tbl1, tbl2, tbl3) = (lc, 0:sh, pc, tbl1, tbl2, []:tbl3)
        lvldown (lc, s1:s2:sh, pc, tbl1, t:tbl2, t31:t32:tbl3) = (lc, s1+s2:sh, pc, tbl1, (if null t32 then "0" else show s1):tbl2, (t31 ++ t32):tbl3)
        fpf c (lc, s:sh, pc, tbl1, tbl2, tbl3) = (lc + 1, s+1:sh, pc, [c]:tbl1, "0":tbl2, tbl3)

main =
    putStrLn $ renderStyle style{lineLength = 80} $ pas
    --putStrLn $ renderStyle style{lineLength = 80} $ dumpTree $ buildParseTree commandsDescription
