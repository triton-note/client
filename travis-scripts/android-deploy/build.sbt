name := "Deploy-GooglePlay"

version := "0.0.1"

scalaVersion := "2.11.5"

libraryDependencies ++= Seq(
  "com.google.apis" % "google-api-services-androidpublisher" % "v2-rev16-1.19.1",
  "com.typesafe.scala-logging" %% "scala-logging" % "3.1.0",
  "org.slf4j" % "slf4j-simple" % "1.7.10"
)
