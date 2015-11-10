{-# LANGUAGE FlexibleContexts, NoMonomorphismRestriction #-}
module PascalBasics where

import Text.Parsec.Combinator
import Text.Parsec.Char
import Text.Parsec.Prim
import Text.Parsec.Token
import Text.Parsec.Language
import Data.Char
import Control.Monad
import Data.Functor.Identity

char' :: Char -> Parsec String u ()
char' = void . char

string' :: String -> Parsec String u ()
string' = void . string

builtin :: [String]
builtin = ["succ", "pred", "low", "high", "ord", "inc", "dec", "exit", "break", "continue", "length", "copy"]

pascalLanguageDef :: GenLanguageDef String u Identity
pascalLanguageDef
    = emptyDef
    { commentStart   = "(*"
    , commentEnd     = "*)"
    , commentLine    = "//"
    , nestedComments = False
    , identStart     = letter <|> oneOf "_"
    , identLetter    = alphaNum <|> oneOf "_"
    , opLetter       = letter
    , reservedNames  = [
            "begin", "end", "program", "unit", "interface"
            , "implementation", "and", "or", "xor", "shl"
            , "shr", "while", "do", "repeat", "until", "case", "of"
            , "type", "var", "const", "out", "array", "packed"
            , "procedure", "function", "with", "for", "to"
            , "downto", "div", "mod", "record", "set", "nil"
            , "cdecl", "external", "if", "then", "else"
            ] -- ++ builtin
    , caseSensitive  = False
    }

preprocessorSwitch :: Stream String Identity Char => Parsec String u String
preprocessorSwitch = do
    try $ string' "{$"
    s <- manyTill (noneOf "\n") $ char '}'
    return s

caseInsensitiveString :: Stream String Identity Char => String -> Parsec String u String
caseInsensitiveString s = do
    mapM_ (\a -> satisfy (\b -> toUpper a == toUpper b)) s <?> s
    return s

pas :: GenTokenParser String u Identity
pas = patch $ makeTokenParser pascalLanguageDef
    where
    patch tp = tp {stringLiteral = stringL}

comment :: Stream String Identity Char => Parsec String u String
comment = choice [
        char '{' >> notFollowedBy (char '$') >> manyTill anyChar (try $ char '}')
        , (try $ string "(*") >> manyTill anyChar (try $ string "*)")
        , (try $ string "//") >> manyTill anyChar (try newline)
        ]

comments :: Parsec String u ()
comments = do
    spaces
    skipMany $ do
        void $ preprocessorSwitch <|> comment
        spaces

stringL :: Parsec String u String
stringL = do
    char' '\''
    s <- (many $ noneOf "'")
    char' '\''
    ss <- many $ do
        char' '\''
        s' <- (many $ noneOf "'")
        char' '\''
        return $ '\'' : s'
    comments
    return $ concat (s:ss)
