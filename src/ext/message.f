\ message.f       - software message handler
\ ------------------------------------------------------------------------

  .( loading message.f ) cr

\ ------------------------------------------------------------------------

  <headers

\ ------------------------------------------------------------------------
\ messages are allocated from 0 to ff.  any number of handlers can be
\ assigned to any message.  message 0 is usually assined to a sig-winch 
\ but signals are not yet implemented in this arm forth yet... yet!

 0 var messages     	\ array of 256 linked lists of handlers

\ ------------------------------------------------------------------------

: msg-alloc
  defers default
  [ 256 list * ]# allocate
  drop !> messages ;

\ ------------------------------------------------------------------------

struct: msg
  /node: msg.list
  1 dd msg.vector
;struct

\ -----------------------------------------------------------------------
\ allocate handler a1 for message number n1

  headers>

: +msg        ( n1 a1 --- f1 )
  msg allocate 0=
  if
    2drop false exit
  then

  dup>r msg.vector !        \ set address of handler
  list * messages +         \ add node to list of handlers for this
  r> swap >tail             \  message number
  true ;

\ ------------------------------------------------------------------------
\ remove handler a1 for message number n1

: -msg        ( n1 a1 --- f1 )
  swap list * messages +
  head@

  begin
    2dup msg.vector @ <>
  while
    next@
    dup root@ head@ over =
  until
    2drop false
  else
    nip <list drop
    true
  then ;

\ ------------------------------------------------------------------------

: >msg
  list * messages + head@
  ?dup 0= ?exit

  begin
    dup msg.vector @ execute
    next@ ?dup 0=
  until ;

\ ------------------------------------------------------------------------

  behead

\ ========================================================================
