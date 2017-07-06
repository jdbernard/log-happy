import ncurses
export ncurses

proc keypad*(win: ptr window, enable: bool): int {.cdecl, discardable, importc: "keypad", dynlib: libncurses.}
proc scrollok*(win: ptr window, enable: bool): int {.cdecl, discardable, importc: "scrollok", dynlib: libncurses.}
proc nodelay*(win: ptr window, enable: bool): int {.cdecl, discardable, importc: "nodelay", dynlib: libncurses.}
proc nonl*(): int {.cdecl, discardable, importc: "nonl", dynlib: libncurses.}

proc newwin*(num_rows, num_cols, begin_x, begin_y: int): ptr window {.cdecl, discardable, importc: "newwin", dynlib: libncurses.}
proc delwin*(win: ptr window): int {.cdecl, discardable, importc: "delwin", dynlib: libncurses.}
#proc newwin(num_rows, num_cols, begin_x, begin_y: int): ptr window {.cdecl, discardable, importc: "newwin", dynlib: libncurses.}

#proc wgetch*(win: ptr window): int {.cdecl, discardable, importc: "wgetch", dynlib: libncurses.}
proc wrefresh*(win: ptr window): int {.cdecl, discardable, importc: "wrefresh", dynlib: libncurses.}
proc wclear*(win: ptr window): int {.cdecl, discardable, importc: "wclear", dynlib: libncurses.}
proc mvwhline*(win: ptr window, rol, col: int, chType: char, n: int): int {.cdecl, discardable, importc: "whline", dynlib: libncurses.}
proc wmove*(win: ptr window, rol, col: int): int {.cdecl, discardable, importc: "wmove", dynlib: libncurses.}
proc wprintw*(win: ptr window, str: cstring): int {.cdecl, discardable, importc: "wprintw", dynlib: libncurses.}
#proc mvwprintw*(win: ptr window, row, col: int, str: cstring): int {.cdecl, discardable, importc: "mvwprintw", dynlib: libncurses.}

proc box*(win: ptr window, vert_border, horiz_border: char): int {.cdecl, discardable, importc: "box", dynlib: libncurses.}
proc wborder*(win: ptr window, ls,rs,ts,bs,tl,tr,bl,br: char): int {.cdecl, discardable, importc: "wborder", dynlib: libncurses.}

proc init_pair*(n, f, b: int): int {.cdecl, discardable, importc: "init_pair", dynlib: libncurses.}
proc COLOR_PAIR*(n: int): int {.cdecl, discardable, importc: "COLOR_PAIR", dynlib: libncurses.}

proc wattron*(win: ptr window, attrs: int): int {.cdecl, discardable, importc: "wattron", dynlib: libncurses.}
proc wattroff*(win: ptr window, attrs: int): int {.cdecl, discardable, importc: "wattron", dynlib: libncurses.}

const BLACK* = 0
const RED* = 1
const GREEN* = 2
const YELLOW* = 3
const BLUE* = 4
const MAGENTA* = 5
const CYAN* = 6
const WHITE* = 7


