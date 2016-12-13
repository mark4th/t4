\ vocabs.f      - extensions to fortgs vocabulary manipulation words
\ ------------------------------------------------------------------------

  .( loading vocabs.f ) cr

\ ------------------------------------------------------------------------

  root definitions

\ ------------------------------------------------------------------------

: vocabulary
  current                   \ save current
  root definitions          \ make root current
  voclink                   \ fetch address of previously defined voc
  head,                     \ create dicionary entry for new vocabulary
  here !> voclink           \ point voclink at cfa of new vocabulary
  $ed04f84c ,               \ rpush lr
  'dovoc ,xt
  here 256 dup allot erase
  ,
  !> current
  reveal ;

\ ------------------------------------------------------------------------
\ saved contexts

  create xstack             \ stack to save contexts to
  16 cells allot

  0 var #x                  \ number of saved contexts

\ -----------------------------------------------------------------------

: only
  context [ 16 cells ]# erase
  ['] root context 15 []!
  1 !> #context ;

\ -----------------------------------------------------------------------

: (.voc)
  >name count lexmask
  type bl emit ;

\ ------------------------------------------------------------------------

: .voc (.voc) cr ;

\ ------------------------------------------------------------------------

: .context
  >context 16 swap
  do
    dup i []@ (.voc)
  loop
  drop cr ;

\ ------------------------------------------------------------------------

: .current
  current .voc ;

\ ------------------------------------------------------------------------

: .vocs
  voclink
  begin
    dup (.voc)
    >body #threads []@
    ?dup 0=
  until
  cr ;

\ -----------------------------------------------------------------------

: (only)    ( a1 --- )
  context [ 16 cells ]# erase
  context 15 []!
  1 !> #context ;

\ ------------------------------------------------------------------------

: only ['] root (only) ;    \ empty context of everything but root voc
: seal  '       (only) ;    \ seal application into specified vocab

\  Only is used to set context back to a sane state.  one would usually
\  do something like only forth compiler blah to make only root, forth
\  compiler and blah vocabs in context.
\
\  seal is used to seal an application into its own vocabulary. this locks
\  the application out of all other vocabularies unless there are words
\  within the sealed vocabulary to give you access to the others.
\  This is primarilly used in applications where you still need the
\  ability to create and compile but you do not want the end user to have
\  full control over the forth environment.

\ ------------------------------------------------------------------------
\ push and pop xstack items

: >x    ( n1 --- )    xstack #x []! incr> #x ;
: x>    ( a1 --- n1 ) decr> #x xstack #x []@ ;

\ ------------------------------------------------------------------------
\ revert back to previous context (pops 3 items off of xstack)

: -context
  #x 0= ?exit               \ no contexts to revert back to?
  x> current !              \ revert to previous current vocabulary
  x> !> #context            \ restore previous context stack depth
  x> !> context ;           \ restore previous context stack address

\ ------------------------------------------------------------------------
\ abort clears the stack of contexts, reverts to original context

: vabort
  #x                        \ if there are any items on this stack
  if
    3 !> #x                 \ then discard all items but last 3 and...
    -context                \ revert to context0
  then                      \ context0 is the default context array
  defers abort ;

\ ------------------------------------------------------------------------
\ create a new private context stck

: context:
  create 64 allot         \ creates a new context stack of 16 cells

  does>
    #x 15 =               \ if you go this deep you need a rethink
    abort" Too Many Saved Contexts"

    \ switching context to private context...

    context 2dup swap     \ make private context a copy of current stack
    64 cmove
             >x           \ save address of previous context stack
    #context >x           \ save depth of previous context stack
    current >x            \ save previous current vocabulary
    !> context ;          \ private context is now THE context

\ ========================================================================
