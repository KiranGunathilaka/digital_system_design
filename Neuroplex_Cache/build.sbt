import sbt._
import Keys._

ThisBuild / organization := "Neuroplex"
ThisBuild / name         := "NeuroplexCache"
ThisBuild / version      := "0.1.0"

// Use a scala version that has matching chisel3-plugin artifacts
ThisBuild / scalaVersion := "2.12.17"

// Enable compiler plugins in sbt
ThisBuild / autoCompilerPlugins := true  // :contentReference[oaicite:2]{index=2}

resolvers ++= Seq(
  Resolver.sonatypeRepo("releases")
)

lazy val root = (project in file("."))
  .settings(
    maxErrors := 3,

    libraryDependencies ++= Seq(
      "edu.berkeley.cs" %% "chisel3"    % "3.5.6",
      "edu.berkeley.cs" %% "chiseltest" % "0.5.6" % Test
    ),

    // Chisel compiler plugin (must match Chisel major/minor)
    addCompilerPlugin("edu.berkeley.cs" % "chisel3-plugin" % "3.5.6" cross CrossVersion.full), // :contentReference[oaicite:3]{index=3}

    scalacOptions --= Seq("-Xfatal-warnings")
  )

addCommandAlias("com", "all compile test:compile")
addCommandAlias("rel", "reload")
addCommandAlias("fmt", "all scalafmtSbt scalafmtAll")
