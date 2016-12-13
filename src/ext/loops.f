\ loops.f       - looping and branching compilation words
\ ------------------------------------------------------------------------

  .( loading loops.f ) cr

\ ------------------------------------------------------------------------
\ initialize a forward branch

: >mark         ( --- a1 )
  here                      \ remember address where branch takes place
  0 w, ;                    \ fill in dummy branch vector

\ ------------------------------------------------------------------------
\ resolve a forward branch

: >resolve      ( a1 --- )
  dup here swap - 1+        \ get address we are branching to
  swap w! ;                 \ store in branch vector we are branching from

\ ------------------------------------------------------------------------
\ initialize a backward branch

: <mark here ;

\ ------------------------------------------------------------------------
\ resolve a backward branch

: <resolve      ( a1 --- )
  here - 1+ w, ;

\ ------------------------------------------------------------------------
\ compile an if statement

: if            ( --- a1 )
  compile ?branch           \ compile conditional branch
  >mark ; immediate         \ compile dummy branch target

\ ------------------------------------------------------------------------
\ compile else part of an if statement

: else          ( a1 --- a2 )
  compile branch            \ unconditional branch at end of if part
  >mark                     \ to unknown end of else part
  swap >resolve ; immediate \ resolve if branch vector

\ ------------------------------------------------------------------------
\ resolve target for if/else

: then          ( a1 --- )
  >resolve ; immediate      \ resolve if/else forward branch

\ ------------------------------------------------------------------------
\ compile the starting point of a begin loop

: begin         ( --- a1 )
  <mark ; immediate

\ ------------------------------------------------------------------------
\ compile infinite loop back to begin

: again
  compile branch
  <resolve ; immediate

\ ------------------------------------------------------------------------
\ compile while part of... begin test-here while still-true-part repeat

: while
  compile ?branch
  >mark swap ; immediate

\ ------------------------------------------------------------------------
\ resolve begin while repeat loop

: repeat
  compile branch
  <resolve
  >resolve ; immediate

\ ------------------------------------------------------------------------
\ compile conditional branch back to begin

: until
  compile ?branch
  <resolve ; immediate

\ ------------------------------------------------------------------------
\ compile a do loop into new definition

: do            ( --- a1 )
  compile (do)              \ compile (do) and a dummy loop exit point
  >mark ; immediate         \  to be back filled in later

\ ------------------------------------------------------------------------
\ compile a conditional do loop into new definition

: ?do           ( --- a1 )
  compile (?do)             \ compile (?do) and
  >mark ; immediate         \ dummy loop exit point

\ ------------------------------------------------------------------------
\ compile resolution of previously compile do or ?do loop

: loop          ( a1 --- )
  compile (loop)            \ compile (loop)
  dup 2+                    \ resolve address to loop back to
  <resolve
  >resolve ; immediate      \ resolve loop exit point at (do)/(?do)

\ ------------------------------------------------------------------------

: +loop         ( a1 --- )
  compile (+loop)           \ compile (+loop)
  dup 2+                    \ resolve address to loop back to
  <resolve
  >resolve ; immediate      \ resolve loop exit poing in (do)/(?do)

\ ------------------------------------------------------------------------
\ compile an early exit from a do loop

: leave         ( --- )
  compile (leave) ; immediate  \ compile (leave)

\ ------------------------------------------------------------------------
\ compile a conditional early exit from a do loop

: ?leave        ( --- )
  compile (?leave) ; immediate  \ compile (?leave)

\ ------------------------------------------------------------------------
\ added these just for you (bleh :)

: for       ( n1 --- )
  compile dofor
  <mark ; immediate

\ ------------------------------------------------------------------------

: nxt
  compile (nxt)             \ for/nxt loops are more efficient than do
  <resolve ; immediate      \ loops but rep loops are better imho... .. .

\ ------------------------------------------------------------------------
\ compile a rep statement

: ]rep          ( --- )
  compile dorep ;           \ compile a dorep

\ ------------------------------------------------------------------------
\ execute (interpret) a repeat

: 'rep        ( n1 --- )
  '                         \ get cfa of word to be repeated
  (rep) ;                   \ execute this cfa n1 times

\ ------------------------------------------------------------------------
\ execute or compile a rep statement

: rep           ( | n1 --- )
  state                     \ get current compile state
  ?:                        \ if were in compile mode then...
    ]rep                    \   compile a rep statement
    'rep ; immediate        \ else execute it now

\ ========================================================================

