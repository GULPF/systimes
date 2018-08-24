# Package

version       = "0.2.0"
author        = "Oscar Nihlgård"
description   = "An alternative DateTime implementation for Nim"
license       = "MIT"

# Dependencies

requires "nim >= 0.18.1"

task docs, "Generate docs":
    exec "nim doc -o:docs/systimes.html systimes.nim"