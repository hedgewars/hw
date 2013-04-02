module Main( main ) where

import System.Console.GetOpt
import System.Environment
import System.Exit
import System.IO
import Data.Maybe( fromMaybe, isJust, fromJust )
import Data.List (find)
import Control.Monad
import Pas2C

main = do
    args <- getArgs
    if length args == 0
    then do
        name <- getProgName
        hPutStrLn stderr $ usageInfo header options
        exitFailure
    else do
        case getOpt RequireOrder options args of
          (flags, [],      []) | enoughFlags flags -> do
                let m = flag flags isName
                let i = flag flags isInput
                let o = flag flags isOutput
                let a = fromMaybe o $ liftM extractString $ find isAlt flags
                hPutStrLn stdout $ "--------Pas2C Config--------"
                hPutStrLn stdout $ "Main module: " ++ m
                hPutStrLn stdout $ "Input path : " ++ i
                hPutStrLn stdout $ "Output path: " ++ o
                hPutStrLn stdout $ "Altern path: " ++ a
                hPutStrLn stdout $ "----------------------------"
                pas2C m (i++"/") (o++"/") (a++"/")
                hPutStrLn stdout $ "----------------------------"
                      | otherwise ->  error $ usageInfo header options
          (_,     nonOpts, [])     -> error $ "unrecognized arguments: " ++ unwords nonOpts
          (_,     _,       msgs)   -> error $ usageInfo header options
    where 
        header = "Freepascal to C conversion! Please specify -n -i -o options.\n"
        enoughFlags f = and $ map (isJust . flip find f) [isName, isInput, isOutput]
        flag f = extractString . fromJust . flip find f


data Flag = HelpMessage | Name String | Input String | Output String | Alternate String


extractString :: Flag -> String
extractString (Name s) = s
extractString (Input s) = s
extractString (Output s) = s
extractString (Alternate s) = s
extractString _ = undefined

isName, isInput, isOutput, isAlt :: Flag -> Bool
isName (Name _) = True
isName _ = False
isInput (Input _) = True
isInput _ = False
isOutput (Output _) = True
isOutput _ = False
isAlt (Alternate _) = True
isAlt _ = False

options :: [OptDescr Flag]
options = [
    Option ['h'] ["help"]      (NoArg HelpMessage)      "print this help message",
    Option ['n'] ["name"]      (ReqArg Name "MAIN")     "name of the main Pascal module",
    Option ['i'] ["input"]     (ReqArg Input "DIR")     "input directory, where .pas files will be read",
    Option ['o'] ["output"]    (ReqArg Output "DIR")    "output directory, where .c/.h files will be written",
    Option ['a'] ["alternate"] (ReqArg Alternate "DIR") "alternate input directory, for out of source builds"
  ]

