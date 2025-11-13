module Lib
  ( engine,
  )
where

import Model.CType
import QueryParser.Lexer (tokenize)
import QueryParser.Parser (parseCQuery)
import System.Environment (getArgs)
import Text.Parsec

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
      print query
    else
      return ()

engine :: IO ()
engine = do
  args <- getArgs
  case args of
    (index_file : _) -> do
      index <- loadIndex index_file
      repl index
    [] -> putStrLn $ "Usage: <app> <path-to-index>"