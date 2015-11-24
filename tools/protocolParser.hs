module Main where

import Text.PrettyPrint.HughesPJ
import qualified Data.MultiMap as MM
import Data.Maybe
import Data.List
import Data.Char
import qualified Data.Set as Set

data HWProtocol = Command String [CmdParam]
    deriving Show

instance Ord HWProtocol where
    (Command a _) `compare` (Command b _) = a `compare` b    
instance Eq HWProtocol where
    (Command a _) == (Command b _) = a == b

data CmdParam = Skip
              | SS
              | LS
              | IntP
              | Many [CmdParam]
    deriving Show

data ParseTree = PTPrefix String [ParseTree]
               | PTCommand String HWProtocol
    deriving Show

cmd = Command
cmd1 s p = Command s [p]
cmd2 s p1 p2 = Command s [p1, p2]

cmdName (Command n _) = n

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
        , cmd1 "ROOM~ADD" $ Many [SS]
        , cmd1 "ROOM~UPD" $ Many [SS]
        , cmd1 "ROOM~DEL" SS
        , cmd1 "ROOMS" $ Many [SS]
        , cmd "KICKED" []
        , cmd "RUN_GAME" []
        , cmd "ROUND_FINISHED" []
        , cmd1 "ADD_TEAM" $ Many [SS]
        , cmd1 "REMOVE_TEAM" SS
        , cmd1 "CFG~MAP" SS
        , cmd1 "CFG~SEED" SS
        , cmd1 "CFG~THEME" SS
        , cmd1 "CFG~TEMPLATE" IntP
        , cmd1 "CFG~MAPGEN" IntP
        , cmd1 "CFG~FEATURE_SIZE" IntP
        , cmd1 "CFG~MAZE_SIZE" IntP
        , cmd1 "CFG~SCRIPT" SS
        , cmd1 "CFG~DRAWNMAP" LS
        , cmd2 "CFG~AMMO" SS LS
        , cmd1 "FULLMAPCONFIG" $ Many [LS]
    ]

hasMany = any isMany
isMany (Many _) = True
isMany _ = False

unknown = Command "__UNKNOWN__" [Many [SS]]
unknowncmd = PTPrefix "$" [PTCommand "$" $ unknown]

fixName = map fixChar
fixChar c | isLetter c = c
          | otherwise = '_'

groupByFirstChar :: [ParseTree] -> [(Char, [ParseTree])]
groupByFirstChar = MM.assocs . MM.fromList . map breakCmd
    where
    breakCmd (PTCommand (c:cs) params) = (c, PTCommand cs params)

makePT cmd@(Command n p) = PTCommand n cmd

buildParseTree cmds = [PTPrefix "!" $ (bpt $ map makePT cmds) ++ [unknowncmd]]

bpt :: [ParseTree] -> [ParseTree]
bpt cmds = cmdLeaf emptyNamed
    where
        emptyNamed = partition (\(_, (PTCommand n _:_)) -> null n) $ groupByFirstChar cmds
        buildsub :: (Char, [ParseTree]) -> [ParseTree] -> ParseTree
        buildsub (c, cmds) pc = let st = (bpt cmds) ++ pc in if null $ drop 1 st then maybeMerge c st else PTPrefix [c] st
        buildsub' = flip buildsub []
        cmdLeaf ([], assocs) = map buildsub' assocs
        cmdLeaf ([(c, hwc:assocs1)], assocs2)
            | null assocs1 = PTPrefix [c] [hwc] : map buildsub' assocs2
            | otherwise = (buildsub (c, assocs1) [hwc]) : map buildsub' assocs2

        maybeMerge c cmd@[PTCommand {}] = PTPrefix [c] cmd
        maybeMerge c cmd@[PTPrefix s ss] = PTPrefix (c:s) ss
        maybeMerge c [] = PTPrefix [c] []
        
dumpTree = vcat . map dt
    where
    dt (PTPrefix s st) = text s $$ (nest (length s) $ vcat $ map dt st)
    dt _ = char '$'

renderArrays (letters, commands, handlers) = vcat $ punctuate (char '\n') [grr, cmds, l, s, c, bodies, structs, realHandlers, realHandlersArray]
    where
        maybeQuotes "$" = text "#0"
        maybeQuotes "~" = text "#10"
        maybeQuotes s = if null $ tail s then quotes $ text s else text s
        l = text "const letters: array[0.." <> (int $ length letters - 1) <> text "] of char = "
            <> parens (hsep . punctuate comma $ map maybeQuotes letters) <> semi
        s = text "const commands: array[0.." <> (int $ length commands - 1) <> text "] of integer = "
            <> parens (hsep . punctuate comma $ map text commands) <> semi
        c = text "const handlers: array[0.." <> (int $ length fixedNames - 1) <> text "] of PHandler = "
            <> parens (hsep . punctuate comma $ map (text . (:) '@') handlerTypes) <> semi
        grr = text "const net2cmd: array[0.." <> (int $ length fixedNames - 1) <> text "] of TCmdType = "
            <> parens (hsep . punctuate comma $ map (text . (++) "cmd_") $ reverse fixedNames) <> semi
        handlerTypes = map cmdParams2handlerType $ reverse sortedCmdDescriptions
        sortedCmdDescriptions = sort commandsDescription
        fixedNames = map fixName handlers
        bodies = vcat $ punctuate (char '\n') $ map handlerBody $ nub $ sort handlerTypes
        handlerBody n = text "procedure " <> text n <> semi
            $+$ text "begin"
            $+$ text "end" <> semi
        cmds = text "type TCmdType = " <> parens (hsep $ punctuate comma $ concatMap (rhentry "cmd_") $ sortedCmdDescriptions) <> semi
        structs = vcat (map text . Set.toList . Set.fromList $ map cmdParams2record commandsDescription)
        realHandlers = vcat $ punctuate (char '\n') $ map rh $ sortedCmdDescriptions
        realHandlersArray = text "const handlers: array[TCmdType] of PHandler = "
            <> parens (hsep . punctuate comma . concatMap (map ((<>) (text "PHandler") . parens) . rhentry "@handler_") $ sortedCmdDescriptions) <> semi

rh cmd@(Command n p) = text "procedure handler_" <> text (fixName n) <> parens (text "var p: " <> text (cmdParams2str cmd)) <> semi
    $+$ emptyBody $+$ if hasMany p then vcat [space, text "procedure handler_" <> text (fixName n) <> text "_s" <> parens (text "var s: TCmdParamS") <> semi
    , emptyBody] else empty
    where
        emptyBody = text "begin"  $+$ text "end" <> semi

rhentry prefix cmd@(Command n p) = (text . (++) prefix . fixName . cmdName $ cmd)
    : if hasMany p then [text . flip (++) "_s" . (++) prefix . fixName . cmdName $ cmd] else []

pas = renderArrays $ buildTables $ buildParseTree commandsDescription
    where
        buildTables cmds = let (_, _, _, t1, t2, t3) = foldr walk (0, [0], -10, [], [], [[]]) cmds in (tail t1, tail t2, concat t3)
        walk (PTCommand _ (Command n params)) (lc, s:sh, pc, tbl1, tbl2, (t3:tbl3)) =
            (lc, 1:sh, pc - 1, "#10":tbl1, show pc:tbl2, (n:t3):tbl3)
        walk (PTPrefix prefix cmds) l = lvldown $ foldr fpf (foldr walk (lvlup l) cmds) prefix
        lvlup (lc, sh, pc, tbl1, tbl2, tbl3) = (lc, 0:sh, pc, tbl1, tbl2, []:tbl3)
        lvldown (lc, s1:s2:sh, pc, tbl1, t:tbl2, t31:t32:tbl3) = (lc, s1+s2:sh, pc, tbl1, (if null t32 then "0" else show s1):tbl2, (t31 ++ t32):tbl3)
        fpf c (lc, s:sh, pc, tbl1, tbl2, tbl3) = (lc + 1, s+1:sh, pc, [c]:tbl1, "0":tbl2, tbl3)

main = do
    putStrLn $ renderStyle style{mode = ZigZagMode, lineLength = 80} $ pas
    --putStrLn $ renderStyle style{lineLength = 80} $ dumpTree $ buildParseTree commandsDescription
