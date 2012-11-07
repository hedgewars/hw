module Main( main ) where

import System.Console.GetOpt
import System.Environment
import System.Exit
import System.IO
import Data.Maybe( fromMaybe )
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
          (flags, [],      [])     ->
            if length args == 8 then do
                pas2C (args !! 1) ((args !! 3)++"/") ((args !! 5)++"/") ((args !! 7)++"/")
            else do
                if length args == 6 then do
                    pas2C (args !! 1) ((args !! 3)++"/") ((args !! 5)++"/") "./"
                else do
                    error $ usageInfo header options
          (_,     nonOpts, [])     -> error $ "unrecognized arguments: " ++ unwords nonOpts
          (_,     _,       msgs)   -> error $ usageInfo header options
    where header = "Freepascal to C conversion! Please use -n -i -o -a options in this order.\n"


data Flag = HelpMessage | Name String | Input String | Output String | Alternate String

options :: [OptDescr Flag]
options = [
    Option ['h'] ["help"]      (NoArg HelpMessage)      "print this help message",
    Option ['n'] ["name"]      (ReqArg Name "MAIN")     "name of the main Pascal module",
    Option ['i'] ["input"]     (ReqArg Input "DIR")     "input directory, where .pas files will be read",
    Option ['o'] ["output"]    (ReqArg Output "DIR")    "output directory, where .c/.h files will be written",
    Option ['a'] ["alternate"] (ReqArg Alternate "DIR") "alternate input directory, for out of source builds"
  ]

