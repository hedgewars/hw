{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad
import Data.Maybe
import qualified Data.Yaml as YAML
import Data.Yaml ((.=))
import Data.List
import qualified Data.ByteString.Char8 as B
import qualified Data.Text as Text

import PascalUnitSyntaxTree


fixName :: String -> String
fixName "MaxHedgeHogs" = "max_hedgehogs"
fixName"canFlip" = "can_flip"
fixName"canInvert" = "can_invert"
fixName"canMirror" = "can_mirror"
fixName"TemplateWidth" = "width"
fixName"TemplateHeight" = "height"
fixName"RandPassesCount" = "rand_passes"
fixName"BezierizeCount" = "bezie_passes"
fixName"hasGirders" = "put_girders"
fixName"isNegative" = "is_negative"
fixName a = a

instance YAML.ToJSON InitExpression where
  toJSON (InitArray ar) = YAML.toJSON ar
  toJSON (InitRecord ar) = YAML.object $ map (\(Identifier i _, iref) ->  Text.pack (fixName i) .= iref) $ filter isRelevant ar
    where
        isRelevant (Identifier i _, _) | i `elem` ["BasePoints", "FillPoints", "BasePointsCount", "FillPointsCount"] = False
        isRelevant _ = True
  toJSON (InitTypeCast {}) = YAML.object []
  toJSON (BuiltInFunction {}) = YAML.object []
  toJSON (InitNumber n) = YAML.toJSON (read n :: Int)
  toJSON (InitReference (Identifier "true" _)) = YAML.toJSON True
  toJSON (InitReference (Identifier "false" _)) = YAML.toJSON False
  toJSON a = error $ show a

instance YAML.ToJSON Identifier where
    toJSON (Identifier i _) = YAML.toJSON i

data Template = Template InitExpression ([InitExpression], InitExpression)
    deriving Show

instance YAML.ToJSON Template where
    toJSON (Template (InitRecord ri) (points, fpoints)) = YAML.toJSON $ InitRecord $ ri ++ [(Identifier "outline_points" BTUnknown, InitArray points), (Identifier "fill_points" BTUnknown, fpoints)]

takeLast i = reverse . take i . reverse

extractDeclarations  :: PascalUnit -> [TypeVarDeclaration]
extractDeclarations (Unit (Identifier "uLandTemplates" _) (Interface _ (TypesAndVars decls)) _ _ _) = decls
extractDeclarations _ = error "Unexpected file structure"

extractTemplatePoints :: Int -> [TypeVarDeclaration] -> ([InitExpression], InitExpression)
extractTemplatePoints templateNumber decls = (breakNTPX . head . catMaybes $ map (toTemplatePointInit "Points") decls, head . catMaybes $ map (toTemplatePointInit "FPoints") decls)
    where
        toTemplatePointInit suffix (VarDeclaration False False ([Identifier i _], _) ie)
            | (i == "Template" ++ show templateNumber ++ suffix) = ie
            | otherwise = Nothing
        toTemplatePointInit _ _ = Nothing

        breakNTPX :: InitExpression -> [InitExpression]
        breakNTPX (InitArray ia) = map InitArray . filter ((<) 0 . length) . map (filter (not . isNtpx)) $ groupBy (\a b -> isNtpx a == isNtpx b) ia
        breakNTPX a = error $ show a
        isNtpx :: InitExpression -> Bool
        isNtpx (InitRecord ((Identifier "x" _, InitReference (Identifier "NTPX" _)):_)) = True
        isNtpx _ = False

extractTemplates :: [TypeVarDeclaration] -> [Template]
extractTemplates decls = map toFull $ zip (head . catMaybes $ map toTemplateInit decls) [0..]
    where
        toTemplateInit (VarDeclaration False False ([Identifier "EdgeTemplates" _], _) (Just (InitArray ia))) = Just ia
        toTemplateInit _ = Nothing

        toFull (ie, num) = let ps = extractTemplatePoints num decls in if "NTPX" `isInfixOf` show ps then error $ show num ++ " " ++ show ps else Template ie ps

convert :: PascalUnit -> B.ByteString
convert pu = YAML.encode . extractTemplates . extractDeclarations $ pu

main = do
    f <- liftM read $ readFile "uLandTemplates.dump"
    B.putStrLn $ convert f
