module PascalParser where

import Text.ParserCombinators.Parsec
import Control.Monad

data PascalUnit =
    Program Identificator Implementation FunctionBody
    | Unit Identificator Interface Implementation (Maybe Initialize) (Maybe Finalize)
    deriving Show

data Interface = Interface Uses TypesAndVars
    deriving Show
data Implementation = Implementation Uses TypesAndVars Functions
    deriving Show
data Functions = Functions [Function]
    deriving Show
data Function = Function String
    deriving Show
data Identificator = Identificator String
    deriving Show
data FunctionBody = FunctionBody String
    deriving Show
data TypesAndVars = TypesAndVars String
    deriving Show
data Initialize = Initialize Functions
    deriving Show
data Finalize = Finalize Functions
    deriving Show
data Uses = Uses [Identificator]
    deriving Show

parsePascalUnit :: String -> Either ParseError PascalUnit
parsePascalUnit = parse pascalUnit "unit"
    where
    comments = skipMany (comment >> spaces)
    identificator = do
        spaces
        l <- letter <|> oneOf "_"
        ls <- many (alphaNum <|> oneOf "_")
        spaces
        return $ Identificator (l:ls)

    pascalUnit = do
        spaces
        comments
        u <- choice [program, unit]
        comments
        spaces
        return u

    comment = choice [
            char '{' >> manyTill anyChar (try $ char '}')
            , string "(*" >> manyTill anyChar (try $ string "*)")
            , string "//" >> manyTill anyChar (try newline)
            ]

    unit = do
        name <- unitName
        spaces
        comments
        int <- string "interface" >> interface
        manyTill anyChar (try $ string "implementation")
        spaces
        comments
        impl <- implementation
        return $ Unit name int impl Nothing Nothing
        where
            unitName = between (string "unit") (char ';') identificator

    interface = do
        spaces
        comments
        u <- uses
        return $ Interface u (TypesAndVars "")

    program = do
        name <- programName
        spaces
        comments
        impl <- implementation
        return $ Program name impl (FunctionBody "")
        where
            programName = between (string "program") (char ';') identificator

    implementation = do
        u <- uses
        manyTill anyChar (try $ string "end.")
        return $ Implementation u (TypesAndVars "") (Functions [])

    uses = liftM Uses (option [] u)
        where
            u = do
                string "uses"
                spaces
                u <- (identificator >>= \i -> spaces >> return i) `sepBy1` (char ',' >> spaces)
                char ';'
                spaces
                return u
