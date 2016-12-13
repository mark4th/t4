
: \ $a parse 2drop ; immediate

\ ------------------------------------------------------------------------
\ stack comment - ignore everything in input stream till next )

: (
  ')' parse
  2drop ; immediate

\ ------------------------------------------------------------------------
\ ignore but echo everything till next ) in input stream

: .(       ( --- )
  ')' parse
  type ; immediate

\ ------------------------------------------------------------------------
\ could not do this till now

  .( loading comment.f ) cr

\ ------------------------------------------------------------------------
\ ignore whole of rest of file

: \s floads not ?exit abort-fload ;

\ ------------------------------------------------------------------------
\ cant compile this here because the looping words arent included yet

\ : \\s
\  begin
\    floads
\  while
\    abort-fload
\  repeat ;

\ ========================================================================
