module QueryParser.Parser (parseCQuery) where

import Data.Functor (($>))
import Model.CType
import Model.Query
import QueryParser.Lexer
import Text.Parsec
import Text.Parsec.Pos

type QParser a = Parsec [QToken] () a

-- | Парсер одного токена, рассматривает отдельные символы.
type QTokenParser a = Parsec QToken () a

-- | Из типа всё понятно.
tokSatMap :: (QToken -> Maybe a) -> QParser a
tokSatMap = tokenPrim id update
  where
    update pos t _ = updatePosString pos t

-- | Свой `satisfy` для потока токенов.
tokSat :: (QToken -> Bool) -> QParser QToken
tokSat p = tokSatMap testToken
  where
    testToken t = if p t then Just t else Nothing

parseToken :: QTokenParser a -> QParser a
parseToken p = do
  source <- sourceName <$> getPosition
  tokSatMap $ either (const Nothing) Just . parse p source

tok :: QToken -> QParser QToken
tok t = tokSat (== t)

inParens :: QParser a -> QParser a
inParens = between (tok "(") (tok ")")

inAngles :: QParser a -> QParser a
inAngles = between (tok "<") (tok ">")

parseCKind :: QParser CKind
parseCKind = tok "Type" $> CKType <|> tok "Value" $> CKValue

parseIdentifier :: QTokenParser Char -> QParser String
parseIdentifier initial = parseToken $ (:) <$> initial <*> many (alphaNum <|> char '_')

parseName :: QParser String
parseName = parseIdentifier (lower <|> upper <|> char '_' <|> char ':')

parseCVar :: QParser CVar
parseCVar = parseName

parseKindAnnotation :: QParser (CVar, CKind)
parseKindAnnotation = inAngles $ do
  var <- parseCVar
  _ <- tok ":"
  kind <- parseCKind
  return (var, kind)

parseKindAnnotations :: QParser [(CVar, CKind)]
parseKindAnnotations = tok "forall" *> many parseKindAnnotation <|> pure []

parseCType :: QParser CType -> QParser CType
parseCType atom = do
  pre_modifiers <- parsePreModifiers
  atom_type <- atom
  post_modifiers <- parsePostModifiers
  let premodified = foldr (\modifier acc -> modifier acc) atom_type pre_modifiers
  return $ foldl (\acc modifier -> modifier acc) premodified post_modifiers
  where
    parseTemplateArgs = flip CTApplication <$> inAngles (sepBy (CTAType <$> parseCType atom) (tok ","))
    parsePointer = tok "*" $> CTPointer
    parsePostModifiers :: QParser [CType -> CType]
    parsePostModifiers = many (parseTemplateArgs <|> parsePointer)
    parseConst = tok "const" $> CTConst
    parseVolatile = tok "volatile" $> CTVolatile
    parsePreModifiers :: QParser [CType -> CType]
    parsePreModifiers = many (parseConst <|> parseVolatile)

atomParser :: [CVar] -> QParser CType
atomParser vars_names = process <$> parseName
  where
    process name = if name `elem` vars_names then CTVar name else CTName name

parseCQuery :: QParser CQuery
parseCQuery = do
  template_args <- parseKindAnnotations
  let vars_names = fst <$> template_args
  args <- inParens (sepBy (parseCType $ atomParser vars_names) $ tok ",")
  _ <- tok "->"
  CQuery . CDeclType template_args args <$> parseCType (atomParser vars_names)
