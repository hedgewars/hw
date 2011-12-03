module Pas2C where

import Text.PrettyPrint.HughesPJ
import Data.Maybe
import Data.Char
import Text.Parsec.Prim
import Control.Monad.State
import System.IO
import System.Directory
import Control.Monad.IO.Class
import PascalPreprocessor
import Control.Exception
import System.IO.Error
import qualified Data.Map as Map

import PascalParser
import PascalUnitSyntaxTree

pas2C :: String -> IO ()
pas2C fn = do
    setCurrentDirectory "../hedgewars/"
    s <- flip execStateT initState $ f fn
    mapM_ toCFiles (Map.toList s)
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
                    modify (Map.insert fileName System)
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

toCFiles :: (String, PascalUnit) -> IO ()
toCFiles (_, System) = return ()
toCFiles p@(fn, pu) = do
    hPutStrLn stderr $ "Rendering '" ++ fn ++ "'..."
    toCFiles' p
    where
    toCFiles' (fn, p@(Program {})) = writeFile (fn ++ ".c") $ (render . pascal2C) p
    toCFiles' (fn, (Unit _ interface implementation _ _)) = do
        writeFile (fn ++ ".h") $ (render . interface2C) interface
        writeFile (fn ++ ".c") $ (render . implementation2C) implementation
                            
usesFiles :: PascalUnit -> [String]
usesFiles (Program _ (Implementation uses _) _) = uses2List uses
usesFiles (Unit _ (Interface uses1 _) (Implementation uses2 _) _ _) = uses2List uses1 ++ uses2List uses2



pascal2C :: PascalUnit -> Doc
pascal2C (Unit _ interface implementation init fin) = 
    interface2C interface
    $+$ 
    implementation2C implementation
pascal2C (Program _ implementation mainFunction) =
    implementation2C implementation
    $+$
    tvar2C True (FunctionDeclaration (Identifier "main" BTInt) (SimpleType $ Identifier "int" BTInt) [] (Just (TypesAndVars [], mainFunction)))
    
    
interface2C :: Interface -> Doc
interface2C (Interface uses tvars) = uses2C uses $+$ typesAndVars2C True tvars

implementation2C :: Implementation -> Doc
implementation2C (Implementation uses tvars) = uses2C uses $+$ typesAndVars2C True tvars


typesAndVars2C :: Bool -> TypesAndVars -> Doc
typesAndVars2C b (TypesAndVars ts) = vcat $ map (tvar2C b) ts

uses2C :: Uses -> Doc
uses2C uses = vcat $ map (\i -> text $ "#include \"" ++ i ++ ".h\"") $ uses2List uses

uses2List :: Uses -> [String]
uses2List (Uses ids) = map (\(Identifier i _) -> i) ids

tvar2C :: Bool -> TypeVarDeclaration -> Doc
tvar2C _ (FunctionDeclaration (Identifier name _) returnType params Nothing) = 
    type2C returnType <+> text name <> parens (hcat $ map (tvar2C False) params) <> text ";"
tvar2C True (FunctionDeclaration (Identifier name _) returnType params (Just (tvars, phrase))) = 
    type2C returnType <+> text name <> parens (hcat $ map (tvar2C False) params)
    $+$
    text "{" 
    $+$ nest 4 (
        typesAndVars2C False tvars
        $+$
        phrase2C' phrase
        )
    $+$
    text "}"
    where
    phrase2C' (Phrases p) = vcat $ map phrase2C p
    phrase2C' p = phrase2C p
tvar2C False (FunctionDeclaration (Identifier name _) _ _ _) = error $ "nested functions not allowed: " ++ name
tvar2C _ (TypeDeclaration (Identifier i _) t) = text "type" <+> text i <+> type2C t <> text ";"
tvar2C _ (VarDeclaration isConst (ids, t) mInitExpr) = 
    if isConst then text "const" else empty
    <+>
    type2C t
    <+>
    (hsep . punctuate (char ',') . map (\(Identifier i _) -> text i) $ ids)
    <+>
    initExpr mInitExpr
    <>
    text ";"
    where
    initExpr Nothing = empty
    initExpr (Just e) = text "=" <+> initExpr2C e
tvar2C f (OperatorDeclaration op _ ret params body) = 
    tvar2C f (FunctionDeclaration (Identifier ("<op " ++ op ++ ">") Unknown) ret params body)

initExpr2C :: InitExpression -> Doc
initExpr2C (InitBinOp op expr1 expr2) = parens $ (initExpr2C expr1) <+> op2C op <+> (initExpr2C expr2)
initExpr2C (InitNumber s) = text s
initExpr2C (InitFloat s) = text s
initExpr2C (InitHexNumber s) = text "0x" <> (text . map toLower $ s)
initExpr2C (InitString s) = doubleQuotes $ text s 
initExpr2C (InitReference (Identifier i _)) = text i


initExpr2C _ = text "<<expression>>"

type2C :: TypeDecl -> Doc
type2C UnknownType = text "void"
type2C (String l) = text $ "string" ++ show l
type2C (SimpleType (Identifier i _)) = text i
type2C (PointerTo t) = type2C t <> text "*"
type2C (RecordType tvs union) = text "{" $+$ (nest 4 . vcat . map (tvar2C False) $ tvs) $+$ text "}"
type2C (RangeType r) = text "<<range type>>"
type2C (Sequence ids) = text "<<sequence type>>"
type2C (ArrayDecl r t) = text "<<array type>>"
type2C (Set t) = text "<<set>>"
type2C (FunctionType returnType params) = text "<<function>>"

phrase2C :: Phrase -> Doc
phrase2C (Phrases p) = text "{" $+$ (nest 4 . vcat . map phrase2C $ p) $+$ text "}"
phrase2C (ProcCall f@(FunCall {}) []) = ref2C f <> semi
phrase2C (ProcCall ref params) = ref2C ref <> parens (hsep . punctuate (char ',') . map expr2C $ params) <> semi
phrase2C (IfThenElse (expr) phrase1 mphrase2) = text "if" <> parens (expr2C expr) $+$ (phrase2C . wrapPhrase) phrase1 $+$ elsePart
    where
    elsePart | isNothing mphrase2 = empty
             | otherwise = text "else" $$ (phrase2C . wrapPhrase) (fromJust mphrase2)
phrase2C (Assignment ref expr) = ref2C ref <> text " = " <> expr2C expr <> semi
phrase2C (WhileCycle expr phrase) = text "while" <> parens (expr2C expr) $$ (phrase2C $ wrapPhrase phrase)
phrase2C (SwitchCase expr cases mphrase) = text "switch" <> parens (expr2C expr) <> text "of" $+$ (nest 4 . vcat . map case2C) cases
    where
    case2C :: ([InitExpression], Phrase) -> Doc
    case2C (e, p) = text "case" <+> parens (hsep . punctuate (char ',') . map initExpr2C $ e) <> char ':' <> nest 4 (phrase2C p $+$ text "break;")
phrase2C (WithBlock ref p) = text "namespace" <> parens (ref2C ref) $$ (phrase2C $ wrapPhrase p)
phrase2C (ForCycle (Identifier i _) e1 e2 p) = 
    text "for" <> (parens . hsep . punctuate (char ';') $ [text i <+> text "=" <+> expr2C e1, text i <+> text "<=" <+> expr2C e2, text "++" <> text i])
    $$
    phrase2C (wrapPhrase p)
phrase2C (RepeatCycle e p) = text "do" <+> phrase2C (Phrases p) <+> text "while" <> parens (text "!" <> parens (expr2C e))
phrase2C NOP = text ";"


wrapPhrase p@(Phrases _) = p
wrapPhrase p = Phrases [p]


expr2C :: Expression -> Doc
expr2C (Expression s) = text s
expr2C (BinOp op expr1 expr2) = parens $ (expr2C expr1) <+> op2C op <+> (expr2C expr2)
expr2C (NumberLiteral s) = text s
expr2C (FloatLiteral s) = text s
expr2C (HexNumber s) = text "0x" <> (text . map toLower $ s)
expr2C (StringLiteral s) = doubleQuotes $ text s 
expr2C (Reference ref) = ref2C ref
expr2C (PrefixOp op expr) = op2C op <+> expr2C expr
expr2C Null = text "NULL"
expr2C (BuiltInFunCall params ref) = ref2C ref <> parens (hsep . punctuate (char ',') . map expr2C $ params)
expr2C _ = text "<<expression>>"


ref2C :: Reference -> Doc
ref2C (ArrayElement exprs ref) = ref2C ref <> (brackets . hcat) (punctuate comma $ map expr2C exprs)
ref2C (SimpleReference (Identifier name _)) = text name
ref2C (RecordField (Dereference ref1) ref2) = ref2C ref1 <> text "->" <> ref2C ref2
ref2C (RecordField ref1 ref2) = ref2C ref1 <> text "." <> ref2C ref2
ref2C (Dereference ref) = parens $ text "*" <> ref2C ref
ref2C (FunCall params ref) = ref2C ref <> parens (hsep . punctuate (char ',') . map expr2C $ params)
ref2C (Address ref) = text "&" <> parens (ref2C ref)
ref2C (TypeCast (Identifier t _) expr) = parens (text t) <> expr2C expr
ref2C (RefExpression expr) = expr2C expr

op2C "or" = text "|"
op2C "and" = text "&"
op2C "not" = text "!"
op2C "xor" = text "^"
op2C "div" = text "/"
op2C "mod" = text "%"
op2C "shl" = text "<<"
op2C "shr" = text ">>"
op2C "<>" = text "!="
op2C "=" = text "=="
op2C a = text a

maybeVoid "" = "void"
maybeVoid a = a
