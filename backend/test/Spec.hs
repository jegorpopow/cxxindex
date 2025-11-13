import Control.Monad (forM_)
import Lib (report)
import Match.Unify
import Model.CType
import Model.Query
import QueryParser.Lexer
import QueryParser.Parser
import Text.Parsec

cMaxTemplate = CDecl {name = "max", location = "here", ctype = CDeclType {template_args = [("T", CKType)], arguments = [CTVar "T", CTVar "T"], result = CTVar "T"}}

maxIntQueryRaw = "(int, int) -> int"

maxIntQuery = report $ parse parseCQuery "" $ tokenize maxIntQueryRaw

main :: IO ()
main = do
  putStrLn ""
--   print maxIntQuery
  let matches = search maxIntQuery [cMaxTemplate]

  if null matches
    then putStrLn "No matches found"
    else forM_ matches (putStrLn . prettyPrint)
