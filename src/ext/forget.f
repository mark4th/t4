\ forget.f      - word forgetting words
\ ------------------------------------------------------------------------

  .( loading forget.f ) cr

\ ------------------------------------------------------------------------

  root definitions

\ ------------------------------------------------------------------------

\ warning:  forgetting the current vocabulary makes forth current and
\           will place forth in context even if it wasnt there previously

\ ------------------------------------------------------------------------

  <headers

  0 var fence               \ cannot forget below this address
  0 var dfence              \

\ ------------------------------------------------------------------------
\ set top of head memory on entry into t4

  headers>

: enclose
  hhere !> fence
  thead !> thead ;

\ ------------------------------------------------------------------------

  <headers

: enclose`
  defers default
  enclose ;

\ ------------------------------------------------------------------------

: ?current
  current =
  if
    forth definitions
  then ;

\ ------------------------------------------------------------------------
\ remove forgotten vocabulary from context and current if its there

: (forgetv)     ( a1 --- a1 )
  dup ?current              \ are we forgetting the current vocabulary ?
  >context 16 swap          \ scan through context stack
  do
    dup i []@               \ get vocabulary address from context
    pluck =                 \ are we forgetting this vocabulary ?
    if
      drop dup
      execute previous
    then
  loop
  drop ;

\ ------------------------------------------------------------------------
\ unlink vocabularies above forgotten word

: ?forgetv       ( a1 --- a1 )
  voclink                   \ have any vocabularies been forgotten

  begin
    2dup >name > not        \ is this a forgotten vocabulary ?
  while
    (forgetv)               \ remove this voc from context if its there
    [ #threads 1+ ]# []@
  repeat
  !> voclink drop ;

\ ------------------------------------------------------------------------
\ return address of first word below a1 in thread

: (trim)    ( a1 top-of-thread --- a1 bottomish-of-thread )
  begin
    2dup > not              \ if word is higher up in mem than a1
  while
    >name                   \ read link to previous word
  repeat ;

\ ------------------------------------------------------------------------
\ trim thread to below a1

: trim          ( a1 thread --- a1 thread )
  dup>r                     \ remember thread address
  @                         \ fetch first item in chain from thread
  ?dup                      \ any words chained in this thread ?
  if
    (trim)                  \ get address of first word in thread below a1
    r@ !                    \ store new end of thread address
  then
  r> cell+ ;

\ ------------------------------------------------------------------------
\ forget word whose nfa is on the stack

: frgt      ( nfa --- )
  voclink                   \ get address of most recent vocabulary
  begin                     \    ( a1 voc --- )
    >body #threads rep trim

    \ now pointing at link to previous voc

    @ ?dup 0=               \ null link?
  until ;

\ ------------------------------------------------------------------------
\ delete all words from voc that are above word a1

\ a2 is the address within a vocabulary that links to the previous voc

: (forget)      ( a1 voc --- a1 a2 )
  dup fence <
  abort" Below Fence"

  frgt ?forgetv             \ handle vocabularies being forgotten

  dfence !> dp
  fence  !> hp ;

\ ------------------------------------------------------------------------

  headers>

: forget        ( --- )
  ' >name frgt ;             \ point at nfa of word to forget and forget it

\ ------------------------------------------------------------------------
\ word to forget everything above fence

: empty
  fence dup hp <>           \ are we already empty?
  if                        \ if not then...
    l>name (forget)         \ point to nfa of word at fence
  else
    dfence !> dp            \ probably dont need to do this
    drop
  then ;

\ ------------------------------------------------------------------------

  behead forth definitions

\ ========================================================================
