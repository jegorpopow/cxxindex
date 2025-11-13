module Model.Query where

import Model.CType
import Data.Map

-- data Query = Query {context :: [(CVar, CKind)], arguments :: Set [CType], result :: CType}
newtype CQuery = CQuery {target :: CDeclType} deriving (Show)
data CMatch = CMatch {queried :: CQuery, matched :: CDecl, unification :: Map CVar CType}

prettyPrint :: CMatch -> String
prettyPrint = undefined
