module Match.Unify where

import Control.Monad (zipWithM)
import Data.Bifunctor
import Data.List (permutations)
import Data.Map qualified as Map
import Data.Maybe (fromMaybe, mapMaybe)
import Model.CType
import Model.Query

replace :: CType -> CUnificator -> CType
replace v@(CTName _) _ = v
replace v@(CTVar var) unificator = fromMaybe v (var `Map.lookup` unificator)
replace (CTApplication h args) unificator = CTApplication (replace h unificator) (replaceArg <$> args)
  where
    replaceArg (CTAType t) = CTAType $ replace t unificator
    replaceArg v = v
replace (CTPointer inner) unificator = CTPointer $ replace inner unificator
replace (CTLRef inner) unificator = CTLRef $ replace inner unificator
replace (CTRRef inner) unificator = CTRRef $ replace inner unificator
replace (CTConst inner) unificator = CTConst $ replace inner unificator
replace (CTVolatile inner) unificator = CTVolatile $ replace inner unificator
replace v@CTUnresolved _ = v

compatibleWithN :: CName -> CName -> Bool
compatibleWithN = (==) -- TODO: add upcasts, trivial conversions and constructors

sameAsT :: CType -> CType -> Bool
sameAsT = (==) -- TODO: add modifiers-aware comparasion

compatibleWithT :: CType -> CType -> Bool
compatibleWithT = sameAsT

joinUnificator :: CUnificator -> CUnificator -> Maybe CUnificator
joinUnificator l r = Map.union (symmetricDifference l r) <$> sequenceA (Map.intersectionWith joiner l r)
  where
    joiner :: CType -> CType -> Maybe CType
    joiner lt rt = if sameAsT lt rt then Just lt else Nothing
    symmetricDifference l' r' = Map.difference l' r' `Map.union` Map.difference r' l'

unifyType :: CType -> CType -> Maybe CUnificator -- (target, query) -> unificator (nessesary variables values)
unifyType (CTName tgt) (CTName req) = if compatibleWithN tgt req then Just Map.empty else Nothing
unifyType (CTVar var) t = Just $ Map.singleton var t
unifyType (CTApplication lh largs) (CTApplication rh rargs) = do
  h <- unifyType lh rh
  Nothing
unifyType _ _ = Nothing

unifyTypes :: [CType] -> [CType] -> Maybe CUnificator
unifyTypes l r =
  if length l /= length r
    then Nothing
    else case zipWithM unifyType l r of
      Just unifiers -> foldr (\a b -> b >>= joinUnificator a) (Just Map.empty) unifiers
      Nothing -> Nothing

unifyArgs :: [CTemplateArg] -> [CTemplateArg] -> Maybe CUnificator
unifyArgs = undefined
  where
    collect :: [CTemplateArg] -> [CTemplateArg] -> Maybe ([(CType, CType)], [(Integer, Integer)])
    collect (CTAType t : r) (CTAType t' : r') = Data.Bifunctor.first ((t, t') :) <$> collect r r'
    collect (CVAValue t : r) (CVAValue t' : r') = Data.Bifunctor.second ((t, t') :) <$> collect r r'
    collect [] [] = Just ([], [])
    collect _ _ = Nothing

unifyDecls CDeclType {template_args, arguments, result} CDeclType {template_args = template_args', arguments = arguments', result = result'} = do
  args_unificator <- unifyTypes arguments arguments'
  let target_result = replace result args_unificator
  let query_result = replace result args_unificator
  if compatibleWithT target_result query_result
    then
      Nothing
    else
      Just args_unificator

unify :: CQuery -> CDecl -> Maybe CMatch
unify q@CQuery {target = CDeclType {template_args, arguments, result}} d@CDecl {name, ctype, location} =
  CMatch q d <$> getFirst (unifyDecls ctype . (\args_permutation -> CDeclType template_args args_permutation result) <$> permutations arguments)
  where
    getFirst :: [Maybe a] -> Maybe a
    getFirst [] = Nothing
    getFirst (h@(Just _) : _) = h
    getFirst (Nothing : rest) = getFirst rest

search :: CQuery -> CIndex -> [CMatch]
search query = Data.Maybe.mapMaybe (unify query)
