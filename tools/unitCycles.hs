module Main where

import PascalParser
import System
import Control.Monad
import Data.Either
import Data.List

unident :: Identificator -> String
unident (Identificator s) = s

extractUnits :: PascalUnit -> (String, [String])
extractUnits (Program (Identificator name) (Implementation (Uses idents) _ _) _) = ("program " ++ name, map unident idents)
extractUnits (Unit (Identificator name) (Interface (Uses idents1) _) (Implementation (Uses idents2) _ _) _ _) = (name, map unident $ idents1 ++ idents2)

main = do
    fileNames <- getArgs
    files <- mapM readFile fileNames
    mapM_ (putStrLn . show . extractUnits) . rights . map parsePascalUnit $ files
