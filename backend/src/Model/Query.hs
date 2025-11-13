module Model.Query where

import Model.CType
import Data.Map

-- data Query = Query {context :: [(CVar, CKind)], arguments :: Set [CType], result :: CType}
newtype CQuery = CQuery {target :: CDeclType} deriving (Show)
type CUnificator =  Map CVar CType

data CMatch = CMatch {queried :: CQuery, matched :: CDecl, unification :: CUnificator}

prettyPrint :: CMatch -> String
prettyPrint = undefined
