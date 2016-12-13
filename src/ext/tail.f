\ tail.f        - command line tail processing
\ ------------------------------------------------------------------------

  .( loading tail.f ) cr

\ ------------------------------------------------------------------------

  <headers

\ this code should not be included in any turnkey applications. this is
\ the t4 development environments default arg processing code.
\
\ see args.f for details on how to produce something similar for your own
\ code

\ ------------------------------------------------------------------------

  0 var floading            \ defer fload till after default init

\ ------------------------------------------------------------------------
\ for shebanged forth script files

  headers>

: #!
  on> shebang               \ shebang line must contain a -sfload
  floading                  \ dont allow -f in the #! line
  if
    ." Do not use -f in the shebang line" cr
    ." Your shebang should use -s instead " cr cr
    0 <exit>
  then
  [compile] \ ;

\ ------------------------------------------------------------------------
\ exit now if t4 was executed via a shebanged forth source

  <headers

: ?shebang
  shebang not ?exit
  errno <exit> ;

\ ------------------------------------------------------------------------

: arg-missing?
  arg# argc =
  if
    cr ." Missing Argument"
    cr 0 <exit>
  then ;

\ ------------------------------------------------------------------------

: arg-h
  cr
  ."  -f FILE                   Interpret specified file" cr
  ."  #! t4 -s                  Place at top of shebanged script" cr
  ."  -h                        Your reading it" cr cr 0 <exit> ;

\ do not use -f on the shebang line in a script as this will cause the
\ default init chain to run before the script is executed.

\ ------------------------------------------------------------------------

: arg>tib
  #tib >r                   \ get current length of tib
  arg@ dup strlen           \ get filename string
  dup +!> #tib              \ copy filename into tib
  tib r> + swap cmove
  bl tib #tib [c]!
  incr> #tib ;

\ ------------------------------------------------------------------------
\ execute an fload of specified file

  here ," fload "           \ here picked up by "literal" below

: do-s
  arg-missing?              \ fload expects a file name
  literal count dup !> #tib \ copy "fload " to tib
  tib swap cmove arg>tib
  begin                     \ keep interpreting this fload and
    interpret               \ refiling input until the fload ends and
    ['] refill >body @      \ the refill mechanism is restored to its
    ['] query =             \ default of query
  until ;                   \ interpret specified file

\ ------------------------------------------------------------------------

: do-f
  arg# !> floading          \ remember current arg position
  argc !> arg# ;            \ halt processing of args till after default

\ ------------------------------------------------------------------------

args: dargs                 \ t4s default args list
  arg" -f"                  \ fload a file specified on the arg list
  arg" -s"                  \ fload a shebanged script
  arg" -h"                  \ display info on args
;args

\ ------------------------------------------------------------------------

: (doargs)
  off> shebang              \ assume not running from #! script
  dargs                     \ init for arg scan of this list
  begin
    off> #tib off> >in
    ?arg                    \ is next arg in list known to us?
    case:
      0 opt arg-h           \ unknown arg
      1 opt do-f            \ fload specified file
      2 opt do-s            \ fload a shebanged script
      3 opt arg-h           \ display useage info
    ;case
    arg# argc =
  until ;

\ ------------------------------------------------------------------------
\ this word patches itself into the hi priority default init chain

: doargs          ( ---- )
  defers pdefault
  argc                      \ dont try interpret null args
  if
    (doargs)                \ process args
    ?shebang                \ quit now if we just ran a #! script
  then ;                    \ otherwise....

\ ------------------------------------------------------------------------
\ this word patches itself into the low priority default init chain

\ -s will be handled prior to any initialization via default so
\ .hello and .status etc are not dumped to the display for script files.
\ also, when the script completes forth quits and init never gets run at
\ all.  this means that scripts cannot use some things that are not
\ initialized (like the text windowing stuff).
\
\ -f just sets a flag which tells the following word to do the fload.
\ this word is not executed until everything else in the default init
\ chain has run so everything will have been initialized.

: do-floading
  defers ldefault
  floading ?dup             \ did do-args set this?
  if
    off> floading
    !> arg#
    do-s
  then ;

\ ------------------------------------------------------------------------

 behead

\ ========================================================================
