module Match.Unify where

-- import Data.List (permutations)
-- import Data.Maybe (mapMaybe)
-- import Model.CType
-- import Model.Query

-- unify :: CQuery -> CDecl -> Maybe CMatch
-- unify CQuery {target = CDeclType {template_args, arguments, result}} CDecl {name, ctype, location} =
--   getFirst (matchOne ctype . (\args_permutation -> CDeclType template_args args_permutation result) <$> permutations arguments)
--   where
--     matchOne :: CDeclType -> CDeclType -> Maybe CMatch
--     matchOne CDeclType {template_args, arguments, result} CDeclType {template_args', arguments', result'} = udefined
--     matchOne _ _ = Nothing
--     unifyArgs :: CType -> CType -> Maybe CMatch
--     unifyArgs = undefined
--     getFirst :: [Maybe a] -> Maybe a
--     getFirst [] = Nothing
--     getFirst (h@(Just _) : _) = h
--     getFirst (Nothing : rest) = getFirst rest

-- search :: CQuery -> CIndex -> [CMatch]
-- search query = Data.Maybe.mapMaybe (unify query)
