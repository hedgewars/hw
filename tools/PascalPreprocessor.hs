module PascalPreprocessor where

import Text.Parsec
import Control.Monad.IO.Class
import Control.Monad
import System.IO
import qualified Data.Map as Map
import Data.Char


-- comments are removed
comment = choice [
        char '{' >> notFollowedBy (char '$') >> manyTill anyChar (try $ char '}') >> return ""
        , (try $ string "(*") >> manyTill anyChar (try $ string "*)") >> return ""
        , (try $ string "//") >> manyTill anyChar (try newline) >> return "\n"
        ]

initDefines = Map.fromList [
    ("FPC", "")
    , ("PAS2C", "")
    ]

preprocess :: String -> IO String
preprocess fn = do
    r <- runParserT (preprocessFile fn) (initDefines, [True]) "" ""
    case r of
         (Left a) -> do
             hPutStrLn stderr (show a)
             return ""
         (Right a) -> return a

    where
    preprocessFile fn = do
        f <- liftIO (readFile fn)
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
        try $ string "{$"
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
        try $ string "INCLUDE"
        spaces
        (char '"')
        fn <- many1 $ noneOf "\"\n"
        char '"'
        spaces
        char '}'
        f <- liftIO (readFile fn `catch` error ("File not found: " ++ fn))
        c <- getInput
        setInput $ f ++ c
        return ""

    ifdef = do
        s <- try (string "IFDEF") <|> try (string "IFNDEF")
        let f = if s == "IFNDEF" then not else id

        spaces
        d <- identifier
        spaces
        char '}'

        updateState $ \(m, b) ->
            (m, (f $ d `Map.member` m) : b)

        return ""

    if' = do
        s <- try (string "IF" >> notFollowedBy alphaNum)

        manyTill anyChar (char '}')
        --char '}'

        updateState $ \(m, b) ->
            (m, False : b)

        return ""

    elseSwitch = do
        try $ string "ELSE}"
        updateState $ \(m, b:bs) -> (m, (not b):bs)
        return ""
    endIf = do
        try $ string "ENDIF}"
        updateState $ \(m, b:bs) -> (m, bs)
        return ""
    define = do
        try $ string "DEFINE"
        spaces
        i <- identifier
        d <- ((string ":=" >> return ())<|> spaces) >> many (noneOf "}")
        char '}'
        updateState $ \(m, b) -> (if (and b) && (head i /= '_') then Map.insert i d m else m, b)
        return ""
    replace s = do
        (m, _) <- getState
        return $ Map.findWithDefault s s m

    unknown = do
        fn <- many1 $ noneOf "}\n"
        char '}'
        return $ "{$" ++ fn ++ "}"
