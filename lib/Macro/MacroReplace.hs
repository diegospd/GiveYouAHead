




module Macro.MacroReplace
    (
    splitMacroDef,
    toText,
    findMacro
    ) where

      import Macro.MacroParser(MacroNode(..),toMacro)

      type MacroT = ([MacroNode],[MacroNode])
      --          macrodefiniton,macros


      splitMacroDefStep :: [MacroNode] -> ([MacroNode],[MacroNode]) -> ([MacroNode],[MacroNode])
      --                                macrodefiniton,macros
      splitMacroDefStep [] (x,y) = (x,reverse y)
      splitMacroDefStep (x@(MacroDef _ _):xs) (as,bs) = splitMacroDefStep xs (x:as,bs)
      splitMacroDefStep (x@(List _ _):xs) (as,bs) = splitMacroDefStep xs (x:as,bs)
      splitMacroDefStep (x:xs) (as,bs) = splitMacroDefStep xs (as,x:bs)

      splitMacroDef :: [MacroNode] -> ([MacroNode],[MacroNode])
      --                            macrodefiniton,macros
      splitMacroDef xs = splitMacroDefStep xs ([],[])


      toText :: MacroT -> [MacroNode]
      toText (_,[]) = []
      toText (as,Text b:bs) = Text b : toText(as,bs)
      toText (as,Macro x:bs)= toText (as,toMacro (findMacro as x)++bs)
      toText (as,Lister x:bs) = toText (as,listerMake as (m,m,False)++bs)
        where
          m = toMacro x
      toText (_,_) = error "macro,line 38,MacroReplace"

      findMacro :: [MacroNode] -> String -> String
      findMacro (MacroDef n t:xs) m
        | n==m = t
        | otherwise = findMacro xs m
      findMacro (List _ _:xs) m = findMacro xs m
      findMacro a b = error $ "error line 37,MacroReplace "++show a++"__"++ show b++" <END>"

      listerMake :: [MacroNode] -> ([MacroNode],[MacroNode],Bool) -> [MacroNode]
      listerMake as (Macro b:bs,cs,x)
        | isList as b = let (as',rt,isNull) = findList as b in toMacro rt ++ listerMake as' (bs,cs,x||isNull)
        | otherwise = Macro b:listerMake as (bs,cs,x)
        where
          isList [] _ = False
          isList (d:ds) c =case d of
            List x _-> x==c ||isList ds c
            _ -> isList ds c
          findList [] _ = error "error line 56,MacroReplace"
          findList (List n ms:ds) c
            | n == c = (List n (if bool then [] else tail ms):ds,head ms,bool)
            | otherwise = let (as,rt,isNum) = findList ds c in (List n ms:as,rt,isNum)
            where
              bool = null $ tail ms
          findList (d:ds) c = let (ds',rt,x) = findList ds c in (d:ds',rt,x)
      listerMake as (Text b:bs,cs,x) =
        Text b:listerMake as (bs,cs,x)
      listerMake as ([],bs,x) = if x then [] else listerMake as (bs,bs,x)
      listerMake _ _ = error "macro,line 63,MacroReplace"
