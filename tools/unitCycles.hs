module Main where

import PascalParser
import System
import Control.Monad
import Data.Either
import Data.List
import Data.Graph
import Data.Maybe

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

myf :: [(String, [String])] -> String
myf d = unlines . map (findCycle . fst) $ d
    where
    findCycle :: String -> String
    findCycle searched = searched ++ ": " ++ (intercalate ", " $ fc searched [])
        where
        fc :: String -> [String] -> [String]
        fc curSearch visited = let uses = curSearch `lookup` d; res = dropWhile null . map t $ fromJust uses in if isNothing uses || null res then [] else head res
            where
            t u =
                if u == searched then
                    [u]
                    else
                    if u `elem` visited then
                        []
                        else
                        let chain = fc u (u:visited) in if null chain then [] else u:chain


main = do
    fileNames <- getArgs
    files <- mapM readFile fileNames
    putStrLn . myf . map extractUnits . rights . map parsePascalUnit $ files
