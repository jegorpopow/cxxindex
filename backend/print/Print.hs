module Main where

-- import Lib

import Model.CType
import Model.Query
import qualified Data.Map as Map
import Model.CType (CTemplateArg(CTAType), CType (CTVar), CKind (CKType, CKValue))


exampleMatch :: CMatch
exampleMatch = CMatch {
        queried = query
        , matched = decl
        , unification = uni
    }
    where
        declType = CDeclType
            { template_args = [("T", CKType), ("U", CKType), ("N", CKValue)]
            , arguments = [CTVar "T", CTVar "T"]
            , result = CTName "U"
            }
        decl = CDecl    { name = "add"
            , ctype = declType
            , location = "add.hpp:10"
            }
        query = CQuery declType
        uni = Map.empty


main :: IO ()
main = do
    putStrLn "PrettyPrint example"
    putStrLn ( prettyPrint  exampleMatch)


