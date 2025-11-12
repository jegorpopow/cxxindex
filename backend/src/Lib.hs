module Lib
    ( someFunc
    ) where


import QueryParser.Lexer (tokenize)
import QueryParser.Parser (parseCQuery)
import Text.Parsec
import Text.Parsec.String (Parser)

report :: Either ParseError a -> a
report = \case
  Left err -> error $ show err
  Right value -> value

someFunc :: IO ()
someFunc = do
    line <- getLine
    putStrLn line
    let query = report $ parse parseCQuery "" $ tokenize line
    -- let tokens = tokenize line
    print query
