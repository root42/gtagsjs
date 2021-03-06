module Main (main) where

import Data.Set (Set, member)
import qualified Data.Set as Set

import Distribution.PackageDescription hiding (Flag)
import Distribution.Simple
import Distribution.Simple.BuildPaths
import Distribution.Simple.LocalBuildInfo
import Distribution.Simple.Program
import Distribution.Simple.Setup
import Distribution.Text
import qualified Distribution.Verbosity as Verbosity

import System.Directory (removeFile)
import System.IO.Error (try)
import System.Process (system)

main :: IO ()
main = defaultMainWithHooks simpleUserHooks'
  where
    simpleUserHooks' = simpleUserHooks
      { preConf = myPreConf
      , confHook = myConfHook
      , postConf = myPostConf
      , postClean = myPostClean
      }
    
    myPreConf x configFlags =
      preConf simpleUserHooks x configFlags'
      where
        configFlags' = updateConfigFlags configFlags
    
    myConfHook x configFlags =
      confHook simpleUserHooks x configFlags'
      where
        configFlags' = updateConfigFlags configFlags
    
    myPostConf x configFlags desc y = do
      writeFile "config.h" configH
      postConf simpleUserHooks x configFlags' desc y
      where
        configH =
          concat
          [ "#ifndef CONFIG_H\n"
          , "#define CONFIG_H\n"
          , "\n"
          , "#define GTAGSJS_ROOT " ++ gtagsjsRoot ++ "\n"
          , "\n"
          , "#endif"
          ]
        gtagsjsRoot =
          concat ["__stginit_", encoded, "_Gtagsjs"]
          where
            encoded = zEncode (show . disp . packageId $ desc)
        configFlags' = updateConfigFlags configFlags
    
    myPostClean _ _ _ _ = do
      try . removeFile $ "config.h"
      return ()
      
    updateConfigFlags configFlags =
      configFlags { configSharedLib = Flag True }

zEncode :: String -> String
zEncode = concatMap encodeChar
  where
    encodeChar x =
      case x of
        'z' -> "zz"
        'Z' -> "ZZ"
        '(' -> "ZL"
        ')' -> "ZR"
        '[' -> "ZM"
        ']' -> "ZN"
        ':' -> "ZC"
        '&' -> "za"
        '|' -> "zb"
        '^' -> "zc"
        '$' -> "zd"
        '=' -> "ze"
        '>' -> "zg"
        '#' -> "zh"
        '.' -> "zi"
        '<' -> "zl"
        '-' -> "zm"
        '!' -> "zn"
        '+' -> "zp"
        '\'' -> "zq"
        '\\' -> "zr"
        '/' -> "za"
        '*' -> "zt"
        '_' -> "zu"
        '%' -> "zv"
        x | x `member` regularLetters -> [x]       
          | otherwise -> undefined
    regularLetters = Set.fromList (concat [ ['a'..'y']
                                          , ['A'..'Y']
                                          , ['0'..'9']
                                          ])
