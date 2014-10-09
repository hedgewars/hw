module Main where

import System.Directory
import Control.Monad
import Data.List
import Text.Parsec
import Control.Monad.IO.Class
import Data.Maybe

data LuaCode =
    Comments String
        | LuaLocString LuaCode LuaCode
        | LuaString String LuaCode
        | CodeChunk String LuaCode
        | LuaOp String LuaCode
        | BlocksList Char [LuaCode]
        | NoCode
        deriving (Show, Eq)

toChunk a = CodeChunk a NoCode

isLuaString LuaLocString{} = True
isLuaString LuaString{} = True
isLuaString _ = False

isLocString (BlocksList _ blocks) = or $ map isLocString blocks
isLocString LuaLocString{} = True
isLocString (LuaString _ lc) = isLocString lc
isLocString (CodeChunk _ lc) = isLocString lc
isLocString (LuaOp _ lc) = isLocString lc
isLocString _ = False

many1Till :: (Stream s m t) => ParsecT s u m a -> ParsecT s u m end -> ParsecT s u m [a]
many1Till p end      = do
    res <- scan
    if null res then unexpected "many1Till" else return res
                    where
                    scan  = do{ end; return [] }
                            <|>
                            do{ x <- p; xs <- scan; return (x:xs) }

processScript :: String -> IO [LuaCode]
processScript fileName = do
    r <- runParserT processFile () "" ""
    case r of
         (Left a) -> do
             putStrLn $ "Error: " ++ (show a)
             return []
         (Right a) -> return a

    where
    processFile = do
        --liftIO $ putStrLn $ "Processing: " ++ fileName
        f <- liftIO (readFile fileName)
        setInput f
        process

    comment :: ParsecT String u IO LuaCode
    comment = liftM Comments $ choice [
            (try $ string "--[[") >> manyTill anyChar (try $ string "]]") >>= \s -> return $ "--[[" ++ s ++ "]]"
            , (try $ string "--") >> manyTill anyChar (try newline) >>= \s -> return $ "--" ++ s ++ "\n"
            ]
            
    stringConcat :: ParsecT String u IO ()
    stringConcat = try $ string ".." >> spaces

    locString :: ParsecT String u IO LuaCode
    locString = do
        s <- (try $ optional stringConcat >> string "loc(") >> luaString >>= \s -> char ')' >> return s
        subString <- liftM (fromMaybe NoCode) . optionMaybe . try $ spaces >> string ".." >> spaces >> codeBlock
        return $ LuaLocString s subString

    luaString :: ParsecT String u IO LuaCode
    luaString = do
        s <- choice[
            (try $ optional stringConcat >> char '\'') >> many (noneOf "'\n") >>= \s -> char '\'' >> return s
            , (try $ optional stringConcat >> char '"') >> many (noneOf "\"\n") >>= \s -> char '"' >> return s
            ]
        subString <- liftM (fromMaybe NoCode) . optionMaybe . try $ spaces >> string ".." >> spaces >> codeBlock
        return $ LuaString s subString

    luaOp :: ParsecT String u IO LuaCode
    luaOp = do
        s <- many1Till anyChar (lookAhead $ (oneOf "=-.,()[]{}'\"" >> return ()) <|> (try (string "end") >> return ()))
        subCode <- liftM (fromMaybe NoCode) . optionMaybe . try $ codeBlock
        return $ LuaOp s subCode

    codeBlock :: ParsecT String u IO LuaCode
    codeBlock = do
        s <- choice [
            comment
            , liftM toChunk $ many1 space
            , locString
            , luaString
            , luaOp
            , liftM (BlocksList '[') . brackets $ commaSep luaOp
            , liftM (BlocksList '{') . braces $ commaSep luaOp
            , liftM (BlocksList '(') . parens $ commaSep luaOp
            ]

        return s

    brackets = between (char '[') (char ']')
    braces = between (char '{') (char '}')
    parens = between (char '(') (char ')')
    commaSep p  = p `sepBy` (char ',')
    
    otherStuff :: ParsecT String u IO LuaCode
    otherStuff = liftM (\s -> CodeChunk s NoCode) $ manyTill anyChar (try $ lookAhead codeBlock)

    process :: ParsecT String u IO [LuaCode]
    process = do
        codes <- many $ try $ do
            a <- otherStuff
            b <- liftM (fromMaybe (CodeChunk "" NoCode)) $ optionMaybe $ try codeBlock
            return [a, b]
        liftIO . putStrLn . unlines . map (renderLua . processLocString) . filter isLocString $ concat codes
        return $ concat codes

listFilesRecursively :: FilePath -> IO [FilePath]
listFilesRecursively dir = do
    fs <- liftM (map (\d -> dir ++ ('/' : d)) . filter ((/=) '.' . head)) $ getDirectoryContents dir
    dirs <- filterM doesDirectoryExist fs
    recfs <- mapM listFilesRecursively dirs
    return . concat $ fs : recfs

renderLua :: LuaCode -> String
renderLua (Comments str) = str
renderLua (LuaLocString lc1 lc2) = let r = renderLua lc2 in "loc(" ++ renderLua lc1 ++ ")" ++ r
renderLua (LuaString str lc) = let r = renderLua lc in "\"" ++ str ++ "\"" ++ r
renderLua (CodeChunk str lc) = str ++ renderLua lc
renderLua (LuaOp str lc) = str ++ renderLua lc
renderLua (BlocksList t lcs) = t : (concat . intersperse "," . map renderLua) lcs ++ [mirror t]
renderLua NoCode = ""

processLocString :: LuaCode -> LuaCode
processLocString lcode = let (str, params) = pp lcode in
                          LuaLocString (LuaString str NoCode) 
                            (if null params then NoCode else (CodeChunk ".format" $ BlocksList '(' params))
    where
        pp (Comments _) = ("", [])
        pp (LuaLocString lc1 lc2) = let (s1, p1) = pp lc1; (s2, p2) = pp lc2 in (s1 ++ s2, p1 ++ p2)
        pp (LuaString str lc) = let (s, p) = pp lc in (str ++ s, p)
        pp (CodeChunk str lc) = let (s, p) = pp lc in ("%s" ++ s, p)
        pp (LuaOp str lc) = let (s, p) = pp lc in ("%s" ++ s, [LuaOp str (head $ p ++ [NoCode])])
        pp (BlocksList t lcs) = ("", [BlocksList t lcs])
        pp NoCode = ("", [])

mirror '(' = ')'
mirror '[' = ']'
mirror '{' = '}'

main = do
    (l18ns, scripts) <- liftM (partition (isPrefixOf "share/hedgewars/Data/Locale") . filter (isSuffixOf ".lua")) 
        $ listFilesRecursively "share/hedgewars/Data"

    mapM_ processScript scripts

    --putStrLn $ unlines l18ns