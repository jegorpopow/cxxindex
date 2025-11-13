module Model.Query where

import Model.CType
import Data.Map
import Data.List (intercalate)
-- data Query = Query {context :: [(CVar, CKind)], arguments :: Set [CType], result :: CType}
newtype CQuery = CQuery {target :: CDeclType} deriving (Show)
type CUnificator =  Map CVar CType

data CMatch = CMatch {queried :: CQuery, matched :: CDecl, unification :: CUnificator}

prettyCType :: CType -> String
prettyCType (CTName n)       = n
prettyCType (CTVar v)        = v
prettyCType (CTPointer t)    = prettyCType t ++ "*"
prettyCType (CTLRef t)       = prettyCType t ++ "&"
prettyCType (CTRRef t)       = prettyCType t ++ "&&"
prettyCType (CTConst t)      = "const " ++ prettyCType t
prettyCType (CTVolatile t)   = "volatile " ++ prettyCType t
prettyCType CTUnresolved     = "auto"
prettyCType (CTApplication t args) =
  prettyCType t ++ "<" ++ intercalate ", " (Prelude.map prettyCTemplateArg args) ++ ">"

prettyCTemplateArg :: CTemplateArg -> String
prettyCTemplateArg (CTAType t)  = prettyCType t
prettyCTemplateArg (CVAValue v) = show v


prettyPrint :: CMatch -> String
prettyPrint (CMatch _ matchedDecl _) = 
    loc ++ ": " ++ argsStr ++ " -> " ++ resStr
    where
        CDecl {ctype = CDeclType { arguments = args, result = res}
        , location = loc
        } = matchedDecl

        argsStr = "(" ++ intercalate ", " (Prelude.map prettyCType args) ++ ")"
        resStr = prettyCType res



