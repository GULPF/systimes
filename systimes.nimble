# Package

version       = "0.2.1"
author        = "Oscar Nihlgård"
description   = "An alternative DateTime implementation for Nim"
license       = "MIT"

skipFiles = @["tests.nim"]

# Dependencies

requires "nim >= 0.18.1"

task docs, "Generate docs":
    exec "nim doc -o:docs/systimes.html systimes.nim"