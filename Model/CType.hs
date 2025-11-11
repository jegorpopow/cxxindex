module Model.CType where 

import Data.Set

type CName = String
type CVar = String

data CKind =                 -- template parameter
    CKType                   -- type template parameter
  | CKValue                  -- value template parameter
  | CKTemplate [CKind] CKind -- template template parameter

data CTemplateArg = 
    CTAType CType            -- any value type can be provided as 
  | CVAValue Integer         -- value template parameter shall be of integer type

data CType =                            -- "Type of * kind" in some way
    CTName CName                        -- full-qualified name with resolved aliases
  | CTVar CVar                          -- template parameter name
  | CTApplication CType [CTemplateArg]  -- template parameters specialisation 
  | CTPointer CType                     -- pointer
  | CTLRef CType                        -- lvalue reference
  | CTRRef CType                        -- rvalue refrence
  | CTConst CType                       -- const-qualified type
  | CTVolatile                          -- volatile-qualified type
  | CTUnresolved                        -- auto or decltype in return type

data CDeclType = CDeclType {template_args :: [(CVar, CKind) ], arguments :: Set CType, result :: CType} 
data CDecl = CDecl{name :: CName, ctype :: CDeclType, location :: String}

type CIndex = [CDecl]