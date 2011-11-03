module PascalParser where

import Text.ParserCombinators.Parsec
import Text.ParserCombinators.Parsec.Expr
import Text.ParserCombinators.Parsec.Token
import Text.ParserCombinators.Parsec.Language
import Control.Monad
import Data.Char

data PascalUnit =
    Program Identifier Implementation
    | Unit Identifier Interface Implementation (Maybe Initialize) (Maybe Finalize)
    deriving Show

data Interface = Interface Uses TypesAndVars
    deriving Show
data Implementation = Implementation Uses TypesAndVars
    deriving Show
data Identifier = Identifier String
    deriving Show
data TypesAndVars = TypesAndVars [TypeVarDeclaration]
    deriving Show
data TypeVarDeclaration = TypeDeclaration TypeDecl
    | ConstDeclaration String
    | VarDeclaration String
    | FunctionDeclaration Identifier Identifier (Maybe Phrase)
    deriving Show
data TypeDecl = SimpleType Identifier
    | RangeType Range
    | ArrayDecl Range TypeDecl
    deriving Show
data Range = Range Identifier    
    deriving Show
data Initialize = Initialize String
    deriving Show
data Finalize = Finalize String
    deriving Show
data Uses = Uses [Identifier]
    deriving Show
data Phrase = ProcCall Identifier [Expression]
        | IfThenElse Expression Phrase (Maybe Phrase)
        | WhileCycle Expression Phrase
        | RepeatCycle Expression Phrase
        | ForCycle
        | Phrases [Phrase]
        | SwitchCase Expression [(Expression, Phrase)] (Maybe Phrase)
        | Assignment Identifier Expression
    deriving Show
data Expression = Expression String
    | FunCall Identifier [Expression]
    | PrefixOp String Expression
    | BinOp String Expression Expression
    deriving Show
    

pascalLanguageDef
    = emptyDef
    { commentStart   = "(*"
    , commentEnd     = "*)"
    , commentLine    = "//"
    , nestedComments = False
    , identStart     = letter <|> oneOf "_"
    , identLetter    = alphaNum <|> oneOf "_."
    , reservedNames  = [
            "begin", "end", "program", "unit", "interface"
            , "implementation", "and", "or", "xor", "shl"
            , "shr", "while", "do", "repeat", "until", "case", "of"
            , "type", "var", "const", "out", "array"
            , "procedure", "function"
            ]
    , reservedOpNames= [] 
    , caseSensitive  = False   
    }
    
pas = makeTokenParser pascalLanguageDef
    
comments = do
    spaces
    skipMany $ do
        comment
        spaces

validIdChar = alphaNum <|> oneOf "_"    

pascalUnit = do
    comments
    u <- choice [program, unit]
    comments
    return u

comment = choice [
        char '{' >> manyTill anyChar (try $ char '}')
        , (try $ string "(*") >> manyTill anyChar (try $ string "*)")
        , (try $ string "//") >> manyTill anyChar (try newline)
        ]

unit = do
    name <- liftM Identifier unitName
    comments
    int <- interface
    impl <- implementation
    comments
    return $ Unit name int impl Nothing Nothing
    where
        unitName = between (string "unit" >> comments) (char ';') (identifier pas)

varsDecl = do
    v <- aVarDecl `sepBy1` (char ';' >> comments)
    char ';'
    comments
    return $ VarDeclaration $ show v
    where
    aVarDecl = do
        ids <- (try (identifier pas) >>= \i -> comments >> return (Identifier i)) `sepBy1` (char ',' >> comments)
        char ':'
        comments
        t <- typeDecl
        comments
        return (ids, t)
        
typeDecl = choice [
    arrayDecl
    , rangeDecl >>= return . RangeType
    , identifier pas >>= return . SimpleType . Identifier
    ] <?> "type declaration"
    where
    arrayDecl = do
        try $ string "array"
        comments
        char '['
        r <- rangeDecl
        char ']'
        comments
        string "of"
        comments
        t <- typeDecl
        return $ ArrayDecl r t

rangeDecl = choice [
    identifier pas >>= return . Range . Identifier
    ] <?> "range declaration"

typeVarDeclaration isImpl = choice [
    varSection,
    funcDecl,
    procDecl
    ]
    where
    varSection = do
        try $ string "var"
        comments
        v <- varsDecl
        return v
            
    procDecl = do
        string "procedure"
        comments
        i <- liftM Identifier $ identifier pas
        optional $ do
            char '('
            varsDecl
            char ')'
        comments
        char ';'
        b <- if isImpl then
                do
                comments
                typeVarDeclaration isImpl
                comments
                liftM Just functionBody
                else
                return Nothing
        comments
        return $ FunctionDeclaration i (Identifier "") b
        
    funcDecl = do
        string "function"
        comments
        char '('
        b <- manyTill anyChar (try $ char ')')
        char ')'
        comments
        char ':'
        ret <- identifier pas
        comments
        char ';'
        b <- if isImpl then
                do
                comments
                typeVarDeclaration isImpl
                comments
                liftM Just functionBody
                else
                return Nothing
        return $ FunctionDeclaration (Identifier "function") (Identifier ret) Nothing

program = do
    name <- liftM Identifier programName
    comments
    impl <- implementation
    comments
    return $ Program name impl
    where
        programName = between (string "program") (char ';') (identifier pas)

interface = do
    string "interface"
    comments
    u <- uses
    comments
    tv <- many (typeVarDeclaration False)
    comments
    return $ Interface u (TypesAndVars tv)

implementation = do
    string "implementation"
    comments
    u <- uses
    comments
    tv <- many (typeVarDeclaration True)
    string "end."
    comments
    return $ Implementation u (TypesAndVars tv)

expression = buildExpressionParser table term <?> "expression"
    where
    term = comments >> choice [
        parens pas $ expression 
        , natural pas >>= return . Expression . show
        , funCall
        ] <?> "simple expression"

    table = [ 
          [Infix (string "^." >> return (BinOp "^.")) AssocLeft]
        , [Prefix (string "not" >> return (PrefixOp "not"))]
        , [  Infix (char '*' >> return (BinOp "*")) AssocLeft
           , Infix (char '/' >> return (BinOp "/")) AssocLeft
           ]
        , [  Infix (char '+' >> return (BinOp "+")) AssocLeft
           , Infix (char '-' >> return (BinOp "-")) AssocLeft
           ]
        , [  Infix (try (string "<>" )>> return (BinOp "<>")) AssocNone
           , Infix (try (string "<=") >> return (BinOp "<=")) AssocNone
           , Infix (try (string ">=") >> return (BinOp ">=")) AssocNone
           , Infix (char '<' >> return (BinOp "<")) AssocNone
           , Infix (char '>' >> return (BinOp ">")) AssocNone
           , Infix (char '=' >> return (BinOp "=")) AssocNone
           ]
        , [  Infix (try $ string "and" >> return (BinOp "and")) AssocNone
           , Infix (try $ string "or" >> return (BinOp "or")) AssocNone
           , Infix (try $ string "xor" >> return (BinOp "xor")) AssocNone
           ]
        ]
    
phrasesBlock = do
    try $ string "begin"
    comments
    p <- manyTill phrase (try $ string "end")
    comments
    return $ Phrases p
    
phrase = do
    o <- choice [
        phrasesBlock
        , ifBlock
        , whileCycle
        , switchCase
        , try $ identifier pas >>= \i -> string ":=" >> expression >>= return . Assignment (Identifier i)
        , procCall
        ]
    optional $ char ';'
    comments
    return o

ifBlock = do
    try $ string "if"
    comments
    e <- expression
    comments
    string "then"
    comments
    o1 <- phrase
    comments
    o2 <- optionMaybe $ do
        try $ string "else"
        comments
        o <- phrase
        comments
        return o
    optional $ char ';'
    return $ IfThenElse e o1 o2

whileCycle = do
    try $ string "while"
    comments
    e <- expression
    comments
    string "do"
    comments
    o <- phrase
    optional $ char ';'
    return $ WhileCycle e o

switchCase = do
    try $ string "case"
    comments
    e <- expression
    comments
    string "of"
    comments
    cs <- many1 aCase
    o2 <- optionMaybe $ do
        try $ string "else"
        comments
        o <- phrase
        comments
        return o
    string "end"
    optional $ char ';'
    return $ SwitchCase e cs o2
    where
    aCase = do
        e <- expression
        comments
        char ':'
        comments
        p <- phrase
        comments
        return (e, p)
    
procCall = do
    i <- liftM Identifier $ identifier pas
    p <- option [] $ (parens pas) parameters
    return $ ProcCall i p

funCall = do
    i <- liftM Identifier $ identifier pas
    p <- option [] $ (parens pas) parameters
    return $ FunCall i p

parameters = expression `sepBy` (char ',' >> comments)
        
functionBody = do
    p <- phrasesBlock
    char ';'
    comments
    return p

uses = liftM Uses (option [] u)
    where
        u = do
            string "uses"
            comments
            u <- (identifier pas >>= \i -> comments >> return (Identifier i)) `sepBy1` (char ',' >> comments)
            char ';'
            comments
            return u
