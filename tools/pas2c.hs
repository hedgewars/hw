module Pas2C where

import PascalParser
import Text.PrettyPrint.HughesPJ
import Data.Maybe


pascal2C :: PascalUnit -> Doc
pascal2C (Unit unitName interface implementation init fin) = implementation2C implementation


implementation2C :: Implementation -> Doc
implementation2C (Implementation uses tvars) = typesAndVars2C tvars


typesAndVars2C :: TypesAndVars -> Doc
typesAndVars2C (TypesAndVars ts) = vcat $ map tvar2C ts


tvar2C :: TypeVarDeclaration -> Doc
tvar2C (FunctionDeclaration (Identifier name) (Identifier returnType) Nothing) = 
    text $ maybeVoid returnType ++ " " ++ name ++ "();"

    
tvar2C (FunctionDeclaration (Identifier name) (Identifier returnType) (Just phrase)) = 
    text (maybeVoid returnType ++ " " ++ name ++ "()") 
    $$
    phrase2C phrase
tvar2C _ = empty


phrase2C :: Phrase -> Doc
phrase2C (Phrases p) = braces . nest 4 . vcat . map phrase2C $ p
phrase2C (ProcCall (Identifier name) params) = text name <> parens (hsep . punctuate (char ',') . map expr2C $ params) <> semi
phrase2C (IfThenElse (expr) phrase1 mphrase2) = text "if" <> parens (expr2C expr) $$ (braces . nest 4 . phrase2C) phrase1 $+$ elsePart
    where
    elsePart | isNothing mphrase2 = empty
             | otherwise = text "else" $$ (braces . nest 4 . phrase2C) (fromJust mphrase2)
phrase2C (Assignment (Identifier name) expr) = text name <> text " = " <> expr2C expr <> semi
phrase2C (WhileCycle expr phrase) = text "while" <> parens (expr2C expr) $$ nest 4 (phrase2C phrase)
phrase2C (SwitchCase expr cases mphrase) = text "switch" <> parens (expr2C expr) <> text "of" $$ (nest 4 . vcat . map case2C) cases
    where
    case2C :: (Expression, Phrase) -> Doc
    case2C (e, p) = text "case" <+> parens (expr2C e) <> char ':' <> nest 4 (phrase2C p $$ text "break;")
{-
        | RepeatCycle Expression Phrase
        | ForCycle
        | SwitchCase Expression [(Expression, Phrase)] (Maybe Phrase)
        | Assignment Identifier Expression
        -}
phrase2C _ = empty


expr2C :: Expression -> Doc
expr2C (Expression s) = text s
expr2C (FunCall (Identifier name) params) = text name <> parens (hsep . punctuate (char ',') . map expr2C $ params)
expr2C (BinOp op expr1 expr2) = (expr2C expr1) <+> op2C op <+> (expr2C expr2)
{-    | FunCall Identifier [Expression]
    | PrefixOp String Expression
    | BinOp String Expression Expression
    -}            
expr2C _ = empty

op2C = text

maybeVoid "" = "void"
maybeVoid a = a
