module Model.Query where

import Model.CType
import Data.Map
import Data.Maybe(mapMaybe)


-- data Query = Query {context :: [(CVar, CKind)], arguments :: Set [CType], result :: CType}
newtype CQuery = CQuery {target :: CDeclType}
data CMatch = CMatch {queried :: CQuery, matched :: CDecl, unification :: Map CVar CType}

prettyPrint :: CMatch -> String
prettyPrint = undefined

unify :: CQuery -> CDecl -> Maybe CMatch
unify = undefined

search :: CQuery -> CIndex -> [CMatch]
search query  = Data.Maybe.mapMaybe (unify query) 
