\ history.f     - command line history
\ ------------------------------------------------------------------------

  .( loading history.f ) cr

\ ------------------------------------------------------------------------
\ this can be modified at any time but dont set lower than #history

 1024 var hmax              \ maximum number of history entries
    0 var #history          \ number of entries in history list

\ ------------------------------------------------------------------------

  <headers                  \ everything in here is headerless

 0 var hitem                \ list item for current history entry
 0 var in-expect            \ true if we are wihtin expect

\ ------------------------------------------------------------------------
\ create linked list for histories

  create hlist list allot

\ ------------------------------------------------------------------------
\ allocate memory for one history entry

: halloc        ( n1 --- a1 )
  13 + allocate drop ;      \ +12 for node, +1 for length byte

\ ------------------------------------------------------------------------
\ discard oldest history entry

: hfree         ( --- )
  hlist <tail free drop ;

\ ------------------------------------------------------------------------
\ compare tib of length n1 to all history entries. return address of match

: unique        ( n1 --- n1 a1 t | n1 f )
  #history dup 0= ?exit     \ are there any entries in the history list ?
  drop                      \  if not then exit

  hlist head@               \ get pointer to head of history chain
  begin
    dup>r 12 [c]@ over =    \ get count byte of current list item
    if                      \ if its the same as #tib (n1)
      r@ 13 + tib           \ point to string in list item
      pluck comp 0=         \ compare it with terminal input buffer
      if                    \ if its a match...
        r> true exit        \ return list item address and a true
      then
    then
    r> next@ dup 0=         \ fetch next list item and repeat
  until ;                   \  till done ;)

\ ------------------------------------------------------------------------
\ put supplied list node item at the head of the history chain

: h>head        ( node --- )
  dup !> hitem              \ also make it the current list item
  <list                     \ detach it so we can readd it
  hlist >head ;             \ add node back into list at head

\ ------------------------------------------------------------------------
\ add list history item to list

: (history!)    ( n1 --- n1 )
  #history hmax < not       \ is history list full ?
  if                        \ if so discard oldest history entry
    hfree decr> #history
  then
  dup
  dup halloc dup>r          \ allocate new node
  12 + tuck c! 1+           \ store count byte in node
  tib swap pluck cmove      \ then copy tib into node
  r@ hlist >head            \ set new node as head of list
  r> !> hitem               \ and make it the current list item
  incr> #history ;

\ ------------------------------------------------------------------------

: history!      ( n1 --- n1 )
  dup 0= ?exit              \ did expect receive any characters ?
  unique not                \ is new command line already in histories ?
  if
    (history!)
  else
    h>head                  \ otherwise move duplicate to head of list
  then ;

\ ------------------------------------------------------------------------
\ copy current list item to tib and leave length on stack for expect

: history@      ( --- n1 )
  hitem 12 +                \ get address of count byte
  count tuck tib            \ get count byte and address of tib
  swap cmove  ;             \ copy it over

\ ------------------------------------------------------------------------
\ display data we just copied into tib

: .tib          ( n1 --- )
  tib over type ;

\ ------------------------------------------------------------------------

: backspaces
  #out  min 0
  ?do
    bs emit
    -2 +!> #out
  loop ;

\ ------------------------------------------------------------------------
\ erase the current input line from the display

: clear-in      ( n1 --- )
  ?dup 0= ?exit
  dup backspaces
  dup spaces
  backspaces ;

\ ------------------------------------------------------------------------
\ user pressed cursor up...

: hk-up          ( n1 --- n2 )
  in-expect not ?exit
  #history 0= ?exit         \ if histories are empty then ignore keypress
  clear-in                  \ clear the input from the display

  history@ .tib             \ fetch and display current list item
  hitem next@ ?dup          \ if not at end of chain advance current
  if                        \ list item
    !> hitem
  then ;

\ ------------------------------------------------------------------------
\ user pressed cursor down...

: hk-down        ( n1 --- n2 | 0 )
  in-expect not ?exit
  #history 0= ?exit         \ if histories are empty then ignore keypress
  clear-in                  \ clear the input from the display

  hitem prev@ dup           \ scan back to previous list item
  if                        \ if there is a previous list item then
    !> hitem                \ make it the current list item
    history@ .tib
  then ;                    \ otherwise we have zero chars input to tib

\ ------------------------------------------------------------------------
\ filter out empty lines or lines containing only blanks

: filter        ( n1 --- n1 f1 )
  dup 0= ?dup ?exit         \ blank lines are automatically filtered
  true over
  for
    tib r@ [c]@
    dup bl $0a either
    swap $09 = or
    and
  nxt ;

\ ------------------------------------------------------------------------

: hk-enter      ( n1 --- n1 )
  in-expect not ?exit
  filter ?exit
  history! k-ent ;

\ ------------------------------------------------------------------------
\ wrapper for expect so we know when were running inside it

: hexpect       ( a1 n1 --- )
  on> in-expect
  (expect)
  off> in-expect ;

\ ------------------------------------------------------------------------
\ stubbs

: hk-bs k-bs ;
: hk-left ;
: hk-right ;
: hk-del ;
: hk-home ;
: hk-end ;

\ ------------------------------------------------------------------------
\ initialize command line history handler

: hinit
  defers pdefault
  ['] hexpect  is expect

\ ['] hk-bs    is _key-bs
  ['] hk-down  is _key-down
  ['] hk-up    is _key-up
  ['] hk-enter is _key-ent
  ['] hk-left  is _key-left
  ['] hk-right is _key-right
  ['] hk-del   is _key-del
  ['] hk-home  is _key-home
  ['] hk-end   is _key-end ;

\ ------------------------------------------------------------------------

 behead

\ ========================================================================
