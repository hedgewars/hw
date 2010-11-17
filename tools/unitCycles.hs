module Main where

import PascalParser
import System
import Control.Monad
import Data.Either
import Data.List
import Data.Graph

unident :: Identificator -> String
unident (Identificator s) = s

extractUnits :: PascalUnit -> (String, [String])
extractUnits (Program (Identificator name) (Implementation (Uses idents) _ _) _) = ("program " ++ name, map unident idents)
extractUnits (Unit (Identificator name) (Interface (Uses idents1) _) (Implementation (Uses idents2) _ _) _ _) = (name, map unident $ idents1 ++ idents2)

f :: [(String, [String])] -> String
f = unlines . map showSCC . stronglyConnComp . map (\(a, b) -> (a, a, b))
    where
    showSCC (AcyclicSCC v) = v
    showSCC (CyclicSCC vs) = intercalate ", " vs

main = do
    fileNames <- getArgs
    files <- mapM readFile fileNames
    putStrLn . f . map extractUnits . rights . map parsePascalUnit $ files
