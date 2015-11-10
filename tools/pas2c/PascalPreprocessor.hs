{-# LANGUAGE ScopedTypeVariables #-}
module PascalPreprocessor where

import Text.Parsec
import Control.Monad.IO.Class
import Control.Monad
import System.IO
import qualified Data.Map as Map
import qualified Control.Exception as E

char' :: Char -> ParsecT String u IO ()
char' = void . char

string' :: String -> ParsecT String u IO ()
string' = void . string

-- comments are removed
comment :: ParsecT String u IO String
comment = choice [
        char '{' >> notFollowedBy (char '$') >> manyTill anyChar (try $ char '}') >> return ""
        , (try $ string "(*") >> manyTill anyChar (try $ string "*)") >> return ""
        , (try $ string "//") >> manyTill anyChar (try newline) >> return "\n"
        ]

preprocess :: String -> String -> String -> [String] -> IO String
preprocess inputPath alternateInputPath fn symbols = do
    r <- runParserT (preprocessFile (inputPath ++ fn)) (Map.fromList $ map (\s -> (s, "")) symbols, [True]) "" ""
    case r of
         (Left a) -> do
             hPutStrLn stderr (show a)
             return ""
         (Right a) -> return a

    where
    preprocessFile fn' = do
        f <- liftIO (readFile fn')
        setInput f
        preprocessor

    preprocessor, codeBlock, switch :: ParsecT String (Map.Map String String, [Bool]) IO String

    preprocessor = chainr codeBlock (return (++)) ""

    codeBlock = do
        s <- choice [
            switch
            , comment
            , char '\'' >> many (noneOf "'\n") >>= \s -> char '\'' >> return ('\'' : s ++ "'")
            , identifier >>= replace
            , noneOf "{" >>= \a -> return [a]
            ]
        (_, ok) <- getState
        return $ if and ok then s else ""

    --otherChar c = c `notElem` "{/('_" && not (isAlphaNum c)
    identifier = do
        c <- letter <|> oneOf "_"
        s <- many (alphaNum <|> oneOf "_")
        return $ c:s

    switch = do
        try $ string' "{$"
        s <- choice [
            include
            , ifdef
            , if'
            , elseSwitch
            , endIf
            , define
            , unknown
            ]
        return s

    include = do
        try $ string' "INCLUDE"
        spaces
        (char' '"')
        ifn <- many1 $ noneOf "\"\n"
        char' '"'
        spaces
        char' '}'
        f <- liftIO (readFile (inputPath ++ ifn) 
            `E.catch` (\(_ :: E.IOException) -> readFile (alternateInputPath ++ ifn) 
                `E.catch` (\(_ :: E.IOException) -> error $ "File not found: " ++ ifn)
                )
            )
        c <- getInput
        setInput $ f ++ c
        return ""

    ifdef = do
        s <- try (string "IFDEF") <|> try (string "IFNDEF")
        let f = if s == "IFNDEF" then not else id

        ds <- (spaces >> identifier) `sepBy` (spaces >> string "OR")
        spaces
        char' '}'

        updateState $ \(m, b) ->
            (m, (f $ any (flip Map.member m) ds) : b)

        return ""

    if' = do
        try (string' "IF" >> notFollowedBy alphaNum)

        void $ manyTill anyChar (char' '}')
        --char '}'

        updateState $ \(m, b) ->
            (m, False : b)

        return ""

    elseSwitch = do
        try $ string' "ELSE}"
        updateState $ \(m, b:bs) -> (m, (not b):bs)
        return ""
    endIf = do
        try $ string' "ENDIF}"
        updateState $ \(m, _:bs) -> (m, bs)
        return ""
    define = do
        try $ string' "DEFINE"
        spaces
        i <- identifier
        d <- ((string ":=" >> return ()) <|> spaces) >> many (noneOf "}")
        char' '}'
        updateState $ \(m, b) -> (if (and b) && (head i /= '_') then Map.insert i d m else m, b)
        return ""
    replace s = do
        (m, _) <- getState
        return $ Map.findWithDefault s s m

    unknown = do
        un <- many1 $ noneOf "}\n"
        char' '}'
        return $ "{$" ++ un ++ "}"
