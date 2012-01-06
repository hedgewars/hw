{-# LANGUAGE FlexibleContexts #-}
module PascalBasics where

import Text.Parsec.Combinator
import Text.Parsec.Char
import Text.Parsec.Prim
import Text.Parsec.Token
import Text.Parsec.Language
import Data.Char

builtin = ["succ", "pred", "low", "high", "ord"]
    
pascalLanguageDef
    = emptyDef
    { commentStart   = "(*"
    , commentEnd     = "*)"
    , commentLine    = "//"
    , nestedComments = False
    , identStart     = letter <|> oneOf "_"
    , identLetter    = alphaNum <|> oneOf "_"
    , reservedNames  = [
            "begin", "end", "program", "unit", "interface"
            , "implementation", "and", "or", "xor", "shl"
            , "shr", "while", "do", "repeat", "until", "case", "of"
            , "type", "var", "const", "out", "array", "packed"
            , "procedure", "function", "with", "for", "to"
            , "downto", "div", "mod", "record", "set", "nil"
            , "cdecl", "external", "if", "then", "else"
            ] -- ++ builtin
    , reservedOpNames= [] 
    , caseSensitive  = False   
    }

preprocessorSwitch :: Stream s m Char => ParsecT s u m String
preprocessorSwitch = do
    try $ string "{$"
    s <- manyTill (noneOf "\n") $ char '}'
    return s
        
caseInsensitiveString s = do
    mapM_ (\a -> satisfy (\b -> toUpper a == toUpper b)) s <?> s
    return s
    
pas = patch $ makeTokenParser pascalLanguageDef
    where
    patch tp = tp {stringLiteral = stringL}

comment = choice [
        char '{' >> notFollowedBy (char '$') >> manyTill anyChar (try $ char '}')
        , (try $ string "(*") >> manyTill anyChar (try $ string "*)")
        , (try $ string "//") >> manyTill anyChar (try newline)
        ]
    
comments = do
    spaces
    skipMany $ do
        preprocessorSwitch <|> comment
        spaces

stringL = do
    (char '\'')
    s <- (many $ noneOf "'")
    (char '\'')
    ss <- many $ do
        (char '\'')
        s' <- (many $ noneOf "'")
        (char '\'')
        return $ '\'' : s'
    comments    
    return $ concat (s:ss)
