
  ' ktotal >body off

  cr cr

  compiler definitions

  fload src/ext/comment.f   \ * commenting words

\ ------------------------------------------------------------------------
\ *     required files
\ +     optional files
\ -     dont include in turnkey apps
\ ------------------------------------------------------------------------

: ..  '.' (emit) ;
: ... .. ; immediate

\ ------------------------------------------------------------------------
\ most of this is required

  fload src/ext/loops.f     \ * loop and branch compilation words
  fload src/ext/compile.f   \ * does> etc
  fload src/ext/variable.f  \ * variable creating words etc

  forth definitions

  fload src/ext/number.f    \ * pictured number output
  fload src/ext/utils.f     \ * usefull stuff to have around
  fload src/ext/vocabs.f    \ *
  fload src/ext/header.f    \ * headerless word creation
  fload src/ext/dump.f
  fload src/ext/struct.f    \ * structure definition words
  fload src/ext/stacks.f    \ * software stacks
  fload src/ext/fsave.f     \ * turnkey and fsave
  fload src/ext/tty.f       \ * terminal initializtion
  fload src/ext/args.f      \ * command line args primatives
  fload src/ext/env.f       \ * environment searching
  fload src/ext/case.f      \ * case statements
  fload src/ext/list.f      \ * linked list words

\ ------------------------------------------------------------------------
\ extend is an implied bye and atexit will mess up the termainl
\ if we do not do this here

  (init-term)               \ defined in tty.f

\ ------------------------------------------------------------------------
\ displays offending line number during an fload

: (.line#)
  floads 0= ?exit
  ." Line Number " line# . ;

  ' (.line#) is .line#

\ ------------------------------------------------------------------------
\ memory manager

\ while this is marked as optonal there are alot of extensions below that
\ depend on this

  .( loading mem-manager: )

  fload src/ext/memman/memory.f       \ +
  fload src/ext/memman/util.f         \ +
  fload src/ext/memman/heap.f         \ +
  fload src/ext/memman/alloc.f        \ +
  fload src/ext/memman/dealloc.f      \ +
  fload src/ext/memman/info.f         \ +-

  behead

\ ------------------------------------------------------------------------

  fload src/ext/file.f               \ + file i/o
  fload src/ext/datetime/timer.f     \ + delays and elapsed time measurement
  fload src/ext/datetime/localtime.f \ +- displaying time and timing things
  fload src/ext/datetime/date.f      \ +-

  behead

\ ------------------------------------------------------------------------

  fload src/ext/rnd.f                \ + random number generator
  fload src/ext/message.f            \ +

\ ------------------------------------------------------------------------
\ terminfo handling etc

  .( loading terminfo: )

  fload src/ext/terminal/term.f      \ + curses without the cussing
  fload src/ext/terminal/tformat.f   \ + terminfo format strings
  fload src/ext/terminal/terminfo.f  \ + terminfo parsing etc
  fload src/ext/terminal/color.f     \ + colour output
  fload src/ext/terminal/keys.f      \ + common keyboard handler code
\  fload src/ext/terminal/twinch.f    \ + window change signal handling

  behead forth definitions cr

\ ------------------------------------------------------------------------
\ the above modules have not been beheaded yet

  .( loading text-ui:  )

  fload src/ext/tui/tui.f        \ + text user interface (aka curses)
  fload src/ext/tui/scrdsp.f     \ + screen display update
  fload src/ext/tui/screen.f     \ + screen creation
  fload src/ext/tui/windsp.f     \ + window display update
  fload src/ext/tui/window.f     \ + window creation
  fload src/ext/tui/border.f     \ + draw window borders

  .( loading menus:    )

  fload src/ext/tui/menu.f       \ + pulldown menus
  fload src/ext/tui/menudsp.f    \ + menu display
  fload src/ext/tui/menuctl.f    \ + menu control

  behead forth definitions

\ ------------------------------------------------------------------------
\ sockets related (work in progress but useable - no dns yet :)

\  fload src/ext/sockets.f        \ + socket connect/read/write

\ ------------------------------------------------------------------------
\ some usefull utils

  fload src/ext/words.f          \ -- vocabulary listings
  fload src/ext/forget.f         \ - forget, empty etc
  fload src/ext/history.f        \ -- command line history
  fload src/ext/hello.f          \ -- nice signon message
  fload src/ext/status.f         \ -- status line display
  fload src/ext/tail.f           \ -- default args handler

\ ------------------------------------------------------------------------
\ custom initialization

  fload src/ext/init.f          \ + interpret ~/.t4.rcf

\ ------------------------------------------------------------------------
\ save out extended forth - does not return - implied bye

  cr .( depth = ) depth .
  cr .( compiled ) ktotal . .( bytes )
  cr .( writing extended compiler ) cr

  forth definitions

  fsave t4

\ ========================================================================
