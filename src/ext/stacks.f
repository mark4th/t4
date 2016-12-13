\ stacks.f      - software stacks
\ ------------------------------------------------------------------------

  .( loading stacks.f ) cr

\ ------------------------------------------------------------------------

\ a stack is an array where the first two cells are as follows
\
\  cell 0     number of cells allocated to stack
\  cell 1     current stack pointer index (grows down)
\  cekk 2+    stack buffer

\ stacks grow down

\ ------------------------------------------------------------------------

  <headers

: [].size@      ( stack --- size )  0 []@ ;
: [].size!      ( size stack --- )  0 []! ;
: [].sp@        ( stack --- spix )  1 []@ ;
: [].sp!        ( spix stack --- )  1 []! ;
: [].sp--       ( stack --- )       1 [] 0decr ;
: [].sp++       ( stack --- )       1 [] incr ;

\ ------------------------------------------------------------------------

  headers>

: [].flush      ( stack --- )       dup>r [].size@ r> [].sp! ;

\ ------------------------------------------------------------------------
\ create a new stack

: stack:        ( size --- )
  create                    \ create stack
  dup ,                     \ set stack cell count
  dup ,                     \ current sp = bottom of stack
  cells allot ;

\ -----------------------------------------------------------------------
\ push item onto stack

: [].push       ( n1 stack --- )
  dup dup>r                 \ dont eat stack address
  [].sp@ 2+ []!             \ store n1 to indexed cell
  r> [].sp-- ;              \ decrement stack pointer

\ ------------------------------------------------------------------------
\ pop item from stack

: [].pop        ( stack --- n1 )
  dup [].sp++
  dup [].sp@ 2+
  []@ ;

\ -----------------------------------------------------------------------
\ discard top item of stack

: [].drop       ( stack --- f1 ) [].sp++ ;

\ ------------------------------------------------------------------------
\ fetch copy of top item of stack

: [].@          ( stack --- n1 )
  dup [].sp@ 2+
  []@ ;

\ ------------------------------------------------------------------------

  behead

\ ========================================================================
