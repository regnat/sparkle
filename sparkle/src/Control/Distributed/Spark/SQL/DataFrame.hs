{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}

module Control.Distributed.Spark.SQL.DataFrame where

import Control.Distributed.Spark.RDD
import Control.Distributed.Spark.SQL.Context
import Control.Distributed.Spark.SQL.Row
import Data.Text (Text)
import Foreign.JNI
import Language.Java

newtype DataFrame = DataFrame (J ('Class "org.apache.spark.sql.DataFrame"))
instance Coercible DataFrame ('Class "org.apache.spark.sql.DataFrame")

toDF :: SQLContext -> RDD Row -> Text -> Text -> IO DataFrame
toDF sqlc rdd s1 s2 = do
  cls <- findClass "Helper"
  mth <- getStaticMethodID cls "toDF" "(Lorg/apache/spark/sql/SQLContext;Lorg/apache/spark/api/java/JavaRDD;Ljava/lang/String;Ljava/lang/String;)Lorg/apache/spark/sql/DataFrame;"
  col1 <- reflect s1
  col2 <- reflect s2
  unsafeUncoerce . coerce <$>
    callStaticObjectMethod cls mth [ coerce sqlc
                                   , coerce rdd
                                   , coerce col1
                                   , coerce col2
                                   ]

selectDF :: DataFrame -> [Text] -> IO DataFrame
selectDF _ [] = error "selectDF: not enough arguments."
selectDF df (col:cols) = do
  jcol <- reflect col
  jcols <- reflect cols
  call df "select" [coerce jcol, coerce jcols]

debugDF :: DataFrame -> IO ()
debugDF df = do
  cls <- findClass "org/apache/spark/sql/DataFrame"
  mth <- getMethodID cls "show" "()V"
  callVoidMethod df mth []

join :: DataFrame -> DataFrame -> IO DataFrame
join d1 d2 = call d1 "join" [coerce d2]
