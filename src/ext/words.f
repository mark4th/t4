\ words.f       - vocabulary listing words
\ ------------------------------------------------------------------------

  .( loading words.f ) cr

\ ------------------------------------------------------------------------

  <headers

: l++           ( --- )
  cr ?more ;

\ ------------------------------------------------------------------------

: l+++          ( --- )
  l++ mkey $1b =
  l++ mkey $1b = or ;

\ ------------------------------------------------------------------------
\ display al words in a given vocabulary thread

: ((words))     ( thread --- )
  begin
    dup (.id)               \ display name of current header
    n>link @                \ link back to previous header
    ?dup 0=                 \ till we run out of previous headers
  until ;

\ ------------------------------------------------------------------------
\ display all words in specified vocabulary

: (words)
  #threads 0                \ for the total nunber of threads ina voc do
  do
    dcount ?dup             \ fetch thread. and while its not empty
    if
      ((words))             \ display all the words in that thread
    then
    mkey $1b = ?leave       \ repeat unless someone hit escape
  loop
  drop ;

\ ------------------------------------------------------------------------

: init
  rows 4 - !> idx0
  cols 1- !> idw
  idx0 !> idx
  ['] cr is .idcr
  cr cr white >fg <bold ;

\ ------------------------------------------------------------------------
\ display all words in context

 headers>

: words
  init >context 16 swap
  do
    dup i []@ dup
    >bold '[' emit
    >name count lexmask type
    ']' emit <bold
    l+++ ?leave
    >body (words)
    mkey $1b = ?leave
    l+++ ?leave
  loop
  drop ;

\ ------------------------------------------------------------------------

 behead

\ ========================================================================
