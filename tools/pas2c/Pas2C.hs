{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE FlexibleContexts #-}
module Pas2C where

import Text.PrettyPrint.HughesPJ
import Data.Maybe
import Data.Char
import Text.Parsec.Prim hiding (State)
import Control.Monad.State
import System.IO
import PascalPreprocessor
import Control.Exception
import System.IO.Error
import qualified Data.Map as Map
import qualified Data.Set as Set
import Data.List (find)
import Numeric

import PascalParser
import PascalUnitSyntaxTree


data InsertOption =
    IOInsert
    | IOInsertWithType Doc
    | IOLookup
    | IOLookupLast
    | IOLookupFunction Int
    | IODeferred

data Record = Record
    {
        lcaseId :: String,
        baseType :: BaseType,
        typeDecl :: Doc
    }
    deriving Show
type Records = Map.Map String [Record]
data RenderState = RenderState
    {
        currentScope :: Records,
        lastIdentifier :: String,
        lastType :: BaseType,
        isFunctionType :: Bool, -- set to true if the current function parameter is functiontype
        lastIdTypeDecl :: Doc,
        stringConsts :: [(String, String)],
        uniqCounter :: Int,
        toMangle :: Set.Set String,
        enums :: [(String, [String])], -- store all declared enums
        currentUnit :: String,
        currentFunctionResult :: String,
        namespaces :: Map.Map String Records
    }

rec2Records :: [(String, BaseType)] -> [Record]
rec2Records = map (\(a, b) -> Record a b empty)

emptyState :: Map.Map String Records -> RenderState
emptyState = RenderState Map.empty "" BTUnknown False empty [] 0 Set.empty [] "" ""

getUniq :: State RenderState Int
getUniq = do
    i <- gets uniqCounter
    modify(\s -> s{uniqCounter = uniqCounter s + 1})
    return i

addStringConst :: String -> State RenderState Doc
addStringConst str = do
    strs <- gets stringConsts
    let a = find ((==) str . snd) strs
    if isJust a then
        do
        modify (\s -> s{lastType = BTString})
        return . text . fst . fromJust $ a
    else
        do
        i <- getUniq
        let sn = "__str" ++ show i
        modify (\s -> s{lastType = BTString, stringConsts = (sn, str) : strs})
        return $ text sn

escapeStr :: String -> String
escapeStr = foldr escapeChar []

escapeChar :: Char -> ShowS
escapeChar '"' s = "\\\"" ++ s
escapeChar '\\' s = "\\\\" ++ s
escapeChar a s = a : s

strInit :: String -> Doc
strInit a = text "STRINIT" <> parens (doubleQuotes (text $ escapeStr a))

renderStringConsts :: State RenderState Doc
renderStringConsts = liftM (vcat . map (\(a, b) -> text "static const string255" <+> (text a) <+> text "=" <+> strInit b <> semi))
    $ gets stringConsts

docToLower :: Doc -> Doc
docToLower = text . map toLower . render

pas2C :: String -> String -> String -> String -> [String] -> IO ()
pas2C fn inputPath outputPath alternateInputPath symbols = do
    s <- flip execStateT initState $ f fn
    renderCFiles s outputPath
    where
    printLn = liftIO . hPutStrLn stdout
    print' = liftIO . hPutStr stdout
    initState = Map.empty
    f :: String -> StateT (Map.Map String PascalUnit) IO ()
    f fileName = do
        processed <- gets $ Map.member fileName
        unless processed $ do
            print' ("Preprocessing '" ++ fileName ++ ".pas'... ")
            fc' <- liftIO
                $ tryJust (guard . isDoesNotExistError)
                $ preprocess inputPath alternateInputPath (fileName ++ ".pas") symbols
            case fc' of
                (Left _) -> do
                    modify (Map.insert fileName (System []))
                    printLn "doesn't exist"
                (Right fc) -> do
                    print' "ok, parsing... "
                    let ptree = parse pascalUnit fileName fc
                    case ptree of
                         (Left a) -> do
                            liftIO $ writeFile (outputPath ++ fileName ++ "preprocess.out") fc
                            printLn $ show a ++ "\nsee preprocess.out for preprocessed source"
                            fail "stop"
                         (Right a) -> do
                            printLn "ok"
                            modify (Map.insert fileName a)
                            mapM_ f (usesFiles a)


renderCFiles :: Map.Map String PascalUnit -> String -> IO ()
renderCFiles units outputPath = do
    let u = Map.toList units
    let nss = Map.map (toNamespace nss) units
    --hPutStrLn stderr $ "Units: " ++ (show . Map.keys . Map.filter (not . Map.null) $ nss)
    --writeFile "pas2c.log" $ unlines . map (\t -> show (fst t) ++ "\n" ++ (unlines . map ((:) '\t' . show) . snd $ t)) . Map.toList $ nss
    mapM_ (toCFiles outputPath nss) u
    where
    toNamespace :: Map.Map String Records -> PascalUnit -> Records
    toNamespace nss (System tvs) =
        currentScope $ execState f (emptyState nss)
        where
        f = do
            checkDuplicateFunDecls tvs
            mapM_ (tvar2C True False True False) tvs
    toNamespace nss (Redo tvs) = -- functions that are re-implemented, add prefix to all of them
        currentScope $ execState f (emptyState nss){currentUnit = "fpcrtl_"}
        where
        f = do
            checkDuplicateFunDecls tvs
            mapM_ (tvar2C True False True False) tvs
    toNamespace _ (Program {}) = Map.empty
    toNamespace nss (Unit (Identifier i _) interface _ _ _) =
        currentScope $ execState (interface2C interface True) (emptyState nss){currentUnit = map toLower i ++ "_"}

withState' :: (RenderState -> RenderState) -> State RenderState a -> State RenderState a
withState' f sf = do
    st <- liftM f get
    let (a, s) = runState sf st
    modify(\st' -> st'{
        lastType = lastType s
        , uniqCounter = uniqCounter s
        , stringConsts = stringConsts s
        })
    return a

withLastIdNamespace :: State RenderState Doc -> State RenderState Doc
withLastIdNamespace f = do
    li <- gets lastIdentifier
    withState' (\st -> st{currentScope = fromMaybe Map.empty $ Map.lookup li (namespaces st)}) f

withRecordNamespace :: String -> [Record] -> State RenderState Doc -> State RenderState Doc
withRecordNamespace _ [] = error "withRecordNamespace: empty record"
withRecordNamespace prefix recs = withState' f
    where
        f st = st{currentScope = Map.unionWith un records (currentScope st), currentUnit = ""}
        records = Map.fromList $ map (\(Record a b d) -> (map toLower a, [Record (prefix ++ a) b d])) recs
        un [a] b = a : b
        un _ _ = error "withRecordNamespace un: pattern not matched"

toCFiles :: String -> Map.Map String Records -> (String, PascalUnit) -> IO ()
toCFiles _ _ (_, System _) = return ()
toCFiles _ _ (_, Redo _) = return ()
toCFiles outputPath ns pu@(fileName, _) = do
    hPutStrLn stdout $ "Rendering '" ++ fileName ++ "'..."
    toCFiles' pu
    where
    toCFiles' (fn, p@(Program {})) = writeFile (outputPath ++ fn ++ ".c") $ "#include \"fpcrtl.h\"\n" ++ (render2C initialState . pascal2C) p
    toCFiles' (fn, (Unit unitId@(Identifier i _) interface implementation _ _)) = do
        let (a, s) = runState (id2C IOInsert (setBaseType BTUnit unitId) >> interface2C interface True) initialState{currentUnit = map toLower i ++ "_"}
            (a', _) = runState (id2C IOInsert (setBaseType BTUnit unitId) >> interface2C interface False) initialState{currentUnit = map toLower i ++ "_"}
            enumDecl = (renderEnum2Strs (enums s) False)
            enumImpl = (renderEnum2Strs (enums s) True)
        writeFile (outputPath ++ fn ++ ".h") $ "#pragma once\n\n#include \"pas2c.h\"\n\n" ++ (render (a $+$ text "")) ++ "\n" ++ enumDecl
        writeFile (outputPath ++ fn ++ ".c") $ "#include \"fpcrtl.h\"\n\n#include \"" ++ fn ++ ".h\"\n" ++ render (a' $+$ text "") ++ (render2C s . implementation2C) implementation ++ "\n" ++ enumImpl
    toCFiles' _ = undefined -- just pleasing compiler to not warn us
    initialState = emptyState ns

    render2C :: RenderState -> State RenderState Doc -> String
    render2C st p =
        let (a, _) = runState p st in
        render a

renderEnum2Strs :: [(String, [String])] -> Bool -> String
renderEnum2Strs enums' implement =
    render $ foldl ($+$) empty $ map (\en -> let d = decl (fst en) in if implement then d $+$ enum2strBlock (snd en) else d <> semi) enums'
    where
    decl id' = text "string255 __attribute__((overloadable)) fpcrtl_GetEnumName" <> parens (text "int dummy, const" <+> text id' <+> text "enumvar")
    enum2strBlock en =
            text "{"
            $+$
            (nest 4 $
                text "switch(enumvar){"
                $+$
                (foldl ($+$) empty $ map (\e -> text "case" <+> text e <> colon $+$ (nest 4 $ text "return fpcrtl_make_string" <> (parens $ doubleQuotes $ text e) <> semi $+$ text "break;")) en)
                $+$
                text "default: assert(0);"
                $+$
                (nest 4 $ text "return fpcrtl_make_string(\"nonsense\");")
                $+$
                text "}"
            )
            $+$
            text "}"

usesFiles :: PascalUnit -> [String]
usesFiles (Program _ (Implementation uses _) _) = ["pas2cSystem", "pas2cRedo"] ++ uses2List uses
usesFiles (Unit _ (Interface uses1 _) (Implementation uses2 _) _ _) = ["pas2cSystem", "pas2cRedo"] ++ uses2List uses1 ++ uses2List uses2
usesFiles (System {}) = []
usesFiles (Redo {}) = []

pascal2C :: PascalUnit -> State RenderState Doc
pascal2C (Unit _ interface implementation _ _) =
    liftM2 ($+$) (interface2C interface True) (implementation2C implementation)

pascal2C (Program _ implementation mainFunction) = do
    impl <- implementation2C implementation
    [main] <- tvar2C True False True True 
        (FunctionDeclaration (Identifier "main" (BTInt True)) False False False (SimpleType $ Identifier "int" (BTInt True)) 
            [VarDeclaration False False ([Identifier "argc" (BTInt True)], SimpleType (Identifier "Integer" (BTInt True))) Nothing
            , VarDeclaration False False ([Identifier "argv" BTUnknown], SimpleType (Identifier "PPChar" BTUnknown)) Nothing] 
        (Just (TypesAndVars [], Phrases [mainResultInit, mainFunction])))

    return $ impl $+$ main

pascal2C _ = error "pascal2C: pattern not matched"

-- the second bool indicates whether do normal interface translation or generate variable declarations
-- that will be inserted into implementation files
interface2C :: Interface -> Bool -> State RenderState Doc
interface2C (Interface uses tvars) True = do
    u <- uses2C uses
    tv <- typesAndVars2C True True True tvars
    r <- renderStringConsts
    return (u $+$ r $+$ tv)
interface2C (Interface uses tvars) False = do
    void $ uses2C uses
    tv <- typesAndVars2C True False False tvars
    void $ renderStringConsts
    return tv

implementation2C :: Implementation -> State RenderState Doc
implementation2C (Implementation uses tvars) = do
    u <- uses2C uses
    tv <- typesAndVars2C True False True tvars
    r <- renderStringConsts
    return (u $+$ r $+$ tv)

checkDuplicateFunDecls :: [TypeVarDeclaration] -> State RenderState ()
checkDuplicateFunDecls tvs =
    modify $ \s -> s{toMangle = Map.keysSet . Map.filter (> 1) . foldr ins initMap $ tvs}
    where
        initMap :: Map.Map String Int
        initMap = Map.empty
        --initMap = Map.fromList [("reset", 2)]
        ins (FunctionDeclaration (Identifier i _) _ _ _ _ _ _) m = Map.insertWith (+) (map toLower i) 1 m
        ins _ m = m

-- the second bool indicates whether declare variable as extern or not
-- the third bool indicates whether include types or not

typesAndVars2C :: Bool -> Bool -> Bool -> TypesAndVars -> State RenderState Doc
typesAndVars2C b externVar includeType(TypesAndVars ts) = do
    checkDuplicateFunDecls ts
    liftM (vcat . map (<> semi) . concat) $ mapM (tvar2C b externVar includeType False) ts

setBaseType :: BaseType -> Identifier -> Identifier
setBaseType bt (Identifier i _) = Identifier i bt

uses2C :: Uses -> State RenderState Doc
uses2C uses@(Uses unitIds) = do

    mapM_ injectNamespace (Identifier "pas2cSystem" undefined : unitIds)
    mapM_ injectNamespace (Identifier "pas2cRedo" undefined : unitIds)
    mapM_ (id2C IOInsert . setBaseType BTUnit) unitIds
    return $ vcat . map (\i -> text $ "#include \"" ++ i ++ ".h\"") $ uses2List uses
    where
    injectNamespace (Identifier i _) = do
        getNS <- gets (flip Map.lookup . namespaces)
        modify (\s -> s{currentScope = Map.unionWith (++) (fromMaybe Map.empty (getNS i)) $ currentScope s})

uses2List :: Uses -> [String]
uses2List (Uses ids) = map (\(Identifier i _) -> i) ids


setLastIdValues :: Record -> RenderState -> RenderState
setLastIdValues vv = (\s -> s{lastType = baseType vv, lastIdentifier = lcaseId vv, lastIdTypeDecl = typeDecl vv})

id2C :: InsertOption -> Identifier -> State RenderState Doc
id2C IOInsert i = id2C (IOInsertWithType empty) i
id2C (IOInsertWithType d) (Identifier i t) = do
    tom <- gets (Set.member n . toMangle)
    cu <- gets currentUnit
    let (i', t') = case (t, tom) of
            (BTFunction _ e p _, True) -> ((if e then id else (++) cu) $ i ++ ('_' : show (length p)), t)
            (BTFunction _ e _ _, _) -> ((if e then id else (++) cu) i, t)
            (BTVarParam t'', _) -> ('(' : '*' : i ++ ")" , t'')
            _ -> (i, t)
    modify (\s -> s{currentScope = Map.insertWith (++) n [Record i' t' d] (currentScope s), lastIdentifier = n})
    return $ text i'
    where
        n = map toLower i

id2C IOLookup i = id2CLookup head i
id2C IOLookupLast i = id2CLookup last i
id2C (IOLookupFunction params) (Identifier i _) = do
    let i' = map toLower i
    v <- gets $ Map.lookup i' . currentScope
    lt <- gets lastType
    if isNothing v then
        error $ "Not defined: '" ++ i' ++ "'\n" ++ show lt ++ "\nwith num of params = " ++ show params ++ "\n" ++ show v
        else
        let vv = fromMaybe (head $ fromJust v) . find checkParam $ fromJust v in
            modify (setLastIdValues vv) >> (return . text . lcaseId $ vv)
    where
        checkParam (Record _ (BTFunction _ _ p _) _) = (length p) == params
        checkParam _ = False
id2C IODeferred (Identifier i _) = do
    let i' = map toLower i
    v <- gets $ Map.lookup i' . currentScope
    if (isNothing v) then
        modify (\s -> s{lastType = BTUnknown, lastIdentifier = i}) >> return (text i)
        else
        let vv = head $ fromJust v in modify (setLastIdValues vv) >> (return . text . lcaseId $ vv)

id2CLookup :: ([Record] -> Record) -> Identifier -> State RenderState Doc
id2CLookup f (Identifier i _) = do
    let i' = map toLower i
    v <- gets $ Map.lookup i' . currentScope
    lt <- gets lastType
    if isNothing v then
        error $ "Not defined: '" ++ i' ++ "'\n" ++ show lt
        else
        let vv = f $ fromJust v in modify (setLastIdValues vv) >> (return . text . lcaseId $ vv)



id2CTyped :: TypeDecl -> Identifier -> State RenderState Doc
id2CTyped = id2CTyped2 Nothing

id2CTyped2 :: Maybe Doc -> TypeDecl -> Identifier -> State RenderState Doc
id2CTyped2 md t (Identifier i _) = do
    tb <- resolveType t
    case (t, tb) of
        (_, BTUnknown) -> do
            error $ "id2CTyped: type BTUnknown for " ++ show i ++ "\ntype: " ++ show t
        (SimpleType {}, BTRecord _ r) -> do
            ts <- type2C t
            id2C (IOInsertWithType $ ts empty) (Identifier i (BTRecord (render $ ts empty) r))
        (_, BTRecord _ r) -> do
            ts <- type2C t
            id2C (IOInsertWithType $ ts empty) (Identifier i (BTRecord i r))
        _ -> case md of
                Nothing -> id2C IOInsert (Identifier i tb)
                Just ts -> id2C (IOInsertWithType ts) (Identifier i tb)

typeVarDecl2BaseType :: [TypeVarDeclaration] -> State RenderState [(Bool, BaseType)]
typeVarDecl2BaseType d = do
    st <- get
    result <- sequence $ concat $ map resolveType' d
    put st -- restore state (not sure if necessary)
    return result
    where
        resolveType' :: TypeVarDeclaration -> [State RenderState (Bool, BaseType)]
        resolveType' (VarDeclaration isVar _ (ids, t) _) = replicate (length ids) (resolveTypeHelper' (resolveType t) isVar)
        resolveType' _ = error "typeVarDecl2BaseType: not a VarDeclaration"
        resolveTypeHelper' :: State RenderState BaseType -> Bool -> State RenderState (Bool, BaseType)
        resolveTypeHelper' st b = do
            bt <- st
            return (b, bt)

resolveType :: TypeDecl -> State RenderState BaseType
resolveType st@(SimpleType (Identifier i _)) = do
    let i' = map toLower i
    v <- gets $ Map.lookup i' . currentScope
    if isJust v then return . baseType . head $ fromJust v else return $ f i'
    where
    f "uinteger" = BTInt False
    f "integer" = BTInt True
    f "pointer" = BTPointerTo BTVoid
    f "boolean" = BTBool
    f "float" = BTFloat
    f "char" = BTChar
    f "string" = BTString
    f "ansistring" = BTAString
    f _ = error $ "Unknown system type: " ++ show st
resolveType (PointerTo (SimpleType (Identifier i _))) = return . BTPointerTo $ BTUnresolved (map toLower i)
resolveType (PointerTo t) = liftM BTPointerTo $ resolveType t
resolveType (RecordType tv mtvs) = do
    tvs <- mapM f (concat $ tv : fromMaybe [] mtvs)
    return . BTRecord "" . concat $ tvs
    where
        f :: TypeVarDeclaration -> State RenderState [(String, BaseType)]
        f (VarDeclaration _ _ (ids, td) _) = mapM (\(Identifier i _) -> liftM ((,) i) $ resolveType td) ids
        f _ = error "resolveType f: pattern not matched"
resolveType (ArrayDecl (Just i) t) = do
    t' <- resolveType t
    return $ BTArray i (BTInt True) t'
resolveType (ArrayDecl Nothing t) = liftM (BTArray RangeInfinite (BTInt True)) $ resolveType t
resolveType (FunctionType t a) = do
    bts <- typeVarDecl2BaseType a
    liftM (BTFunction False False bts) $ resolveType t
resolveType (DeriveType (InitHexNumber _)) = return (BTInt True)
resolveType (DeriveType (InitNumber _)) = return (BTInt True)
resolveType (DeriveType (InitFloat _)) = return BTFloat
resolveType (DeriveType (InitString _)) = return BTString
resolveType (DeriveType (InitBinOp {})) = return (BTInt True)
resolveType (DeriveType (InitPrefixOp _ e)) = initExpr2C e >> gets lastType
resolveType (DeriveType (BuiltInFunction{})) = return (BTInt True)
resolveType (DeriveType (InitReference (Identifier{}))) = return BTBool -- TODO: derive from actual type
resolveType (DeriveType _) = return BTUnknown
resolveType String = return BTString
resolveType AString = return BTAString
resolveType VoidType = return BTVoid
resolveType (Sequence ids) = return $ BTEnum $ map (\(Identifier i _) -> map toLower i) ids
resolveType (RangeType _) = return $ BTVoid
resolveType (Set t) = liftM BTSet $ resolveType t
resolveType (VarParamType t) = liftM BTVarParam $ resolveType t


resolve :: String -> BaseType -> State RenderState BaseType
resolve s (BTUnresolved t) = do
    v <- gets $ Map.lookup t . currentScope
    if isJust v then
        resolve s . baseType . head . fromJust $ v
        else
        error $ "Unknown type " ++ show t ++ "\n" ++ s
resolve _ t = return t

fromPointer :: String -> BaseType -> State RenderState BaseType
fromPointer s (BTPointerTo t) = resolve s t
fromPointer s t = do
    error $ "Dereferencing from non-pointer type " ++ show t ++ "\n" ++ s


functionParams2C :: [TypeVarDeclaration] -> State RenderState Doc
functionParams2C params = liftM (hcat . punctuate comma . concat) $ mapM (tvar2C False False True True) params

numberOfDeclarations :: [TypeVarDeclaration] -> Int
numberOfDeclarations = sum . map cnt
    where
        cnt (VarDeclaration _ _ (ids, _) _) = length ids
        cnt _ = 1

hasPassByReference :: [TypeVarDeclaration] -> Bool
hasPassByReference = or . map isVar
    where
        isVar (VarDeclaration v _ (_, _) _) = v
        isVar _ = error $ "hasPassByReference called not on function parameters"

toIsVarList :: [TypeVarDeclaration] -> [Bool]
toIsVarList = concatMap isVar
    where
        isVar (VarDeclaration v _ (p, _) _) = replicate (length p) v
        isVar _ = error $ "toIsVarList called not on function parameters"


funWithVarsToDefine :: String -> [TypeVarDeclaration] -> Doc
funWithVarsToDefine n params = text "#define" <+> text n <> parens abc <+> text (n ++ "__vars") <> parens cparams
    where
        abc = hcat . punctuate comma . map (char . fst) $ ps
        cparams = hcat . punctuate comma . map (\(c, v) -> if v then char '&' <> parens (char c) else char c) $ ps
        ps = zip ['a'..] (toIsVarList params)

fun2C :: Bool -> String -> TypeVarDeclaration -> State RenderState [Doc]
fun2C _ _ (FunctionDeclaration name _ overload external returnType params Nothing) = do
    t <- type2C returnType
    t'<- gets lastType
    bts <- typeVarDecl2BaseType params
    p <- withState' id $ functionParams2C params
    n <- liftM render . id2C IOInsert $ setBaseType (BTFunction False external bts t') name
    let decor = if overload then text "__attribute__((overloadable))" else empty
    return [t empty <+> decor <+> text n <> parens p]

fun2C True rv (FunctionDeclaration name@(Identifier i _) inline overload external returnType params (Just (tvars, phrase))) = do
    let isVoid = case returnType of
            VoidType -> True
            _ -> False

    let res = docToLower $ text rv <> if isVoid then empty else text "_result"
    t <- type2C returnType
    t' <- gets lastType

    bts <- typeVarDecl2BaseType params
    --cu <- gets currentUnit
    notDeclared <- liftM isNothing . gets $ Map.lookup (map toLower i) . currentScope

    n <- liftM render . id2C IOInsert $ setBaseType (BTFunction hasVars external bts t') name
    let resultId = if isVoid
                    then n -- void type doesn't have result, solving recursive procedure calls
                    else (render res)

    (p, ph) <- withState' (\st -> st{currentScope = Map.insertWith un (map toLower rv) [Record resultId (if isVoid then (BTFunction hasVars False bts t') else t') empty] $ currentScope st
            , currentFunctionResult = if isVoid then [] else render res}) $ do
        p <- functionParams2C params
        ph <- liftM2 ($+$) (typesAndVars2C False False True tvars) (phrase2C' phrase)
        return (p, ph)

    let isTrivialReturn = case phrase of
         (Phrases (BuiltInFunctionCall _ (SimpleReference (Identifier "exit" BTUnknown)) : _)) -> True
         _ -> False
    let phrasesBlock = if isVoid || isTrivialReturn then ph else t empty <+> res <> semi $+$ ph $+$ text "return" <+> res <> semi
    --let define = if hasVars then text "#ifndef" <+> text n $+$ funWithVarsToDefine n params $+$ text "#endif" else empty
    let inlineDecor = if inline then case notDeclared of
                                    True -> text "static inline"
                                    False -> text "inline"
                          else empty
        overloadDecor = if overload then text "__attribute__((overloadable))" else empty
    return [
        --define
        -- $+$
        --(if notDeclared && hasVars then funWithVarsToDefine n params else empty) $+$
        inlineDecor <+> t empty <+> overloadDecor <+> text n <> parens p
        $+$
        text "{"
        $+$
        nest 4 phrasesBlock
        $+$
        text "}"]
    where
    phrase2C' (Phrases p) = liftM vcat $ mapM phrase2C p
    phrase2C' p = phrase2C p
    un [a] b = a : b
    un _ _ = error "fun2C u: pattern not matched"
    hasVars = hasPassByReference params

fun2C False _ (FunctionDeclaration (Identifier name _) _ _ _ _ _ _) = error $ "nested functions not allowed: " ++ name
fun2C _ tv _ = error $ "fun2C: I don't render " ++ show tv

-- the second bool indicates whether declare variable as extern or not
-- the third bool indicates whether include types or not
-- the fourth bool indicates whether ignore initialization or not (basically for dynamic arrays since we cannot do initialization in function params)
tvar2C :: Bool -> Bool -> Bool -> Bool -> TypeVarDeclaration -> State RenderState [Doc]
tvar2C b _ includeType _ f@(FunctionDeclaration (Identifier name _) _ _ _ _ _ _) = do
    t <- fun2C b name f
    if includeType then return t else return []
tvar2C _ _ includeType _ (TypeDeclaration i' t) = do
    i <- id2CTyped t i'
    tp <- type2C t
    let res = if includeType then [text "typedef" <+> tp i] else []
    case t of
        (Sequence ids) -> do
            modify(\s -> s{enums = (render i, map (\(Identifier id' _) -> id') ids) : enums s})
            return res
        _ -> return res

tvar2C _ _ _ _ (VarDeclaration True _ (ids, t) Nothing) = do
    t' <- liftM ((empty <+>) . ) $ type2C t
    liftM (map(\i -> t' i)) $ mapM (id2CTyped2 (Just $ t' empty) (VarParamType t)) ids

tvar2C _ externVar includeType ignoreInit (VarDeclaration _ isConst (ids, t) mInitExpr) = do
    t' <- liftM (((if isConst then text "static const" else if externVar
                                                                then text "extern"
                                                                else empty)
                   <+>) . ) $ type2C t
    ie <- initExpr mInitExpr
    lt <- gets lastType
    case (isConst, lt, ids, mInitExpr) of
         (True, BTInt _, [i], Just _) -> do
             i' <- id2CTyped t i
             return $ if includeType then [text "enum" <> braces (i' <+> ie)] else []
         (True, BTFloat, [i], Just e) -> do
             i' <- id2CTyped t i
             ie' <- initExpr2C e
             return $ if includeType then [text "#define" <+> i' <+> parens ie' <> text "\n"] else []
         (_, BTFunction{}, _, Nothing) -> liftM (map(\i -> t' i)) $ mapM (id2CTyped t) ids
         (_, BTArray r _ _, [i], _) -> do
            i' <- id2CTyped t i
            ie' <- return $ case (r, mInitExpr, ignoreInit) of
                (RangeInfinite, Nothing, False) -> text "= NULL" -- force dynamic array to be initialized as NULL if not initialized at all
                (_, _, _) -> ie
            result <- liftM (map(\id' -> varDeclDecision isConst includeType (t' id') ie')) $ mapM (id2CTyped t) ids
            case (r, ignoreInit) of
                (RangeInfinite, False) ->
                    -- if the array is dynamic, add dimension info to it
                    return $ [dimDecl] ++ result
                    where
                        arrayDimStr = show $ arrayDimension t
                        arrayDimInitExp = text ("={" ++ ".dim = " ++ arrayDimStr ++ ", .a = {0, 0, 0, 0}}")
                        dimDecl = varDeclDecision isConst includeType (text "fpcrtl_dimension_t" <+>  i' <> text "_dimension_info") arrayDimInitExp

                (_, _) -> return result

         _ -> liftM (map(\i -> varDeclDecision isConst includeType (t' i) ie)) $ mapM (id2CTyped2 (Just $ t' empty) t) ids
    where
    initExpr Nothing = return $ empty
    initExpr (Just e) = liftM (text "=" <+>) (initExpr2C e)
    varDeclDecision True True varStr expStr = varStr <+> expStr
    varDeclDecision False True varStr expStr = if externVar then varStr else varStr <+> expStr
    varDeclDecision False False varStr expStr = varStr <+> expStr
    varDeclDecision True False _ _ = empty
    arrayDimension a = case a of
        ArrayDecl Nothing t' -> let a' = arrayDimension t' in 
                                   if a' > 3 then error "Dynamic array with dimension > 4 is not supported." else 1 + a'
        ArrayDecl _ _ -> error "Mixed dynamic array and static array are not supported."
        _ -> 0

tvar2C f _ _ _ (OperatorDeclaration op (Identifier i _) inline ret params body) = do
    r <- op2CTyped op (extractTypes params)
    fun2C f i (FunctionDeclaration r inline False False ret params body)


op2CTyped :: String -> [TypeDecl] -> State RenderState Identifier
op2CTyped op t = do
    t' <- liftM (render . hcat . punctuate (char '_') . map (\txt -> txt empty)) $ mapM type2C t
    bt <- gets lastType
    return $ Identifier (t' ++ "_op_" ++ opStr) bt
    where
    opStr = case op of
                    "+" -> "add"
                    "-" -> "sub"
                    "*" -> "mul"
                    "/" -> "div"
                    "/(float)" -> "div"
                    "=" -> "eq"
                    "<" -> "lt"
                    ">" -> "gt"
                    "<>" -> "neq"
                    _ -> error $ "op2CTyped: unknown op '" ++ op ++ "'"

extractTypes :: [TypeVarDeclaration] -> [TypeDecl]
extractTypes = concatMap f
    where
        f (VarDeclaration _ _ (ids, t) _) = replicate (length ids) t
        f a = error $ "extractTypes: can't extract from " ++ show a

initExpr2C, initExpr2C' :: InitExpression -> State RenderState Doc
initExpr2C (InitArray values) = liftM (braces . vcat . punctuate comma) $ mapM initExpr2C values
initExpr2C a = initExpr2C' a
initExpr2C' InitNull = return $ text "NULL"
initExpr2C' (InitAddress expr) = do
    ie <- initExpr2C' expr
    lt <- gets lastType
    case lt of
        BTFunction True _ _ _ -> return $ text "&" <> ie -- <> text "__vars"
        _ -> return $ text "&" <> ie
initExpr2C' (InitPrefixOp op expr) = liftM (text (op2C op) <>) (initExpr2C' expr)
initExpr2C' (InitBinOp op expr1 expr2) = do
    e1 <- initExpr2C' expr1
    e2 <- initExpr2C' expr2
    return $ parens $ e1 <+> text (op2C op) <+> e2
initExpr2C' (InitNumber s) = do
                                modify(\st -> st{lastType = (BTInt True)})
                                return $ text s
initExpr2C' (InitFloat s) = return $ text s
initExpr2C' (InitHexNumber s) = return $ text "0x" <> (text . map toLower $ s)
initExpr2C' (InitString [a]) = return . quotes $ text [a]
initExpr2C' (InitString s) = return $ strInit s
initExpr2C' (InitPChar s) = return $ doubleQuotes (text $ escapeStr s)
initExpr2C' (InitChar a) = return $ text "0x" <> text (showHex (read a) "")
initExpr2C' (InitReference i) = id2C IOLookup i
initExpr2C' (InitRecord fields) = do
    (fs :: [Doc]) <- mapM (\(Identifier a _, b) -> liftM (text "." <> text a <+> equals <+>) $ initExpr2C b) fields
    return $ lbrace $+$ (nest 4 . vcat . punctuate comma $ fs) $+$ rbrace
--initExpr2C' (InitArray [InitRecord fields]) = do
--    e <- initExpr2C $ InitRecord fields
--    return $ braces $ e
initExpr2C' r@(InitRange (Range i@(Identifier i' _))) = do
    void $ id2C IOLookup i
    t <- gets lastType
    case t of
         BTEnum s -> return . int $ length s
         BTInt _ -> case i' of
                       "byte" -> return $ int 256
                       _ -> error $ "InitRange identifier: " ++ i'
         _ -> error $ "InitRange: " ++ show r
initExpr2C' (InitRange (RangeFromTo (InitNumber "0") r)) = initExpr2C $ BuiltInFunction "succ" [r]
initExpr2C' (InitRange (RangeFromTo (InitChar "0") (InitChar r))) = initExpr2C $ BuiltInFunction "succ" [InitNumber r]
initExpr2C' (InitRange a) = error $ show a --return $ text "<<range>>"
initExpr2C' (InitSet []) = return $ text "0"
initExpr2C' (InitSet _) = return $ text "<<set>>"
initExpr2C' (BuiltInFunction "low" [InitReference e]) = return $
    case e of
         (Identifier "LongInt" _) -> int (-2^31)
         (Identifier "SmallInt" _) -> int (-2^15)
         _ -> error $ "BuiltInFunction 'low': " ++ show e
initExpr2C' (BuiltInFunction "high" [e]) = do
    void $ initExpr2C e
    t <- gets lastType
    case t of
         (BTArray i _ _) -> initExpr2C' $ BuiltInFunction "pred" [InitRange i]
         a -> error $ "BuiltInFunction 'high': " ++ show a
initExpr2C' (BuiltInFunction "succ" [BuiltInFunction "pred" [e]]) = initExpr2C' e
initExpr2C' (BuiltInFunction "pred" [BuiltInFunction "succ" [e]]) = initExpr2C' e
initExpr2C' (BuiltInFunction "succ" [e]) = liftM (<> text " + 1") $ initExpr2C' e
initExpr2C' (BuiltInFunction "pred" [e]) = liftM (<> text " - 1") $ initExpr2C' e
initExpr2C' b@(BuiltInFunction _ _) = error $ show b
initExpr2C' (InitTypeCast t' i) = do
    e <- initExpr2C i
    t <- id2C IOLookup t'
    return . parens $ parens t <> e
initExpr2C' a = error $ "initExpr2C: don't know how to render " ++ show a


range2C :: InitExpression -> State RenderState [Doc]
range2C (InitString [a]) = return [quotes $ text [a]]
range2C (InitRange (Range i)) = liftM (flip (:) []) $ id2C IOLookup i
range2C (InitRange (RangeFromTo (InitString [a]) (InitString [b]))) = return $ map (\i -> quotes $ text [i]) [a..b]
range2C a = liftM (flip (:) []) $ initExpr2C a

baseType2C :: String -> BaseType -> Doc
baseType2C _ BTFloat = text "float"
baseType2C _ BTBool = text "bool"
baseType2C _ BTString = text "string255"
baseType2C _ BTAString = text "astring"
baseType2C s a = error $ "baseType2C: " ++ show a ++ "\n" ++ s

type2C :: TypeDecl -> State RenderState (Doc -> Doc)
type2C (SimpleType i) = liftM (\i' a -> i' <+> a) $ id2C IOLookup i
type2C t = do
    r <- type2C' t
    rt <- resolveType t
    modify (\st -> st{lastType = rt})
    return r
    where
    type2C' VoidType = return (text "void" <+>)
    type2C' String = return (text "string255" <+>)--return (text ("string" ++ show l) <+>)
    type2C' AString = return (text "astring" <+>)
    type2C' (PointerTo (SimpleType i)) = do
        i' <- id2C IODeferred i
        lt <- gets lastType
        case lt of
             BTRecord _ _ -> return $ \a -> text "struct __" <> i' <+> text "*" <+> a
             BTUnknown -> return $ \a -> text "struct __" <> i' <+> text "*" <+> a
             _ -> return $ \a -> i' <+> text "*" <+> a
    type2C' (PointerTo t) = liftM (\tx a -> tx (parens $ text "*" <> a)) $ type2C t
    type2C' (RecordType tvs union) = do
        t' <- withState' f $ mapM (tvar2C False False True False) tvs
        u <- unions
        return $ \i -> text "struct __" <> i <+> lbrace $+$ nest 4 ((vcat . map (<> semi) . concat $ t') $$ u) $+$ rbrace <+> i
        where
            f s = s{currentUnit = ""}
            unions = case union of
                     Nothing -> return empty
                     Just a -> do
                         structs <- mapM struct2C a
                         return $ text "union" $+$ braces (nest 4 $ vcat structs) <> semi
            struct2C stvs = do
                txts <- withState' f $ mapM (tvar2C False False True False) stvs
                return $ text "struct" $+$ braces (nest 4 (vcat . map (<> semi) . concat $ txts)) <> semi
    type2C' (RangeType r) = return (text "int" <+>)
    type2C' (Sequence ids) = do
        is <- mapM (id2C IOInsert . setBaseType bt) ids
        return (text "enum" <+> (braces . vcat . punctuate comma . map (\(a, b) -> a <+> equals <+> text "0x" <> text (showHex b "")) $ zip is [0..]) <+>)
        where
            bt = BTEnum $ map (\(Identifier i _) -> map toLower i) ids
    type2C' (ArrayDecl Nothing t) = type2C (PointerTo t)
    type2C' (ArrayDecl (Just r) t) = do
        t' <- type2C t
        lt <- gets lastType
        ft <- case lt of
                -- BTFunction {} -> type2C (PointerTo t)
                _ -> return t'
        r' <- initExpr2C (InitRange r)
        return $ \i -> ft i <> brackets r'
    type2C' (Set t) = return (text "<<set>>" <+>)
    type2C' (FunctionType returnType params) = do
        t <- type2C returnType
        p <- withState' id $ functionParams2C params
        return (\i -> (t empty <> (parens $ text "*" <> i) <> parens p))
    type2C' (DeriveType (InitBinOp _ _ i)) = type2C' (DeriveType i)
    type2C' (DeriveType (InitPrefixOp _ i)) = type2C' (DeriveType i)
    type2C' (DeriveType (InitNumber _)) = return (text "int" <+>)
    type2C' (DeriveType (InitHexNumber _)) = return (text "int" <+>)
    type2C' (DeriveType (InitFloat _)) = return (text "float" <+>)
    type2C' (DeriveType (BuiltInFunction {})) = return (text "int" <+>)
    type2C' (DeriveType (InitString {})) = return (text "string255" <+>)
    type2C' (DeriveType r@(InitReference {})) = do
        initExpr2C r
        t <- gets lastType
        return (baseType2C (show r) t <+>)
    type2C' (DeriveType a) = error $ "Can't derive type from " ++ show a
    type2C' a = error $ "type2C: unknown type " ++ show a

phrase2C :: Phrase -> State RenderState Doc
phrase2C (Phrases p) = do
    ps <- mapM phrase2C p
    return $ text "{" $+$ (nest 4 . vcat $ ps) $+$ text "}"
phrase2C (ProcCall f@(FunCall {}) []) = liftM (<> semi) $ ref2C f
phrase2C (ProcCall ref []) = liftM (<> semi) $ ref2CF ref True
phrase2C (ProcCall _ _) = error $ "ProcCall"{-do
    r <- ref2C ref
    ps <- mapM expr2C params
    return $ r <> parens (hsep . punctuate (char ',') $ ps) <> semi -}
phrase2C (IfThenElse (expr) phrase1 mphrase2) = do
    e <- expr2C expr
    p1 <- (phrase2C . wrapPhrase) phrase1
    el <- elsePart
    return $
        text "if" <> parens e $+$ p1 $+$ el
    where
    elsePart | isNothing mphrase2 = return $ empty
             | otherwise = liftM (text "else" $$) $ (phrase2C . wrapPhrase) (fromJust mphrase2)
phrase2C asgn@(Assignment ref expr) = do
    r <- ref2C ref
    t <- gets lastType
    case (t, expr) of
        (_, Reference r') | ref == r' -> do
            e <- ref2C r'
            return $ text "UNUSED" <+> parens e <> semi
        (BTFunction {}, (Reference r')) -> do
            e <- ref2C r'
            return $ r <+> text "=" <+> e <> semi
        (BTString, _) -> do
            void $ expr2C expr
            lt <- gets lastType
            case lt of
                -- assume pointer to char for simplicity
                BTPointerTo _ -> do
                    e <- expr2C $ Reference $ FunCall [Reference $ RefExpression expr] (SimpleReference (Identifier "pchar2str" BTUnknown))
                    return $ r <+> text "=" <+> e <> semi
                BTAString -> do
                    e <- expr2C $ Reference $ FunCall [Reference $ RefExpression expr] (SimpleReference (Identifier "astr2str" BTUnknown))
                    return $ r <+> text "=" <+> e <> semi
                BTString -> do
                    e <- expr2C expr
                    return $ r <+> text "=" <+> e <> semi
                _ -> error $ "Assignment to string from " ++ show lt ++ "\n" ++ show asgn
        (BTAString, _) -> do
            void $ expr2C expr
            lt <- gets lastType
            case lt of
                -- assume pointer to char for simplicity
                BTPointerTo _ -> do
                    e <- expr2C $ Reference $ FunCall [Reference $ RefExpression expr] (SimpleReference (Identifier "pchar2astr" BTUnknown))
                    return $ r <+> text "=" <+> e <> semi
                BTString -> do
                    e <- expr2C $ Reference $ FunCall [Reference $ RefExpression expr] (SimpleReference (Identifier "str2astr" BTUnknown))
                    return $ r <+> text "=" <+> e <> semi
                BTAString -> do
                    e <- expr2C expr
                    return $ r <+> text "=" <+> e <> semi
                _ -> error $ "Assignment to ansistring from " ++ show lt ++ "\n" ++ show asgn
        (BTArray _ _ _, _) -> do
            case expr of
                Reference er -> do
                    void $ ref2C er
                    exprT <- gets lastType
                    case exprT of
                        BTArray RangeInfinite _ _ ->
                            return $ text "FIXME: assign a dynamic array to an array"
                        BTArray _ _ _ -> phrase2C $
                                ProcCall (FunCall
                                    [
                                    Reference $ ref
                                    , Reference $ RefExpression expr
                                    , Reference $ FunCall [expr] (SimpleReference (Identifier "sizeof" BTUnknown))
                                    ]
                                    (SimpleReference (Identifier "memcpy" BTUnknown))
                                    ) []
                        _ -> return $ text "FIXME: assign a non-specific value to an array"

                _ -> return $ text "FIXME: dynamic array assignment 2"
        _ -> do
            e <- expr2C expr
            return $ r <+> text "=" <+> e <> semi
phrase2C (WhileCycle expr phrase) = do
    e <- expr2C expr
    p <- phrase2C $ wrapPhrase phrase
    return $ text "while" <> parens e $$ p
phrase2C (SwitchCase expr cases mphrase) = do
    e <- expr2C expr
    cs <- mapM case2C cases
    d <- dflt
    return $
        text "switch" <> parens e $+$ braces (nest 4 . vcat $ cs ++ d)
    where
    case2C :: ([InitExpression], Phrase) -> State RenderState Doc
    case2C (e, p) = do
        ies <- mapM range2C e
        ph <- phrase2C p
        return $
             vcat (map (\i -> text "case" <+> i <> colon) . concat $ ies) <> nest 4 (ph $+$ text "break;")
    dflt | isNothing mphrase = return [text "default: break;"] -- avoid compiler warning
         | otherwise = do
             ph <- mapM phrase2C $ fromJust mphrase
             return [text "default:" <+> nest 4 (vcat ph)]

phrase2C wb@(WithBlock ref p) = do
    r <- ref2C ref
    t <- gets lastType
    case t of
        (BTRecord _ rs) -> withRecordNamespace (render r ++ ".") (rec2Records rs) $ phrase2C $ wrapPhrase p
        a -> do
            error $ "'with' block referencing non-record type " ++ show a ++ "\n" ++ show wb
phrase2C (ForCycle i' e1' e2' p up) = do
    i <- id2C IOLookup i'
    iType <- gets lastIdTypeDecl
    e1 <- expr2C e1'
    e2 <- expr2C e2'
    let iEnd = i <> text "__end__"
    ph <- phrase2C $ wrapPhrase p
    return . braces $
        i <+> text "=" <+> e1 <> semi
        $$
        iType <+> iEnd <+> text "=" <+> e2 <> semi
        $$
        text "if" <+> (parens $ i <+> text (if up then "<=" else ">=") <+> iEnd) <+> text "do" <+> ph <+>
        text "while" <> parens (i <> text (if up then "++" else "--") <+> text "!=" <+> iEnd) <> semi
    where
        appendPhrase p (Phrases ps) = Phrases $ ps ++ [p]
        appendPhrase _ _ = error "illegal appendPhrase call"
phrase2C (RepeatCycle e' p') = do
    e <- expr2C e'
    p <- phrase2C (Phrases p')
    return $ text "do" <+> p <+> text "while" <> parens (text "!" <> parens e) <> semi

phrase2C NOP = return $ text ";"

phrase2C (BuiltInFunctionCall [] (SimpleReference (Identifier "exit" BTUnknown))) = do
    f <- gets currentFunctionResult
    if null f then
        return $ text "return" <> semi
        else
        return $ text "return" <+> text f <> semi
phrase2C (BuiltInFunctionCall [] (SimpleReference (Identifier "break" BTUnknown))) = return $ text "break" <> semi
phrase2C (BuiltInFunctionCall [] (SimpleReference (Identifier "continue" BTUnknown))) = return $ text "continue" <> semi
phrase2C (BuiltInFunctionCall [e] (SimpleReference (Identifier "exit" BTUnknown))) = liftM (\e -> text "return" <+> e <> semi) $ expr2C e
phrase2C (BuiltInFunctionCall [e] (SimpleReference (Identifier "dec" BTUnknown))) = liftM (\e -> text "--" <> e <> semi) $ expr2C e
phrase2C (BuiltInFunctionCall [e1, e2] (SimpleReference (Identifier "dec" BTUnknown))) = liftM2 (\a b -> a <> text " -= " <> b <> semi) (expr2C e1) (expr2C e2)
phrase2C (BuiltInFunctionCall [e] (SimpleReference (Identifier "inc" BTUnknown))) = liftM (\e -> text "++" <> e <> semi) $ expr2C e
phrase2C (BuiltInFunctionCall [e1, e2] (SimpleReference (Identifier "inc" BTUnknown))) = liftM2 (\a b -> a <+> text "+=" <+> b <> semi) (expr2C e1) (expr2C e2)
phrase2C a = error $ "phrase2C: " ++ show a

wrapPhrase p@(Phrases _) = p
wrapPhrase p = Phrases [p]

expr2C :: Expression -> State RenderState Doc
expr2C (Expression s) = return $ text s
expr2C bop@(BinOp op expr1 expr2) = do
    e1 <- expr2C expr1
    t1 <- gets lastType
    e2 <- expr2C expr2
    t2 <- gets lastType
    case (op2C op, t1, t2) of
        ("+", BTAString, BTAString) -> expr2C $ BuiltInFunCall [expr1, expr2] (SimpleReference $ Identifier "_strconcatA" (fff t1 t2 BTString))
        ("+", BTAString, BTChar) -> expr2C $ BuiltInFunCall [expr1, expr2] (SimpleReference $ Identifier "_strappendA" (fff t1 t2  BTAString))
        ("!=", BTAString, BTAString) -> expr2C $ BuiltInFunCall [expr1, expr2] (SimpleReference $ Identifier "_strncompareA" (fff t1 t2  BTBool))
        (_, BTAString, _) -> error $ "unhandled bin op with ansistring on the left side: " ++ show bop
        (_, _, BTAString) -> error $ "unhandled bin op with ansistring on the right side: " ++ show bop
        ("+", BTString, BTString) -> expr2C $ BuiltInFunCall [expr1, expr2] (SimpleReference $ Identifier "_strconcat" (fff t1 t2  BTString))
        ("+", BTString, BTChar) -> expr2C $ BuiltInFunCall [expr1, expr2] (SimpleReference $ Identifier "_strappend" (fff t1 t2  BTString))
        ("+", BTChar, BTString) -> expr2C $ BuiltInFunCall [expr1, expr2] (SimpleReference $ Identifier "_strprepend" (fff t1 t2  BTString))
        ("+", BTChar, BTChar) -> expr2C $ BuiltInFunCall [expr1, expr2] (SimpleReference $ Identifier "_chrconcat" (fff t1 t2  BTString))
        ("==", BTString, BTChar) -> expr2C $ BuiltInFunCall [expr1, expr2] (SimpleReference $ Identifier "_strcomparec" (fff t1 t2  BTBool))

        -- for function/procedure comparision
        ("==", BTVoid, _) -> procCompare expr1 expr2 "=="
        ("==", BTFunction _ _ _ _, _) -> procCompare expr1 expr2 "=="

        ("!=", BTVoid, _) -> procCompare expr1 expr2 "!="
        ("!=", BTFunction _ _ _ _, _) -> procCompare expr1 expr2 "!="

        ("==", BTString, BTString) -> expr2C $ BuiltInFunCall [expr1, expr2] (SimpleReference $ Identifier "_strcompare" (fff t1 t2  BTBool))
        ("!=", BTString, _) -> expr2C $ BuiltInFunCall [expr1, expr2] (SimpleReference $ Identifier "_strncompare" (fff t1 t2  BTBool))
        ("&", BTBool, _) -> return $ parens e1 <+> text "&&" <+> parens e2
        ("|", BTBool, _) -> return $ parens e1 <+> text "||" <+> parens e2
        (_, BTRecord t1 _, BTRecord t2 _) -> do
            i <- op2CTyped op [SimpleType (Identifier t1 undefined), SimpleType (Identifier t2 undefined)]
            ref2C $ FunCall [expr1, expr2] (SimpleReference i)
        (_, BTRecord t1 _, BTInt _) -> do
            -- aw, "LongInt" here is hwengine-specific hack
            i <- op2CTyped op [SimpleType (Identifier t1 undefined), SimpleType (Identifier "LongInt" undefined)]
            ref2C $ FunCall [expr1, expr2] (SimpleReference i)
        ("in", _, _) ->
            case expr2 of
                 SetExpression set -> do
                     ids <- mapM (id2C IOLookup) set
                     modify(\s -> s{lastType = BTBool})
                     return . parens . hcat . punctuate (text " || ") . map (\i -> parens $ e1 <+> text "==" <+> i) $ ids
                 _ -> error "'in' against not set expression"
        (o, _, _) | o `elem` boolOps -> do
                        modify(\s -> s{lastType = BTBool})
                        return $ parens e1 <+> text o <+> parens e2
                  | otherwise -> do
                        o' <- return $ case o of
                            "/(float)" -> text "/(float)" -- pascal returns real value
                            _ -> text o
                        e1' <- return $ case (o, t1, t2) of
                                ("-", BTInt False, BTInt False) -> parens $ text "(int64_t)" <+> parens e1
                                _ -> parens e1
                        e2' <- return $ case (o, t1, t2) of
                                ("-", BTInt False, BTInt False) -> parens $ text "(int64_t)" <+> parens e2
                                _ -> parens e2
                        return $ e1' <+> o' <+> e2'
    where
        fff t1 t2 = BTFunction False False [(False, t1), (False, t2)]
        boolOps = ["==", "!=", "<", ">", "<=", ">="]
        procCompare expr1 expr2 op =
            case (expr1, expr2) of
                (Reference r1, Reference r2) -> do
                    id1 <- ref2C r1
                    id2 <- ref2C r2
                    return $ (parens id1) <+> text op <+> (parens id2)
                (_, _) -> error $ "Two non reference type vars are compared but they have type of BTVoid or BTFunction\n" ++ show expr1 ++ "\n" ++ show expr2

expr2C (NumberLiteral s) = do
    modify(\s -> s{lastType = BTInt True})
    return $ text s
expr2C (FloatLiteral s) = return $ text s
expr2C (HexNumber s) = return $ text "0x" <> (text . map toLower $ s)
{-expr2C (StringLiteral [a]) = do
    modify(\s -> s{lastType = BTChar})
    return . quotes . text $ escape a
    where
        escape '\'' = "\\\'"
        escape a = [a]-}
expr2C (StringLiteral s) = addStringConst s
expr2C (PCharLiteral s) = return . doubleQuotes $ text s
expr2C (Reference ref) = do
   isfunc <- gets isFunctionType
   modify(\s -> s{isFunctionType = False}) -- reset
   if isfunc then ref2CF ref False else ref2CF ref True
expr2C (PrefixOp op expr) = do
    e <- expr2C expr
    lt <- gets lastType
    case lt of
        BTRecord t _ -> do
            i <- op2CTyped op [SimpleType (Identifier t undefined)]
            ref2C $ FunCall [expr] (SimpleReference i)
        BTBool -> do
            o <- return $ case op of
                     "not" -> text "!"
                     _ -> text (op2C op)
            return $ o <> parens e
        _ -> return $ text (op2C op) <> parens e
expr2C Null = return $ text "NULL"
expr2C (CharCode a) = do
    modify(\s -> s{lastType = BTChar})
    return $ text "0x" <> text (showHex (read a) "")
expr2C (HexCharCode a) = if length a <= 2 then return $ quotes $ text "\\x" <> text (map toLower a) else expr2C $ HexNumber a
expr2C (SetExpression ids) = mapM (id2C IOLookup) ids >>= return . parens . hcat . punctuate (text " | ")

expr2C (BuiltInFunCall [e] (SimpleReference (Identifier "low" _))) = do
    e' <- liftM (map toLower . render) $ expr2C e
    lt <- gets lastType
    case lt of
         BTEnum _-> return $ int 0
         BTInt _ -> case e' of
                  "longint" -> return $ int (-2147483648)
         BTArray {} -> return $ int 0
         _ -> error $ "BuiltInFunCall 'low' from " ++ show e ++ "\ntype: " ++ show lt
expr2C (BuiltInFunCall [e] (SimpleReference (Identifier "high" _))) = do
    e' <- liftM (map toLower . render) $ expr2C e
    lt <- gets lastType
    case lt of
         BTEnum a -> return . int $ length a - 1
         BTInt _ -> case e' of
                  "longint" -> return $ int (2147483647)
         BTString -> return $ int 255
         BTArray (RangeFromTo _ n) _ _ -> initExpr2C n
         _ -> error $ "BuiltInFunCall 'high' from " ++ show e ++ "\ntype: " ++ show lt
expr2C (BuiltInFunCall [e] (SimpleReference (Identifier "ord" _))) = liftM parens $ expr2C e
expr2C (BuiltInFunCall [e] (SimpleReference (Identifier "succ" _))) = liftM (<> text " + 1") $ expr2C e
expr2C (BuiltInFunCall [e] (SimpleReference (Identifier "pred" _))) = do
    e'<- expr2C e
    return $ text "(int)" <> parens e' <> text " - 1"
expr2C (BuiltInFunCall [e] (SimpleReference (Identifier "length" _))) = do
    e' <- expr2C e
    lt <- gets lastType
    modify (\s -> s{lastType = BTInt True})
    case lt of
         BTString -> return $ text "fpcrtl_Length" <> parens e'
         BTAString -> return $ text "fpcrtl_LengthA" <> parens e'
         BTArray RangeInfinite _ _ -> error $ "length() called on variable size array " ++ show e'
         BTArray (RangeFromTo _ n) _ _ -> initExpr2C (BuiltInFunction "succ" [n])
         _ -> error $ "length() called on " ++ show lt
expr2C (BuiltInFunCall [e, e1, e2] (SimpleReference (Identifier "copy" _))) = do
    e1' <- expr2C e1
    e2' <- expr2C e2
    e' <- expr2C e
    lt <- gets lastType
    let f name = return $ text name <> parens (hsep $ punctuate (char ',') [e', e1', e2'])
    case lt of
         BTString -> f "fpcrtl_copy"
         BTAString -> f "fpcrtl_copyA"
         _ -> error $ "copy() called on " ++ show lt
     
expr2C (BuiltInFunCall params ref) = do
    r <- ref2C ref
    t <- gets lastType
    ps <- mapM expr2C params
    case t of
        BTFunction _ _ _ t' -> do
            modify (\s -> s{lastType = t'})
        _ -> error $ "BuiltInFunCall lastType: " ++ show t
    return $
        r <> parens (hsep . punctuate (char ',') $ ps)
expr2C a = error $ "Don't know how to render " ++ show a

ref2CF :: Reference -> Bool -> State RenderState Doc
ref2CF (SimpleReference name) addParens = do
    i <- id2C IOLookup name
    t <- gets lastType
    case t of
         BTFunction _ _ _ rt -> do
             modify(\s -> s{lastType = rt})
             return $ if addParens then i <> parens empty else i --xymeng: removed parens
         _ -> return $ i
ref2CF r@(RecordField (SimpleReference _) (SimpleReference _)) addParens = do
    i <- ref2C r
    t <- gets lastType
    case t of
         BTFunction _ _ _ rt -> do
             modify(\s -> s{lastType = rt})
             return $ if addParens then i <> parens empty else i
         _ -> return $ i
ref2CF r _ = ref2C r

ref2C :: Reference -> State RenderState Doc
-- rewrite into proper form
ref2C (RecordField ref1 (ArrayElement exprs ref2)) = ref2C $ ArrayElement exprs (RecordField ref1 ref2)
ref2C (RecordField ref1 (Dereference ref2)) = ref2C $ Dereference (RecordField ref1 ref2)
ref2C (RecordField ref1 (RecordField ref2 ref3)) = ref2C $ RecordField (RecordField ref1 ref2) ref3
ref2C (RecordField ref1 (FunCall params ref2)) = ref2C $ FunCall params (RecordField ref1 ref2)
ref2C (ArrayElement (a:b:xs) ref) = ref2C $ ArrayElement (b:xs) (ArrayElement [a] ref)
-- conversion routines
ref2C ae@(ArrayElement [expr] ref) = do
    e <- expr2C expr
    r <- ref2C ref
    t <- gets lastType
    case t of
         (BTArray _ _ t') -> modify (\st -> st{lastType = t'})
--         (BTFunctionReturn _ (BTArray _ _ t')) -> modify (\st -> st{lastType = t'})
--         (BTFunctionReturn _ (BTString)) -> modify (\st -> st{lastType = BTChar})
         BTString -> modify (\st -> st{lastType = BTChar})
         BTAString -> modify (\st -> st{lastType = BTChar})
         (BTPointerTo t) -> do
                t'' <- fromPointer (show t) =<< gets lastType
                case t'' of
                     BTChar -> modify (\st -> st{lastType = BTChar})
                     a -> error $ "Getting element of " ++ show a ++ "\nReference: " ++ show ae
         a -> error $ "Getting element of " ++ show a ++ "\nReference: " ++ show ae
    case t of
         BTString ->  return $ r <> text ".s" <> brackets e
         BTAString ->  return $ r <> text ".s" <> brackets e
         _ -> return $ r <> brackets e
ref2C (SimpleReference name) = id2C IOLookup name
ref2C rf@(RecordField (Dereference ref1) ref2) = do
    r1 <- ref2C ref1
    t <- fromPointer (show ref1) =<< gets lastType
    r2 <- case t of
        BTRecord _ rs -> withRecordNamespace "" (rec2Records rs) $ ref2C ref2
        BTUnit -> error "What??"
        a -> error $ "dereferencing from " ++ show a ++ "\n" ++ show rf
    return $
        r1 <> text "->" <> r2
ref2C rf@(RecordField ref1 ref2) = do
    r1 <- ref2C ref1
    t <- gets lastType
    case t of
        BTRecord _ rs -> do
            r2 <- withRecordNamespace "" (rec2Records rs) $ ref2C ref2
            return $ r1 <> text "." <> r2
        BTUnit -> withLastIdNamespace $ ref2C ref2
        a -> error $ "dereferencing from " ++ show a ++ "\n" ++ show rf
ref2C d@(Dereference ref) = do
    r <- ref2C ref
    t <- fromPointer (show d) =<< gets lastType
    modify (\st -> st{lastType = t})
    return $ (parens $ text "*" <> r)
ref2C f@(FunCall params ref) = do
    r <- fref2C ref
    t <- gets lastType
    case t of
        BTFunction _ _ bts t' -> do
            ps <- liftM (parens . hsep . punctuate (char ',')) $
                    if (length params) == (length bts) -- hot fix for pas2cSystem and pas2cRedo functions since they don't have params
                    then
                        mapM expr2CHelper (zip params bts)
                    else mapM expr2C params
            modify (\s -> s{lastType = t'})
            return $ r <> ps
        _ -> case (ref, params) of
                  (SimpleReference i, [p]) -> ref2C $ TypeCast i p
                  _ -> error $ "ref2C FunCall erroneous type cast detected: " ++ show f ++ "\nType detected: " ++ show t ++ "\n" ++ show ref ++ "\n" ++ show params ++ "\n" ++ show t
    where
    fref2C (SimpleReference name) = id2C (IOLookupFunction $ length params) name
    fref2C a = ref2C a
    expr2CHelper :: (Expression, (Bool, BaseType)) -> State RenderState Doc
    expr2CHelper (e, (_, BTFunction _ _ _ _)) = do
        modify (\s -> s{isFunctionType = True})
        expr2C e
    expr2CHelper (e, (isVar, _)) = if isVar then liftM (((<>) $ text "&") . parens) $ (expr2C e) else expr2C e

ref2C (Address ref) = do
    r <- ref2C ref
    lt <- gets lastType
    case lt of
        BTFunction True _ _ _ -> return $ text "&" <> parens r
        _ -> return $ text "&" <> parens r
ref2C (TypeCast t'@(Identifier i _) expr) = do
    lt <- expr2C expr >> gets lastType
    case (map toLower i, lt) of
        ("pchar", BTString) -> ref2C $ FunCall [expr] (SimpleReference (Identifier "_pchar" $ BTPointerTo BTChar))
        ("pchar", BTAString) -> ref2C $ FunCall [expr] (SimpleReference (Identifier "_pcharA" $ BTPointerTo BTChar))
        ("shortstring", BTAString) -> ref2C $ FunCall [expr] (SimpleReference (Identifier "astr2str" $ BTString))
        ("shortstring", BTPointerTo _) -> ref2C $ FunCall [expr] (SimpleReference (Identifier "pchar2str" $ BTString))
        ("ansistring", BTPointerTo _) -> ref2C $ FunCall [expr] (SimpleReference (Identifier "pchar2astr" $ BTAString))
        ("ansistring", BTString) -> ref2C $ FunCall [expr] (SimpleReference (Identifier "str2astr" $ BTAString))
        (a, _) -> do
            e <- expr2C expr
            t <- id2C IOLookup t'
            return . parens $ parens t <> e
ref2C (RefExpression expr) = expr2C expr


op2C :: String -> String
op2C "or" = "|"
op2C "and" = "&"
op2C "not" = "~"
op2C "xor" = "^"
op2C "div" = "/"
op2C "mod" = "%"
op2C "shl" = "<<"
op2C "shr" = ">>"
op2C "<>" = "!="
op2C "=" = "=="
op2C "/" = "/(float)"
op2C a = a

