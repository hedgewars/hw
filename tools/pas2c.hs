{-# LANGUAGE ScopedTypeVariables #-}
module Pas2C where

import Text.PrettyPrint.HughesPJ
import Data.Maybe
import Data.Char
import Text.Parsec.Prim hiding (State)
import Control.Monad.State
import System.IO
import System.Directory
import Control.Monad.IO.Class
import PascalPreprocessor
import Control.Exception
import System.IO.Error
import qualified Data.Map as Map
import Data.List (find)
import Numeric

import PascalParser
import PascalUnitSyntaxTree


data InsertOption = 
    IOInsert
    | IOLookup
    | IODeferred

type Record = (String, (String, BaseType))
data RenderState = RenderState 
    {
        currentScope :: [Record],
        lastIdentifier :: String,
        lastType :: BaseType,
        namespaces :: Map.Map String [Record]
    }
    
emptyState = RenderState [] "" BTUnknown
    
docToLower :: Doc -> Doc
docToLower = text . map toLower . render

pas2C :: String -> IO ()
pas2C fn = do
    setCurrentDirectory "../hedgewars/"
    s <- flip execStateT initState $ f fn
    renderCFiles s
    where
    printLn = liftIO . hPutStrLn stderr
    print = liftIO . hPutStr stderr
    initState = Map.empty
    f :: String -> StateT (Map.Map String PascalUnit) IO ()
    f fileName = do
        processed <- gets $ Map.member fileName
        unless processed $ do
            print ("Preprocessing '" ++ fileName ++ ".pas'... ")
            fc' <- liftIO 
                $ tryJust (guard . isDoesNotExistError) 
                $ preprocess (fileName ++ ".pas")
            case fc' of
                (Left a) -> do
                    modify (Map.insert fileName (System []))
                    printLn "doesn't exist"
                (Right fc) -> do
                    print "ok, parsing... "
                    let ptree = parse pascalUnit fileName fc
                    case ptree of
                         (Left a) -> do
                            liftIO $ writeFile "preprocess.out" fc
                            printLn $ show a ++ "\nsee preprocess.out for preprocessed source"
                            fail "stop"
                         (Right a) -> do
                            printLn "ok"
                            modify (Map.insert fileName a)
                            mapM_ f (usesFiles a)


renderCFiles :: Map.Map String PascalUnit -> IO ()
renderCFiles units = do
    let u = Map.toList units
    let nss = Map.map (toNamespace nss) units
    hPutStrLn stderr $ "Units: " ++ (show . Map.keys . Map.filter (not . null) $ nss)
    --writeFile "pas2c.log" $ unlines . map (\t -> show (fst t) ++ "\n" ++ (unlines . map ((:) '\t' . show) . snd $ t)) . Map.toList $ nss
    mapM_ (toCFiles nss) u
    where
    toNamespace :: Map.Map String [Record] -> PascalUnit -> [Record]
    toNamespace nss (System tvs) = 
        currentScope $ execState (mapM_ (tvar2C True) tvs) (emptyState nss)
    toNamespace _ (Program {}) = []
    toNamespace nss (Unit _ interface _ _ _) = 
        currentScope $ execState (interface2C interface) (emptyState nss)


withState' :: (RenderState -> RenderState) -> State RenderState a -> State RenderState a
withState' f sf = do
    st <- liftM f get
    let (a, s) = runState sf st
    modify(\st -> st{lastType = lastType s})
    return a

withLastIdNamespace :: State RenderState Doc -> State RenderState Doc
withLastIdNamespace f = do
    li <- gets lastIdentifier
    nss <- gets namespaces
    withState' (\st -> st{currentScope = fromMaybe [] $ Map.lookup li (namespaces st)}) f

withRecordNamespace :: String -> [(String, BaseType)] -> State RenderState Doc -> State RenderState Doc
withRecordNamespace _ [] = error "withRecordNamespace: empty record"
withRecordNamespace prefix recs = withState' f
    where
        f st = st{currentScope = records ++ currentScope st}
        records = map (\(a, b) -> (map toLower a, (prefix ++ a, b))) recs

toCFiles :: Map.Map String [Record] -> (String, PascalUnit) -> IO ()
toCFiles _ (_, System _) = return ()
toCFiles ns p@(fn, pu) = do
    hPutStrLn stderr $ "Rendering '" ++ fn ++ "'..."
    toCFiles' p
    where
    toCFiles' (fn, p@(Program {})) = writeFile (fn ++ ".c") $ (render2C initialState . pascal2C) p
    toCFiles' (fn, (Unit unitId interface implementation _ _)) = do
        let (a, s) = runState (id2C IOInsert (setBaseType BTUnit unitId) >> interface2C interface) initialState
        writeFile (fn ++ ".h") $ "#pragma once\n\n" ++ (render a)
        writeFile (fn ++ ".c") $ "#include \"pas2c.h\"\n#include \"" ++ fn ++ ".h\"\n" ++ (render2C s . implementation2C) implementation
    initialState = emptyState ns

    render2C :: RenderState -> State RenderState Doc -> String
    render2C a = render . flip evalState a

usesFiles :: PascalUnit -> [String]
usesFiles (Program _ (Implementation uses _) _) = "pas2cSystem" : uses2List uses
usesFiles (Unit _ (Interface uses1 _) (Implementation uses2 _) _ _) = "pas2cSystem" : uses2List uses1 ++ uses2List uses2
usesFiles (System {}) = []


pascal2C :: PascalUnit -> State RenderState Doc
pascal2C (Unit _ interface implementation init fin) =
    liftM2 ($+$) (interface2C interface) (implementation2C implementation)
    
pascal2C (Program _ implementation mainFunction) = do
    impl <- implementation2C implementation
    main <- tvar2C True 
        (FunctionDeclaration (Identifier "main" BTInt) (SimpleType $ Identifier "int" BTInt) [] (Just (TypesAndVars [], mainFunction)))
    return $ impl $+$ main

    
    
interface2C :: Interface -> State RenderState Doc
interface2C (Interface uses tvars) = liftM2 ($+$) (uses2C uses) (typesAndVars2C True tvars)

implementation2C :: Implementation -> State RenderState Doc
implementation2C (Implementation uses tvars) = liftM2 ($+$) (uses2C uses) (typesAndVars2C True tvars)


typesAndVars2C :: Bool -> TypesAndVars -> State RenderState Doc
typesAndVars2C b (TypesAndVars ts) = liftM vcat $ mapM (tvar2C b) ts

setBaseType :: BaseType -> Identifier -> Identifier
setBaseType bt (Identifier i _) = Identifier i bt

uses2C :: Uses -> State RenderState Doc
uses2C uses@(Uses unitIds) = do
    mapM_ injectNamespace (Identifier "pas2cSystem" undefined : unitIds)
    mapM_ (id2C IOInsert . setBaseType BTUnit) unitIds
    return $ vcat . map (\i -> text $ "#include \"" ++ i ++ ".h\"") $ uses2List uses
    where
    injectNamespace (Identifier i _) = do
        getNS <- gets (flip Map.lookup . namespaces)
        let f = flip (foldl (flip (:))) (fromMaybe [] (getNS i))
        modify (\s -> s{currentScope = f $ currentScope s})

uses2List :: Uses -> [String]
uses2List (Uses ids) = map (\(Identifier i _) -> i) ids


id2C :: InsertOption -> Identifier -> State RenderState Doc
id2C IOInsert (Identifier i t) = do
    ns <- gets currentScope
{--    case t of 
        BTUnknown -> do
            ns <- gets currentScope
            error $ "id2C IOInsert: type BTUnknown for " ++ show i ++ "\nnamespace: " ++ show (take 100 ns)
        _ -> do --}
    modify (\s -> s{currentScope = (n, (i, t)) : currentScope s, lastIdentifier = n})
    return $ text i
    where
        n = map toLower i
id2C IOLookup (Identifier i t) = do
    let i' = map toLower i
    v <- gets $ find (\(a, _) -> a == i') . currentScope
    ns <- gets currentScope
    lt <- gets lastType
    if isNothing v then 
        error $ "Not defined: '" ++ i' ++ "'\n" ++ show lt ++ "\n" ++ show (take 100 ns)
        else 
        let vv = snd $ fromJust v in modify (\s -> s{lastType = snd vv, lastIdentifier = fst vv}) >> (return . text . fst $ vv)
id2C IODeferred (Identifier i t) = do
    let i' = map toLower i
    v <- gets $ find (\(a, _) -> a == i') . currentScope
    if (isNothing v) then
        return $ text i
        else
        return . text . fst . snd . fromJust $ v

id2CTyped :: TypeDecl -> Identifier -> State RenderState Doc
id2CTyped t (Identifier i _) = do
    tb <- resolveType t
    ns <- gets currentScope
    case tb of 
        BTUnknown -> do
            ns <- gets currentScope
            error $ "id2CTyped: type BTUnknown for " ++ show i ++ "\ntype: " ++ show t ++ "\nnamespace: " ++ show (take 100 ns)
        _ -> return ()
    id2C IOInsert (Identifier i tb)


resolveType :: TypeDecl -> State RenderState BaseType
resolveType st@(SimpleType (Identifier i _)) = do
    let i' = map toLower i
    v <- gets $ find (\(a, _) -> a == i') . currentScope
    if isJust v then return . snd . snd $ fromJust v else return $ f i'
    where
    f "integer" = BTInt
    f "pointer" = BTPointerTo BTVoid
    f "boolean" = BTBool
    f "float" = BTFloat
    f "char" = BTChar
    f "string" = BTString
    f _ = error $ "Unknown system type: " ++ show st
resolveType (PointerTo (SimpleType (Identifier i _))) = return . BTPointerTo $ BTUnresolved (map toLower i)
resolveType (PointerTo t) = liftM BTPointerTo $ resolveType t
resolveType (RecordType tv mtvs) = do
    tvs <- mapM f (concat $ tv : fromMaybe [] mtvs)
    return . BTRecord . concat $ tvs
    where
        f :: TypeVarDeclaration -> State RenderState [(String, BaseType)]
        f (VarDeclaration _ (ids, td) _) = mapM (\(Identifier i _) -> liftM ((,) i) $ resolveType td) ids
resolveType (ArrayDecl (Just _) t) = liftM (BTArray BTInt) $ resolveType t
resolveType (ArrayDecl Nothing t) = liftM (BTArray BTInt) $ resolveType t
resolveType (FunctionType t _) = liftM BTFunction $ resolveType t
resolveType (DeriveType (InitHexNumber _)) = return BTInt
resolveType (DeriveType (InitNumber _)) = return BTInt
resolveType (DeriveType (InitFloat _)) = return BTFloat
resolveType (DeriveType (InitString _)) = return BTString
resolveType (DeriveType (InitBinOp {})) = return BTInt
resolveType (DeriveType (InitPrefixOp {})) = return BTInt
resolveType (DeriveType (BuiltInFunction{})) = return BTInt
resolveType (DeriveType (InitReference (Identifier{}))) = return BTBool -- TODO: derive from actual type
resolveType (DeriveType _) = return BTUnknown
resolveType (String _) = return BTString
resolveType VoidType = return BTVoid
resolveType (Sequence ids) = return $ BTEnum $ map (\(Identifier i _) -> map toLower i) ids
resolveType (RangeType _) = return $ BTVoid
resolveType (Set t) = liftM BTSet $ resolveType t
   

fromPointer :: String -> BaseType -> State RenderState BaseType    
fromPointer s (BTPointerTo t) = f t
    where
        f (BTUnresolved s) = do
            v <- gets $ find (\(a, _) -> a == s) . currentScope
            if isJust v then
                f . snd . snd . fromJust $ v
                else
                error $ "Unknown type " ++ show t ++ "\n" ++ s
        f t = return t
fromPointer s t = do
    ns <- gets currentScope
    error $ "Dereferencing from non-pointer type " ++ show t ++ "\n" ++ s ++ "\n\n" ++ show (take 100 ns)


tvar2C :: Bool -> TypeVarDeclaration -> State RenderState Doc
tvar2C _ (FunctionDeclaration name returnType params Nothing) = do
    t <- type2C returnType 
    t'<- gets lastType
    p <- withState' id $ liftM hcat $ mapM (tvar2C False) params
    n <- id2C IOInsert $ setBaseType (BTFunction t') name
    return $ t <+> n <> parens p <> text ";"
    
tvar2C True (FunctionDeclaration name returnType params (Just (tvars, phrase))) = do
    t <- type2C returnType
    t'<- gets lastType
    n <- id2C IOInsert $ setBaseType (BTFunction t') name
    (p, ph) <- withState' (\st -> st{currentScope = (lastIdentifier st, (lastIdentifier st ++ "_result", t')) : currentScope st}) $ do
        p <- liftM hcat $ mapM (tvar2C False) params
        ph <- liftM2 ($+$) (typesAndVars2C False tvars) (phrase2C' phrase)
        return (p, ph)
    let res = docToLower $ n <> text "_result"
    let phrasesBlock = case returnType of
            VoidType -> ph
            _ -> t <+> res <> semi $+$ ph $+$ text "return" <+> res <> semi
    return $ 
        t <+> n <> parens p
        $+$
        text "{" 
        $+$ 
        nest 4 phrasesBlock
        $+$
        text "}"
    where
    phrase2C' (Phrases p) = liftM vcat $ mapM phrase2C p
    phrase2C' p = phrase2C p
    
tvar2C False (FunctionDeclaration (Identifier name _) _ _ _) = error $ "nested functions not allowed: " ++ name

tvar2C _ td@(TypeDeclaration i' t) = do
    i <- id2CTyped t i'
    tp <- type2C t
    return $ text "type" <+> i <+> tp <> semi
    
tvar2C _ (VarDeclaration isConst (ids, t) mInitExpr) = do
    t' <- type2C t
    i <- mapM (id2CTyped t) ids
    ie <- initExpr mInitExpr
    return $ if isConst then text "const" else empty
        <+> t'
        <+> (hsep . punctuate (char ',') $ i)
        <+> ie
        <> text ";"
    where
    initExpr Nothing = return $ empty
    initExpr (Just e) = liftM (text "=" <+>) (initExpr2C e)
    
tvar2C f (OperatorDeclaration op i ret params body) = 
    tvar2C f (FunctionDeclaration i ret params body)

    
initExpr2C :: InitExpression -> State RenderState Doc
initExpr2C InitNull = return $ text "NULL"
initExpr2C (InitAddress expr) = liftM ((<>) (text "&")) (initExpr2C expr)
initExpr2C (InitPrefixOp op expr) = liftM2 (<>) (op2C op) (initExpr2C expr)
initExpr2C (InitBinOp op expr1 expr2) = do
    e1 <- initExpr2C expr1
    e2 <- initExpr2C expr2
    o <- op2C op
    return $ parens $ e1 <+> o <+> e2
initExpr2C (InitNumber s) = return $ text s
initExpr2C (InitFloat s) = return $ text s
initExpr2C (InitHexNumber s) = return $ text "0x" <> (text . map toLower $ s)
initExpr2C (InitString s) = return $ doubleQuotes $ text s 
initExpr2C (InitChar a) = return $ quotes $ text "\\x" <> text (showHex (read a) "")
initExpr2C (InitReference i) = id2C IOLookup i
initExpr2C (InitRecord fields) = do
    (fs :: [Doc]) <- mapM (\(Identifier a _, b) -> liftM (text "." <> text a <+> equals <+>) $ initExpr2C b) fields
    return $ lbrace $+$ (nest 4 . vcat $ fs) $+$ rbrace
initExpr2C (InitArray [value]) = initExpr2C value
initExpr2C (InitArray values) = liftM (braces . vcat . punctuate comma) $ mapM initExpr2C values
initExpr2C (InitRange _) = return $ text "<<range expression>>"
initExpr2C (InitSet _) = return $ text "<<set>>"
initExpr2C (BuiltInFunction {}) = return $ text "<<built-in function>>"
initExpr2C a = error $ "Don't know how to render " ++ show a


type2C :: TypeDecl -> State RenderState Doc
type2C (SimpleType i) = id2C IOLookup i
type2C t = do
    r <- type2C' t
    rt <- resolveType t
    modify (\st -> st{lastType = rt})
    return r
    where
    type2C' VoidType = return $ text "void"
    type2C' (String l) = return $ text $ "string" ++ show l
    type2C' (PointerTo (SimpleType i)) = liftM (<> text "*") $ id2C IODeferred i
    type2C' (PointerTo t) = liftM (<> text "*") $ type2C t
    type2C' (RecordType tvs union) = do
        t <- withState' id $ mapM (tvar2C False) tvs
        return $ lbrace $+$ (nest 4 . vcat $ t) $+$ rbrace
    type2C' (RangeType r) = return $ text "<<range type>>"
    type2C' (Sequence ids) = do
        mapM_ (id2C IOInsert) ids
        return $ text "<<sequence type>>"
    type2C' (ArrayDecl r t) = do
        t' <- type2C t
        return $ t' <> brackets (text "<<range>>")
    type2C' (Set t) = return $ text "<<set>>"
    type2C' (FunctionType returnType params) = return $ text "<<function>>"
    type2C' (DeriveType (InitBinOp {})) = return $ text "int"
    type2C' (DeriveType (InitPrefixOp _ i)) = type2C' (DeriveType i)
    type2C' (DeriveType (InitNumber _)) = return $ text "int"
    type2C' (DeriveType (InitHexNumber _)) = return $ text "int"
    type2C' (DeriveType (InitFloat _)) = return $ text "float"
    type2C' (DeriveType (BuiltInFunction {})) = return $ text "int"
    type2C' (DeriveType (InitString {})) = return $ text "string255"
    type2C' (DeriveType (InitReference {})) = return $ text "<<some type>>"
    type2C' (DeriveType a) = error $ "Can't derive type from " ++ show a

phrase2C :: Phrase -> State RenderState Doc
phrase2C (Phrases p) = do
    ps <- mapM phrase2C p
    return $ text "{" $+$ (nest 4 . vcat $ ps) $+$ text "}"
phrase2C (ProcCall f@(FunCall {}) []) = liftM (<> semi) $ ref2C f
phrase2C (ProcCall ref params) = do
    r <- ref2C ref
    ps <- mapM expr2C params
    return $ r <> parens (hsep . punctuate (char ',') $ ps) <> semi
phrase2C (IfThenElse (expr) phrase1 mphrase2) = do
    e <- expr2C expr
    p1 <- (phrase2C . wrapPhrase) phrase1
    el <- elsePart
    return $ 
        text "if" <> parens e $+$ p1 $+$ el
    where
    elsePart | isNothing mphrase2 = return $ empty
             | otherwise = liftM (text "else" $$) $ (phrase2C . wrapPhrase) (fromJust mphrase2)
phrase2C (Assignment ref expr) = do
    r <- ref2C ref 
    e <- expr2C expr
    return $
        r <> text " = " <> e <> semi
phrase2C (WhileCycle expr phrase) = do
    e <- expr2C expr
    p <- phrase2C $ wrapPhrase phrase
    return $ text "while" <> parens e $$ p
phrase2C (SwitchCase expr cases mphrase) = do
    e <- expr2C expr
    cs <- mapM case2C cases
    return $ 
        text "switch" <> parens e <> text "of" $+$ (nest 4 . vcat) cs
    where
    case2C :: ([InitExpression], Phrase) -> State RenderState Doc
    case2C (e, p) = do
        ie <- mapM initExpr2C e
        ph <- phrase2C p
        return $ 
            text "case" <+> parens (hsep . punctuate (char ',') $ ie) <> char ':' <> nest 4 (ph $+$ text "break;")
phrase2C wb@(WithBlock ref p) = do
    r <- ref2C ref 
    t <- gets lastType
    case t of
        (BTRecord rs) -> withRecordNamespace (render r ++ ".") rs $ phrase2C $ wrapPhrase p
        a -> do
            ns <- gets currentScope
            error $ "'with' block referencing non-record type " ++ show a ++ "\n" ++ show wb ++ "\nnamespace: " ++ show (take 100 ns)
phrase2C (ForCycle i' e1' e2' p) = do
    i <- id2C IOLookup i'
    e1 <- expr2C e1'
    e2 <- expr2C e2'
    ph <- phrase2C (wrapPhrase p)
    return $ 
        text "for" <> (parens . hsep . punctuate (char ';') $ [i <+> text "=" <+> e1, i <+> text "<=" <+> e2, text "++" <> i])
        $$
        ph
phrase2C (RepeatCycle e' p') = do
    e <- expr2C e'
    p <- phrase2C (Phrases p')
    return $ text "do" <+> p <+> text "while" <> parens (text "!" <> parens e)
phrase2C NOP = return $ text ";"


wrapPhrase p@(Phrases _) = p
wrapPhrase p = Phrases [p]


expr2C :: Expression -> State RenderState Doc
expr2C (Expression s) = return $ text s
expr2C (BinOp op expr1 expr2) = do
    e1 <- expr2C expr1
    e2 <- expr2C expr2
    o <- op2C op
    return $ parens $ e1 <+> o <+> e2
expr2C (NumberLiteral s) = return $ text s
expr2C (FloatLiteral s) = return $ text s
expr2C (HexNumber s) = return $ text "0x" <> (text . map toLower $ s)
expr2C (StringLiteral s) = return $ doubleQuotes $ text s 
expr2C (Reference ref) = ref2C ref
expr2C (PrefixOp op expr) = liftM2 (<>) (op2C op) (expr2C expr)
expr2C Null = return $ text "NULL"
expr2C (BuiltInFunCall params ref) = do
    r <- ref2C ref 
    ps <- mapM expr2C params
    return $ 
        r <> parens (hsep . punctuate (char ',') $ ps)
expr2C (CharCode a) = return $ quotes $ text "\\x" <> text (showHex (read a) "")
expr2C (HexCharCode a) = return $ quotes $ text "\\x" <> text (map toLower a)
expr2C (SetExpression ids) = mapM (id2C IOLookup) ids >>= return . parens . hcat . punctuate (text " | ")
expr2C a = error $ "Don't know how to render " ++ show a


ref2C :: Reference -> State RenderState Doc
-- rewrite into proper form
ref2C (RecordField ref1 (ArrayElement exprs ref2)) = ref2C $ ArrayElement exprs (RecordField ref1 ref2)
ref2C (RecordField ref1 (Dereference ref2)) = ref2C $ Dereference (RecordField ref1 ref2)
ref2C (RecordField ref1 (RecordField ref2 ref3)) = ref2C $ RecordField (RecordField ref1 ref2) ref3
ref2C (RecordField ref1 (FunCall params ref2)) = ref2C $ FunCall params (RecordField ref1 ref2)
ref2C (ArrayElement (a:b:xs) ref) = ref2C $ ArrayElement (b:xs) (ArrayElement [a] ref)
-- conversion routines
ref2C ae@(ArrayElement exprs ref) = do
    es <- mapM expr2C exprs
    r <- ref2C ref 
    t <- gets lastType
    ns <- gets currentScope
    case t of
         (BTArray _ t') -> modify (\st -> st{lastType = t'})
         (BTString) -> modify (\st -> st{lastType = BTChar})
         a -> error $ "Getting element of " ++ show a ++ "\nReference: " ++ show ae ++ "\n" ++ show (take 100 ns)
    return $ r <> (brackets . hcat) (punctuate comma es)
ref2C (SimpleReference name) = id2C IOLookup name
ref2C rf@(RecordField (Dereference ref1) ref2) = do
    r1 <- ref2C ref1 
    t <- fromPointer (show ref1) =<< gets lastType
    ns <- gets currentScope
    r2 <- case t of
        BTRecord rs -> withRecordNamespace "" rs $ ref2C ref2
        BTUnit -> withLastIdNamespace $ ref2C ref2
        a -> error $ "dereferencing from " ++ show a ++ "\n" ++ show rf ++ "\n" ++ show (take 100 ns)
    return $ 
        r1 <> text "->" <> r2
ref2C rf@(RecordField ref1 ref2) = do
    r1 <- ref2C ref1
    t <- gets lastType
    ns <- gets currentScope
    r2 <- case t of
        BTRecord rs -> withRecordNamespace "" rs $ ref2C ref2
        BTUnit -> withLastIdNamespace $ ref2C ref2
        a -> error $ "dereferencing from " ++ show a ++ "\n" ++ show rf ++ "\n" ++ show (take 100 ns)
    return $ 
        r1 <> text "." <> r2
ref2C d@(Dereference ref) = do
    r <- ref2C ref
    t <- fromPointer (show d) =<< gets lastType
    modify (\st -> st{lastType = t})
    return $ (parens $ text "*" <> r)
ref2C (FunCall params ref) = do
    ps <- liftM (parens . hsep . punctuate (char ',')) $ mapM expr2C params
    r <- ref2C ref
    t <- gets lastType
    case t of
        BTFunction t -> do
            modify (\s -> s{lastType = t})
            return $ r <> ps
        _ -> return $ parens r <> ps
        
ref2C (Address ref) = do
    r <- ref2C ref
    return $ text "&" <> parens r
ref2C (TypeCast t' expr) = do
    t <- id2C IOLookup t'
    e <- expr2C expr
    return $ parens t <> e
ref2C (RefExpression expr) = expr2C expr


op2C :: String -> State RenderState Doc
op2C "or" = return $ text "|"
op2C "and" = return $ text "&"
op2C "not" = return $ text "!"
op2C "xor" = return $ text "^"
op2C "div" = return $ text "/"
op2C "mod" = return $ text "%"
op2C "shl" = return $ text "<<"
op2C "shr" = return $ text ">>"
op2C "<>" = return $ text "!="
op2C "=" = return $ text "=="
op2C a = return $ text a

