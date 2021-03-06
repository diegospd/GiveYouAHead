




module Macro.MacroParser
    (
    textE,
    macroE,
    MacroNode(..),
    getEither,
    toMacro
    ) where

      import Text.Parsec(Parsec,many,noneOf,char,space,(<|>),parse,oneOf,anyChar,string,try)
      --import Control.Applicative(some)

      data MacroNode = Text String
                     | Macro String
                     | MacroDef String String
                     | Include FilePath
                     | List String [String]
                     | Lister String
                     | Flag String [(String,String)]
                     deriving (Eq)

      instance Show MacroNode where
        show (Text a) = a
        show (MacroDef a b) = "MacroDefiniton " ++ a ++ " -> " ++ b
        show (Include a) = "Included file: " ++ a
        show (Macro a) = "Macro "++a
        show (List a b) = "List " ++ a ++ " = " ++ show b
        show (Lister s) = "List maker " ++ s
        show (Flag a cases) = "Flag "++a++"=="++show cases



      toMacro :: String -> [MacroNode]
      toMacro = getEither.parse textE "error all".(++"\0")

      getEither :: Show b => Either b a -> a
      getEither (Right x) = x
      getEither (Left x) = error $ show x


      textE :: Parsec String () [MacroNode]
      textE = do
        text <- many (noneOf "\\\0") <* (char '\\' <|> char '\0')
        others <- many $ macroE <|> textE
        return $ mconcat $ [Text text]:others

      macroE :: Parsec String () [MacroNode]
      macroE = do
        macroName <- many (noneOf "\n {}\\\0") <* (char '\\' <|> space <|> char '{'<|> char '\0' <|> char ' ' <|> char '\n')
        case macroName of
          "def" -> do
            mde <- many macroDefE
            many (char ' ' <|> char '\n' <|> char '\0')
            others <- many $ textE <|> macroE
            return $ mconcat $ mde++others
          "list" -> do
            l <- many listE
            many (char ' ' <|> char '\n' <|> char '\0')
            others <- many $ textE <|> macroE
            return $ mconcat $ l++others
          "include" -> do
            file <- many (noneOf "\n}") <* char '}'
            many $ char '\n'
            -- many (char ' ' <|> char '\n' <|> char '\0')
            others <- many $ textE <|> macroE
            return $ mconcat $ [Include file]:others
          "lister" ->do
            s <- many (noneOf "}") <* char '}'
            many $ char '\n'
            -- <* oneOf "\n \0"  -- many (noneOf " \n\0") <* (char ' ' <|> char '\n' <|> char '\0')
            others <- many $ textE <|> macroE
            return $ mconcat $ [Lister s]:others
          "flag" -> do
            f <- many flagE
            others <- many $ textE <|> macroE
            return $ mconcat $ f++others
          "@bs" -> do
            others <- many $ textE <|> macroE
            return $ mconcat $ [Text "\\"]:others
          "@lb" -> do
            others <- many $ textE <|> macroE
            return $ mconcat $ [Text "{"]:others
          "@rb" -> do
            others <- many $ textE <|> macroE
            return $ mconcat $ [Text "}"]:others
          _ -> do
            others <- many $ textE <|> macroE
            return $ mconcat $ [Macro macroName]:others


      flagE :: Parsec String () [MacroNode]
      flagE = do
        flagName <- many (noneOf "\n {}\\\0") <* char '}'
        many $ char '\n'
        string "\\case{"
        cases <- caseE
        many $ char '\n'
        return [Flag flagName cases]

      caseE:: Parsec String () [(String,String)]
      caseE = do
        caseName <- many (noneOf "}") <* char '}'
        (x,caseText) <- tE
        -- _ <- string "\\case{"
        othercases <- if x then return [] else caseE
        return $ (caseName,caseText):othercases
        where
          {-stE = do
            string "\\case{"
            return (False,"")-}
          tE = do
            t <- many (noneOf "{\n") <* oneOf "{\n"
            let q = t == "\\flagend"
            let p = t == "\\case"
            if q then
                return (True,"")
              else if p then
                  return (False,"")
                else do
                  (x,ot) <- tE
                  return (x,t++"\n"++ot)
            {-case t of
              "\\flagend" -> return (True,"")
              "\\case{" -> return (False,"")
              t' -> do
                [(x,ot)] <- many tE
                return (x,t'++"\n"++ot)-}
          {-flagEndE = do
            string "\\endflag"
            return (True,"")-}

      macroDefE :: Parsec String () [MacroNode]
      macroDefE = do
        macroName <- many (noneOf " {}\\\0") <* char '{'
        macroText <- many (noneOf "}") <* char '}'
        many $ char '\n'
        others <- many $ textE <|> macroE
        return $ mconcat $ [MacroDef macroName macroText]:others

      listE :: Parsec String () [MacroNode]       -- 不推荐定义 list
      listE = do
        listName <- many (noneOf "{}\\\0") <* char '}'
        listText <- many (noneOf "}") <* char '}'  --换行分割
        many $ char '\n'
        others <- many $ textE <|> macroE
        return $ mconcat $ [List listName $ lines $ tail listText]:others
