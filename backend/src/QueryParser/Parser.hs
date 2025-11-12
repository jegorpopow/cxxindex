module QueryParser.Parser where 

import Model.Query
import Model.CType
import QueryParser.Lexer
import Control.Applicative (some, asum)
import Data.Functor (($>))
import Data.Set qualified as Set
import Text.Parsec
import Text.Parsec.Pos
import Text.Parsec.Expr
-- import MetaUtils

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
parseCKind = (tok "Type" *> pure CKType) <|> (tok "Value" *> pure CKValue)

parseIdentifier :: QTokenParser Char -> QParser String
parseIdentifier initial = parseToken $ (:) <$> initial <*> many (alphaNum <|> char '_')

parseName :: QParser String
parseName = parseIdentifier (lower <|> upper <|> char '_')

parseCVar :: QParser CVar
parseCVar = parseName 

parseCName :: QParser CName
parseCName = parseName

parseKindAnnotation :: QParser (CVar, CKind)
parseKindAnnotation = inAngles $ do 
  var <- parseCVar
  _ <- tok ":"
  kind <- parseCKind
  return (var, kind)

parseKindAnnotations :: QParser [(CVar, CKind)]
parseKindAnnotations = (tok "forall" *> many parseKindAnnotation) <|> pure []

parseCType :: QParser CType
parseCType = CTVar <$> parseCVar 
   <|> CTName <$> parseCName

parseCQuery :: QParser CQuery
parseCQuery = do 
  template_args <- parseKindAnnotations
  args <- inParens (sepBy parseCType $ tok ",")
  _ <- tok "->"
  ret_type <- parseCType
  return $ CQuery $ CDeclType template_args (Set.fromList args) ret_type
