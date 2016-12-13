\ hello.f       - this file needs lots of work :)
\ ------------------------------------------------------------------------

  .( loading hello.f ) cr

\ ------------------------------------------------------------------------

  <headers

  0 var dohello

\ ------------------------------------------------------------------------
\ display version

  headers>

: .version
  base decimal              \ construct version string backwards
  <# 'b' hold               \ still in beta
  version dup>r $ff and
  0 # # '.' hold drop
  r> 8 u>> 0 #s drop
  'V' hold #>
  type !> base ;

\ ------------------------------------------------------------------------
\ display signon message

: hello
  ['] noop is .$buffer      \ prevent output of terminal strings
  ['] c>$ is emit           \ emit appends to terminal string buffer
  0$buffer

  black >bg
  white >fg
  clear
  magenta >bg

  cols 2/ 18 -              \ console mid point minus window mid point
  7 over at 33 spaces
  13 8                      \ draw window centred on console
  do
    i over 1- at
    35 spaces
  loop
  13 over at 33 spaces

  8 over at
  ."     Thumb2 Forth : "
  >bold .version <bold

  cyan >fg >bold
  12 swap 5 + at ."  by Mark I Manning IV "
  rows 3 - 0 at
  >norm black >bg white >fg

  ['] (.$buffer) is .$buffer
  ['] (emit) is emit

 .$buffer ;

\ ------------------------------------------------------------------------
\ display t4s active time at exit blah blah

  <headers

: exitelapsed
  defers atexit
  dohello not ?exit         \ did we do a hello?
  cr ." Active For "        \ if so display how long we ran for
  .elapsed ;

\ ------------------------------------------------------------------------
\ patch hello into default yet still allow hello interactively

: ?hello
  defers default
  timer-reset               \ start timer for how long t4 is active
  intty not ?exit
  on> dohello               \ enable "hello"
  hello ;                   \ run hello

\ ------------------------------------------------------------------------

  behead

\ ========================================================================
