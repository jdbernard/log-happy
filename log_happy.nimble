# Package

version       = "0.1.0"
author        = "Jonathan Bernard"
description   = "Scan logs for regex-defined events and report on what was found."
license       = "MIT"
bin           = @["log_happy"]

# Dependencies

requires @["nim >= 0.16.1", "docopt >= 0.6.4", "ncurses"]

