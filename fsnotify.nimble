# Package

version       = "0.1.0"
author        = "flywind"
description   = "A file system monitor in Nim."
license       = "Apache-2.0"
srcDir        = "src"


# Dependencies

requires "nim >= 1.2.6"
requires "xio >= 0.1.0"

task tests, "Run all tests":
  exec "testament all"
