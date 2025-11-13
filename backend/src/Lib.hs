module Lib
  ( engine,
  )
where

import Model.CType
import Model.Query
import Match.Unify (search)
import QueryParser.Lexer (tokenize)
import QueryParser.Parser (parseCQuery)
import System.Environment (getArgs)
import Text.Parsec
import Control.Monad (forM)
-- import Control.Deepseq

loadIndex :: String -> IO CIndex
loadIndex filename = do
  contents <- readFile filename
  let decls = lines contents
  return $ read <$> decls

report :: Either ParseError a -> a
report = \case
  Left err -> error $ show err
  Right value -> value

repl :: CIndex -> IO ()
repl index = do
  line <- getLine
  if line /= "exit"
    then do
      let query = report $ parse parseCQuery "" $ tokenize line
      let matches = search query index

      if length matches == 0 then 
        putStrLn "No matches found"
      else 
        forM matches (putStrLn . prettyPrint) >> return ()
      repl index
    else
      return ()

engine :: IO ()
engine = do
  args <- getArgs
  case args of
    (index_file : _) -> do
      index <- loadIndex index_file
      putStrLn $ show (length index) ++ " lines parsed"
      repl index
    [] -> putStrLn $ "Usage: <app> <path-to-index>"