## Log Happy
## =========
##
## Little tool to extract expected information from log streams.
import json, logging, ncurses, os, osproc, sequtils, streams, strutils, threadpool
import nre except toSeq

import private/ncurses_ext

from posix import signal

type
  Expectation* = ref object
    label: string
    pattern: Regex
    expected, found: bool

let expPattern = re"^-([eE])([^;]+);(.+)$"

var msgChannel: Channel[string]

proc exitErr(msg: string): void =
  stderr.writeLine "log_happy: " & msg
  quit(QuitFailure)

proc readStream(stream: Stream): void =
  var line = TaintedString""
  try:
    while stream.readLine(line): msgChannel.send(line)
  except: discard ""

when isMainModule:
  var cmdProc: Process
  var inStream: Stream
  var outFile: File

  try:
    let VERSION = "0.1.0"
    let usage = """
Usage:
  log_happy [options]
  log_happy <filename> [options]
  log_happy [options] -- <cmd>

Options:

  -v                        Print version information and exit.
  -e<label>;<pattern>       Add something to expect to see in the log stream.
  -E<label>;<patterh>       Add something to expect not to see in the log stream.
  -d<def-file>              Read expectations from a JSON definitions file.
  -i<in-file>               Read JSON definitions from <in-file>.
  -o<out-file>              Write the log to <out-file>. Usefull for viewing
                            output later when executing commands.
  -f                        Similar to tail, do not stop when the end of file
                            is reached but wait for additional modifications
                            to the file. -f is ignored when the input is STDIN.

Expectation definitions take the format LABEL;REGEX where the LABEL is the text
label log_happy will use to describe the event, and REGEX is the regular
expression log_happy will use to identify the event.

Expectations JSON definitions follow this format:
  {
    "expected": {
      "<label>": "<regex>",
      "<label>": "<regex>"
    },
    "unexpected": {
      "<label>": "<regex>",
      "<label>": "<regex>"
    }
  }
"""

    let args = commandLineParams()

    var expectations: seq[Expectation] = @[]
    var follow = false 
    var cmd = "NOCMD"

    if args.len == 0:
      echo usage
      quit(QuitSuccess)

    for arg in args:
      if cmd != "NOCMD": cmd &= " " & arg

      elif arg.startsWith("-d"):
        let filename = arg[2..^1]
        try:
          let defs = parseFile(filename)

          if defs.hasKey("expected"):
            for item in defs["expected"].pairs():
              expectations.add(Expectation(
                label: item.key,
                pattern: re(item.val.getStr()),
                expected: true,
                found: false))

          if defs.hasKey("unexpected"):
            for item in defs["unexpected"].pairs():
              expectations.add(Expectation(
                label: item.key,
                pattern: re(item.val.getStr()),
                expected: false,
                found: false))
        except:
          exitErr "could not parse definitions file (" &
            filename & "):\n\t" & getCurrentExceptionMsg()

      elif arg.startsWith("-i"):
        let filename = arg[2..^1]
        try:
          if not existsFile(filename):
            exitErr "no such file (" & filename & ")"

          inStream = newFileStream(filename)
        except:
          exitErr "could not open file (" & filename & "):\t\n" &
            getCurrentExceptionMsg()

      elif arg.startsWith("-o"):
        let filename = arg[2..^1]
        try:
          outFile = open(filename, fmWrite)
        except:
          exitErr "could not open output file in write mode (" & filename &
            "):\n\t" & getCurrentExceptionMsg()
        
      elif arg.match(expPattern).isSome:
        var m = arg.match(expPattern).get().captures()
        expectations.add(Expectation(
          label: m[1],
          pattern: re(m[2]),
          expected: m[0] == "e",
          found: false))

      elif arg == "-v":
        stdout.writeLine "log_happy v" & VERSION
        quit(QuitSuccess)

      elif arg == "-f": follow = true
      elif arg == "--": cmd = ""
      else: exitErr "unrecognized argument: " & arg
        
    if cmd == "NOCMD" and inStream.isNil:
      exitErr "no input file or command to execute."

    elif inStream.isNil:
      cmdProc = startProcess(cmd, "", [], nil, {poStdErrToStdOut, poEvalCommand, poUsePath})
      inStream = cmdProc.outputStream

    open(msgChannel)
    spawn readStream(inStream)

    # Init ncurses
    let stdscr = initscr()
    var height, width: int
    getmaxyx(stdscr, height, width)

    startColor()
    noecho()
    cbreak()
    keypad(stdscr, true)
    clear()
    nonl()

    init_pair(1, GREEN, BLACK)
    init_pair(2, RED, BLACK)

    # Figure out how much room we need to display our information
    let labelWidth = mapIt(expectations, it.label.len).foldl(max(a, b)) + 10
    let labelsPerLine = width div labelWidth
    let dispHeight = max((expectations.len div labelsPerLine) + 1, 2)
    let logwin = newwin(height - dispHeight, width, 0, 0)
    let dispwin = newwin(dispHeight, width, height - dispHeight, 0)
    dispwin.wborder(' ', ' ', '_', ' ', '_', '_', ' ', ' ')
    dispwin.wrefresh()

    logwin.scrollok(true)
    logwin.nodelay(true)

    # init run loop
    var stop = false
    var firstPass = true
    var drawDisp = false

    while not stop:

      var lineMsg = msgChannel.tryRecv()

      if lineMsg.dataAvailable:
        let line = lineMsg.msg
        if not outFile.isNil: outFile.writeLine(line)
        for expect in expectations:
          if not expect.found:
            if line.find(expect.pattern).isSome:
              expect.found = true
              drawDisp = true

        if drawDisp or firstPass:
          dispwin.wmove(1, 0)
          var labelsOnLine = 0
          for expect in expectations:
            var text =
              if expect.found: " FOUND  "
              else: " MISSING "
            text = align(expect.label & text, labelWidth)

            if expect.expected == expect.found:
              dispwin.wattron(COLOR_PAIR(1))
              dispwin.wprintw(text)
              dispwin.wattroff(COLOR_PAIR(1))

            else:
              dispwin.wattron(COLOR_PAIR(2))
              dispwin.wprintw(text)
              dispwin.wattroff(COLOR_PAIR(2))

            if labelsOnLine == labelsPerLine - 1:
              labelsOnLine = 0
              dispwin.wprintw("\n")
            else: labelsOnLine += 1

          dispwin.wrefresh()
          firstPass = false
              
        logwin.wprintw("\n" & line)
        logwin.wrefresh()

      let ch = logwin.wgetch()

      # Stop on CTRL-D
      if ch == 4:
        stop = true
        if not cmdProc.isNil and cmdProc.running(): cmdProc.terminate()
        break

      # Reset on CTRL-R
      elif ch == 18:
        for expect in expectations: expect.found = false
        drawDisp = true

      sleep 1

#    echo $args
#    echo "\n\n\n"
#
#    for line in lines fin:
#      stdout.cursorUp(1)
#      stdout.eraseLine()
#      stdout.cursorUp(1)
#      stdout.eraseLine()
#
#      stdout.writeLine line

# Scan for patterns
# Print PASS/FAIL when patterns are seen.
  except:
    exitErr getCurrentExceptionMsg()

  finally:
    if not cmdProc.isNil:
      if running(cmdProc): kill(cmdProc)
    else:
      if not inStream.isNil: close(inStream)
    if not outFile.isNil: close(outFile)

    close(msgChannel)
    endwin()
