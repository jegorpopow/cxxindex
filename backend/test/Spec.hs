import Model.CType
import Model.Query 

import Match.Unify
import Model.CType (CDeclType(template_args))

cMaxTemplate = CDecl {name = "maxl", locaction = "here", ctype = CDeclType {template_args = []}}

-- c_maxl :: CDecl {name = "maxl", ctype = CDeclType(template )}

main :: IO ()
main = do 
    putStrLn ""
    print "meow"
