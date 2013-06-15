module PascalParser where

import Text.Parsec
import Text.Parsec.Char
import Text.Parsec.Token
import Text.Parsec.Language
import Text.Parsec.Expr
import Text.Parsec.Prim
import Text.Parsec.Combinator
import Text.Parsec.String
import Control.Monad
import Data.Maybe
import Data.Char

import PascalBasics
import PascalUnitSyntaxTree

knownTypes = ["shortstring", "ansistring", "char", "byte"]

pascalUnit = do
    comments
    u <- choice [program, unit, systemUnit, redoUnit]
    comments
    return u

iD = do
    i <- identifier pas
    comments
    when (i == "not") $ unexpected "'not' used as an identifier"
    return $ Identifier i BTUnknown

unit = do
    string "unit" >> comments
    name <- iD
    semi pas
    comments
    int <- interface
    impl <- implementation
    comments
    return $ Unit name int impl Nothing Nothing


reference = buildExpressionParser table term <?> "reference"
    where
    term = comments >> choice [
        parens pas (liftM RefExpression expression >>= postfixes) >>= postfixes
        , try $ typeCast >>= postfixes
        , char '@' >> liftM Address reference >>= postfixes
        , liftM SimpleReference iD >>= postfixes
        ] <?> "simple reference"

    table = [
        ]

    postfixes r = many postfix >>= return . foldl (flip ($)) r
    postfix = choice [
            parens pas (option [] parameters) >>= return . FunCall
          , char '^' >> return Dereference
          , (brackets pas) (commaSep1 pas $ expression) >>= return . ArrayElement
          , (char '.' >> notFollowedBy (char '.')) >> liftM (flip RecordField) reference
        ]

    typeCast = do
        t <- choice $ map (\s -> try $ caseInsensitiveString s >>= \i -> notFollowedBy alphaNum >> return i) knownTypes
        e <- parens pas expression
        comments
        return $ TypeCast (Identifier t BTUnknown) e

varsDecl1 = varsParser sepEndBy1
varsDecl = varsParser sepEndBy
varsParser m endsWithSemi = do
    vs <- m (aVarDecl endsWithSemi) (semi pas)
    return vs

aVarDecl endsWithSemi = do
    isVar <- liftM (== Just "var") $
        if not endsWithSemi then
            optionMaybe $ choice [
                try $ string "var"
                , try $ string "const"
                , try $ string "out"
                ]
            else
                return Nothing
    comments
    ids <- do
        i <- (commaSep1 pas) $ (try iD <?> "variable declaration")
        char ':'
        return i
    comments
    t <- typeDecl <?> "variable type declaration"
    comments
    init <- option Nothing $ do
        char '='
        comments
        e <- initExpression
        comments
        return (Just e)
    return $ VarDeclaration isVar False (ids, t) init


constsDecl = do
    vs <- many1 (try (aConstDecl >>= \i -> semi pas >> return i) >>= \i -> comments >> return i)
    comments
    return vs
    where
    aConstDecl = do
        comments
        i <- iD
        t <- optionMaybe $ do
            char ':'
            comments
            t <- typeDecl
            comments
            return t
        char '='
        comments
        e <- initExpression
        comments
        return $ VarDeclaration False (isNothing t) ([i], fromMaybe (DeriveType e) t) (Just e)

typeDecl = choice [
    char '^' >> typeDecl >>= return . PointerTo
    , try (string "shortstring") >> return (String 255)
    , try (string "string") >> optionMaybe (brackets pas $ integer pas) >>= return . String . fromMaybe 255
    , try (string "ansistring") >> optionMaybe (brackets pas $ integer pas) >>= return . String . fromMaybe 255
    , arrayDecl
    , recordDecl
    , setDecl
    , functionType
    , sequenceDecl >>= return . Sequence
    , try iD >>= return . SimpleType
    , rangeDecl >>= return . RangeType
    ] <?> "type declaration"
    where
    arrayDecl = do
        try $ do
            optional $ (try $ string "packed") >> comments
            string "array"
        comments
        r <- option [] $ do
            char '['
            r <- commaSep pas rangeDecl
            char ']'
            comments
            return r
        string "of"
        comments
        t <- typeDecl
        if null r then
            return $ ArrayDecl Nothing t
            else
            return $ foldr (\a b -> ArrayDecl (Just a) b) (ArrayDecl (Just $ head r) t) (tail r)
    recordDecl = do
        try $ do
            optional $ (try $ string "packed") >> comments
            string "record"
        comments
        vs <- varsDecl True
        union <- optionMaybe $ do
            string "case"
            comments
            iD
            comments
            string "of"
            comments
            many unionCase
        string "end"
        return $ RecordType vs union
    setDecl = do
        try $ string "set" >> space
        comments
        string "of"
        comments
        liftM Set typeDecl
    unionCase = do
        try $ commaSep pas $ (iD >> return ()) <|> (integer pas >> return ())
        char ':'
        comments
        u <- parens pas $ varsDecl True
        char ';'
        comments
        return u
    sequenceDecl = (parens pas) $ (commaSep pas) (iD >>= \i -> optional (spaces >> char '=' >> spaces >> integer pas) >> return i)
    functionType = do
        fp <- try (string "function") <|> try (string "procedure")
        comments
        vs <- option [] $ parens pas $ varsDecl False
        comments
        ret <- if (fp == "function") then do
            char ':'
            comments
            ret <- typeDecl
            comments
            return ret
            else
            return VoidType
        optional $ try $ char ';' >> comments >> string "cdecl"
        comments
        return $ FunctionType ret vs

typesDecl = many (aTypeDecl >>= \t -> comments >> return t)
    where
    aTypeDecl = do
        i <- try $ do
            i <- iD <?> "type declaration"
            comments
            char '='
            return i
        comments
        t <- typeDecl
        comments
        semi pas
        comments
        return $ TypeDeclaration i t

rangeDecl = choice [
    try $ rangeft
    , iD >>= return . Range
    ] <?> "range declaration"
    where
    rangeft = do
    e1 <- initExpression
    string ".."
    e2 <- initExpression
    return $ RangeFromTo e1 e2

typeVarDeclaration isImpl = (liftM concat . many . choice) [
    varSection,
    constSection,
    typeSection,
    funcDecl,
    operatorDecl
    ]
    where

    fixInit v = concat $ map (\x -> case x of
                    VarDeclaration a b (ids, t) c ->
                        let typeId = (Identifier ((\(Identifier i _) -> i) (head ids) ++ "_tt") BTUnknown) in
                        let res =  [TypeDeclaration typeId t, VarDeclaration a b (ids, (SimpleType typeId)) c] in
                        case t of
                            RecordType _ _ -> res -- create a separated type declaration
                            ArrayDecl _ _ -> res
                            _ -> [x]
                    _ -> error ("checkInit:\n" ++ (show v))) v

    varSection = do
        try $ string "var"
        comments
        v <- varsDecl1 True <?> "variable declaration"
        comments
        return $ fixInit v

    constSection = do
        try $ string "const"
        comments
        c <- constsDecl <?> "const declaration"
        comments
        return $ fixInit c

    typeSection = do
        try $ string "type"
        comments
        t <- typesDecl <?> "type declaration"
        comments
        return t

    operatorDecl = do
        try $ string "operator"
        comments
        i <- manyTill anyChar space
        comments
        vs <- parens pas $ varsDecl False
        comments
        rid <- iD
        comments
        char ':'
        comments
        ret <- typeDecl
        comments
        return ret
        char ';'
        comments
        forward <- liftM isJust $ optionMaybe (try (string "forward;") >> comments)
        inline <- liftM (any (== "inline;")) $ many functionDecorator
        b <- if isImpl && (not forward) then
                liftM Just functionBody
                else
                return Nothing
        return $ [OperatorDeclaration i rid inline ret vs b]


    funcDecl = do
        fp <- try (string "function") <|> try (string "procedure")
        comments
        i <- iD
        vs <- option [] $ parens pas $ varsDecl False
        comments
        ret <- if (fp == "function") then do
            char ':'
            comments
            ret <- typeDecl
            comments
            return ret
            else
            return VoidType
        char ';'
        comments
        forward <- liftM isJust $ optionMaybe (try (string "forward;") >> comments)
        decorators <- many functionDecorator
        let inline = any (== "inline;") decorators
            overload = any (== "overload;") decorators
        b <- if isImpl && (not forward) then
                liftM Just functionBody
                else
                return Nothing
        return $ [FunctionDeclaration i inline overload ret vs b]

    functionDecorator = do
        d <- choice [
            try $ string "inline;"
            , try $ caseInsensitiveString "cdecl;"
            , try $ string "overload;"
            , try $ string "export;"
            , try $ string "varargs;"
            , try (string "external") >> comments >> iD >> optional (string "name" >> comments >> stringLiteral pas)>> string ";"
            ]
        comments
        return d


program = do
    string "program"
    comments
    name <- iD
    (char ';')
    comments
    comments
    u <- uses
    comments
    tv <- typeVarDeclaration True
    comments
    p <- phrase
    comments
    char '.'
    comments
    return $ Program name (Implementation u (TypesAndVars tv)) p

interface = do
    string "interface"
    comments
    u <- uses
    comments
    tv <- typeVarDeclaration False
    comments
    return $ Interface u (TypesAndVars tv)

implementation = do
    string "implementation"
    comments
    u <- uses
    comments
    tv <- typeVarDeclaration True
    string "end."
    comments
    return $ Implementation u (TypesAndVars tv)

expression = do
    buildExpressionParser table term <?> "expression"
    where
    term = comments >> choice [
        builtInFunction expression >>= \(n, e) -> return $ BuiltInFunCall e (SimpleReference (Identifier n BTUnknown))
        , try (parens pas $ expression >>= \e -> notFollowedBy (comments >> char '.') >> return e)
        , brackets pas (commaSep pas iD) >>= return . SetExpression
        , try $ integer pas >>= \i -> notFollowedBy (char '.') >> (return . NumberLiteral . show) i
        , float pas >>= return . FloatLiteral . show
        , try $ integer pas >>= return . NumberLiteral . show
        , try (string "_S" >> stringLiteral pas) >>= return . StringLiteral
        , try (string "_P" >> stringLiteral pas) >>= return . PCharLiteral
        , stringLiteral pas >>= return . strOrChar
        , try (string "#$") >> many hexDigit >>= \c -> comments >> return (HexCharCode c)
        , char '#' >> many digit >>= \c -> comments >> return (CharCode c)
        , char '$' >> many hexDigit >>=  \h -> comments >> return (HexNumber h)
        --, char '-' >> expression >>= return . PrefixOp "-"
        , char '-' >> reference >>= return . PrefixOp "-" . Reference
        , (try $ string "not" >> notFollowedBy comments) >> unexpected "'not'"
        , try $ string "nil" >> return Null
        , reference >>= return . Reference
        ] <?> "simple expression"

    table = [
          [  Prefix (reservedOp pas "not">> return (PrefixOp "not"))
           , Prefix (try (char '-') >> return (PrefixOp "-"))]
           ,
          [  Infix (char '*' >> return (BinOp "*")) AssocLeft
           , Infix (char '/' >> return (BinOp "/")) AssocLeft
           , Infix (try (string "div") >> return (BinOp "div")) AssocLeft
           , Infix (try (string "mod") >> return (BinOp "mod")) AssocLeft
           , Infix (try (string "in") >> return (BinOp "in")) AssocNone
           , Infix (try $ string "and" >> return (BinOp "and")) AssocLeft
           , Infix (try $ string "shl" >> return (BinOp "shl")) AssocLeft
           , Infix (try $ string "shr" >> return (BinOp "shr")) AssocLeft
          ]
        , [  Infix (char '+' >> return (BinOp "+")) AssocLeft
           , Infix (char '-' >> return (BinOp "-")) AssocLeft
           , Infix (try $ string "or" >> return (BinOp "or")) AssocLeft
           , Infix (try $ string "xor" >> return (BinOp "xor")) AssocLeft
          ]
        , [  Infix (try (string "<>") >> return (BinOp "<>")) AssocNone
           , Infix (try (string "<=") >> return (BinOp "<=")) AssocNone
           , Infix (try (string ">=") >> return (BinOp ">=")) AssocNone
           , Infix (char '<' >> return (BinOp "<")) AssocNone
           , Infix (char '>' >> return (BinOp ">")) AssocNone
          ]
        {-, [  Infix (try $ string "shl" >> return (BinOp "shl")) AssocNone
             , Infix (try $ string "shr" >> return (BinOp "shr")) AssocNone
          ]
        , [
             Infix (try $ string "or" >> return (BinOp "or")) AssocLeft
           , Infix (try $ string "xor" >> return (BinOp "xor")) AssocLeft
          ]-}
        , [
             Infix (char '=' >> return (BinOp "=")) AssocNone
          ]
        ]
    strOrChar [a] = CharCode . show . ord $ a
    strOrChar a = StringLiteral a

phrasesBlock = do
    try $ string "begin"
    comments
    p <- manyTill phrase (try $ string "end" >> notFollowedBy alphaNum)
    comments
    return $ Phrases p

phrase = do
    o <- choice [
        phrasesBlock
        , ifBlock
        , whileCycle
        , repeatCycle
        , switchCase
        , withBlock
        , forCycle
        , (try $ reference >>= \r -> string ":=" >> return r) >>= \r -> comments >> expression >>= return . Assignment r
        , builtInFunction expression >>= \(n, e) -> return $ BuiltInFunctionCall e (SimpleReference (Identifier n BTUnknown))
        , procCall
        , char ';' >> comments >> return NOP
        ]
    optional $ char ';'
    comments
    return o

ifBlock = do
    try $ string "if" >> notFollowedBy (alphaNum <|> char '_')
    comments
    e <- expression
    comments
    string "then"
    comments
    o1 <- phrase
    comments
    o2 <- optionMaybe $ do
        try $ string "else" >> space
        comments
        o <- option NOP phrase
        comments
        return o
    return $ IfThenElse e o1 o2

whileCycle = do
    try $ string "while"
    comments
    e <- expression
    comments
    string "do"
    comments
    o <- phrase
    return $ WhileCycle e o

withBlock = do
    try $ string "with" >> space
    comments
    rs <- (commaSep1 pas) reference
    comments
    string "do"
    comments
    o <- phrase
    return $ foldr WithBlock o rs

repeatCycle = do
    try $ string "repeat" >> space
    comments
    o <- many phrase
    string "until"
    comments
    e <- expression
    comments
    return $ RepeatCycle e o

forCycle = do
    try $ string "for" >> space
    comments
    i <- iD
    comments
    string ":="
    comments
    e1 <- expression
    comments
    up <- liftM (== Just "to") $
            optionMaybe $ choice [
                try $ string "to"
                , try $ string "downto"
                ]
    --choice [string "to", string "downto"]
    comments
    e2 <- expression
    comments
    string "do"
    comments
    p <- phrase
    comments
    return $ ForCycle i e1 e2 p up

switchCase = do
    try $ string "case"
    comments
    e <- expression
    comments
    string "of"
    comments
    cs <- many1 aCase
    o2 <- optionMaybe $ do
        try $ string "else" >> notFollowedBy alphaNum
        comments
        o <- many phrase
        comments
        return o
    string "end"
    comments
    return $ SwitchCase e cs o2
    where
    aCase = do
        e <- (commaSep pas) $ (liftM InitRange rangeDecl <|> initExpression)
        comments
        char ':'
        comments
        p <- phrase
        comments
        return (e, p)

procCall = do
    r <- reference
    p <- option [] $ (parens pas) parameters
    return $ ProcCall r p

parameters = (commaSep pas) expression <?> "parameters"

functionBody = do
    tv <- typeVarDeclaration True
    comments
    p <- phrasesBlock
    char ';'
    comments
    return (TypesAndVars tv, p)

uses = liftM Uses (option [] u)
    where
        u = do
            string "uses"
            comments
            u <- (iD >>= \i -> comments >> return i) `sepBy1` (char ',' >> comments)
            char ';'
            comments
            return u

initExpression = buildExpressionParser table term <?> "initialization expression"
    where
    term = comments >> choice [
        liftM (uncurry BuiltInFunction) $ builtInFunction initExpression
        , try $ brackets pas (commaSep pas $ initExpression) >>= return . InitSet
        , try $ parens pas (commaSep pas $ initExpression) >>= \ia -> when (null $ tail ia) mzero >> return (InitArray ia)
        , try $ parens pas (sepEndBy recField (char ';' >> comments)) >>= return . InitRecord
        , parens pas initExpression
        , try $ integer pas >>= \i -> notFollowedBy (char '.') >> (return . InitNumber . show) i
        , try $ float pas >>= return . InitFloat . show
        , try $ integer pas >>= return . InitNumber . show
        , stringLiteral pas >>= return . InitString
        , char '#' >> many digit >>= \c -> comments >> return (InitChar c)
        , char '$' >> many hexDigit >>= \h -> comments >> return (InitHexNumber h)
        , char '@' >> initExpression >>= \c -> comments >> return (InitAddress c)
        , try $ string "nil" >> return InitNull
        , itypeCast
        , iD >>= return . InitReference
        ]

    recField = do
        i <- iD
        spaces
        char ':'
        spaces
        e <- initExpression
        spaces
        return (i ,e)

    table = [
          [
             Prefix (char '-' >> return (InitPrefixOp "-"))
            ,Prefix (try (string "not") >> return (InitPrefixOp "not"))
          ]
        , [  Infix (char '*' >> return (InitBinOp "*")) AssocLeft
           , Infix (char '/' >> return (InitBinOp "/")) AssocLeft
           , Infix (try (string "div") >> return (InitBinOp "div")) AssocLeft
           , Infix (try (string "mod") >> return (InitBinOp "mod")) AssocLeft
           , Infix (try $ string "and" >> return (InitBinOp "and")) AssocLeft
           , Infix (try $ string "shl" >> return (InitBinOp "shl")) AssocNone
           , Infix (try $ string "shr" >> return (InitBinOp "shr")) AssocNone
          ]
        , [  Infix (char '+' >> return (InitBinOp "+")) AssocLeft
           , Infix (char '-' >> return (InitBinOp "-")) AssocLeft
           , Infix (try $ string "or" >> return (InitBinOp "or")) AssocLeft
           , Infix (try $ string "xor" >> return (InitBinOp "xor")) AssocLeft
          ]
        , [  Infix (try (string "<>") >> return (InitBinOp "<>")) AssocNone
           , Infix (try (string "<=") >> return (InitBinOp "<=")) AssocNone
           , Infix (try (string ">=") >> return (InitBinOp ">=")) AssocNone
           , Infix (char '<' >> return (InitBinOp "<")) AssocNone
           , Infix (char '>' >> return (InitBinOp ">")) AssocNone
           , Infix (char '=' >> return (InitBinOp "=")) AssocNone
          ]
        {--, [  Infix (try $ string "and" >> return (InitBinOp "and")) AssocLeft
           , Infix (try $ string "or" >> return (InitBinOp "or")) AssocLeft
           , Infix (try $ string "xor" >> return (InitBinOp "xor")) AssocLeft
          ]
        , [  Infix (try $ string "shl" >> return (InitBinOp "shl")) AssocNone
           , Infix (try $ string "shr" >> return (InitBinOp "shr")) AssocNone
          ]--}
        --, [Prefix (try (string "not") >> return (InitPrefixOp "not"))]
        ]

    itypeCast = do
        t <- choice $ map (\s -> try $ caseInsensitiveString s >>= \i -> notFollowedBy alphaNum >> return i) knownTypes
        i <- parens pas initExpression
        comments
        return $ InitTypeCast (Identifier t BTUnknown) i

builtInFunction e = do
    name <- choice $ map (\s -> try $ caseInsensitiveString s >>= \i -> notFollowedBy alphaNum >> return i) builtin
    spaces
    exprs <- option [] $ parens pas $ option [] $ commaSep1 pas $ e
    spaces
    return (name, exprs)

systemUnit = do
    string "system;"
    comments
    string "type"
    comments
    t <- typesDecl
    string "var"
    v <- varsDecl True
    return $ System (t ++ v)

redoUnit = do
    string "redo;"
    comments
    string "type"
    comments
    t <- typesDecl
    string "var"
    v <- varsDecl True
    return $ Redo (t ++ v)

