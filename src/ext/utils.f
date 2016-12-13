\ utils.f       - useful things to have arround
\ ------------------------------------------------------------------------

  .( loading utils.f ) cr

\ ------------------------------------------------------------------------
\ some useful words to have around while debugging new code
\ ------------------------------------------------------------------------

  forth definitions

\ -----------------------------------------------------------------------

  0 var idw                 \ max column for output by .id
  0 var idx                 \ line countdown for "more"
  0 var idx0                \ reset value for above
  0 var mkey                \ keypress hit on "more" (may be escape!)

  defer .idcr               \ function to write cr at end of .id line
   ' cr is .idcr

\ -----------------------------------------------------------------------

: ?more
  off> mkey
  decr> idx
  idx 0=
  if
    idx0 !> idx
    cr ." -- MORE --"
    key !> mkey cr cr
  then ;

\ ------------------------------------------------------------------------

: .noname       ( --- )
  ." ??? " ;

\ ------------------------------------------------------------------------

: (.id)
  count lexmask             \ convert address to a1 n1 (mask n1)
  dup 1+ #out +             \ would display of this word take us
  idw >                     \ past max column
  if
    .idcr ?more             \ yes - go to start of next line
  then
  type space ;              \ display this word name

\ ------------------------------------------------------------------------
\ display nfa of word given its cfa

: .id       ( a1 --- )
  >name ?dup
  ?:
    (.id) .noname ;

\ -----------------------------------------------------------------------

\ durning debug session add .self into any word and when that point
\ is executed, the name of the word containing .self will be emitted

: .self
  last name> [compile] literal
  compile .id ; immediate

\ ------------------------------------------------------------------------
\ return true if n1 is equal to either n2 or n3

: either      ( n1 n2 n3 --- f1 )
  -rot over =
  -rot = or ;

\ ------------------------------------------------------------------------
\ return true if n1 is equal to neither n2 or n3

: neither     ( n1 n2 n3 --- f1 )
  -rot over <>
  -rot <> and ;

\ ------------------------------------------------------------------------
\ display top 10 items of parameter stack

: (.s)  ." [top->] " depth 10 min 0 ?do i pick  . loop ." [<-bottom]" cr ;
: (.us) ." [top->] " depth  5 min 0 ?do i pick u. loop ." [<-bottom]" cr ;

  ' (.s)  is .s
  ' (.us) is .us

\ ========================================================================
