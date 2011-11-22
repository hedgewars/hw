module PascalPreprocessor where

import Text.Parsec
import Control.Monad.IO.Class
import System.IO
import qualified Data.Map as Map


-- comments are removed
comment = choice [
        char '{' >> notFollowedBy (char '$') >> manyTill anyChar (try $ char '}') >> return ""
        , (try $ string "(*") >> manyTill anyChar (try $ string "*)") >> return ""
        , (try $ string "//") >> manyTill anyChar (try newline) >> return "\n"
        ]

preprocess :: String -> IO String
preprocess fn = do
    r <- runParserT (preprocessFile fn) Map.empty "" ""
    case r of
         (Left a) -> do
             hPutStrLn stderr (show a)
             return ""
         (Right a) -> return a
    
    where
    preprocessFile :: String -> ParsecT String (Map.Map String String) IO String
    preprocessFile fn = do
        f <- liftIO (readFile fn)
        setInput f
        preprocessor
        
    preprocessor, codeBlock, switch :: ParsecT String (Map.Map String String) IO String
    
    preprocessor = chainl codeBlock (return (++)) ""
    
    codeBlock = choice [
            switch
            , comment
            , char '\'' >> many (noneOf "'") >>= \s -> char '\'' >> return ('\'' : s ++ "'")
            , many1 $ noneOf "{'/("
            , char '/' >> notFollowedBy (char '/') >> return "/"
            , char '(' >> notFollowedBy (char '*') >> return "("
            ]
            
    switch = do
        try $ string "{$"
        s <- choice [
            include
            , unknown
            ]
        return s
        
    include = do
        try $ string "INCLUDE"
        spaces
        (char '"')
        fn <- many1 $ noneOf "\"\n"
        char '"'
        spaces
        char '}'
        f <- liftIO (readFile fn)
        c <- getInput
        setInput $ f ++ c
        return ""

    unknown = do
        fn <- many1 $ noneOf "}\n"
        char '}'
        return ""
        