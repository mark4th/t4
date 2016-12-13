\ header.f      - headerless word creation
\ ------------------------------------------------------------------------

 .( loading header.f ) cr

\ ------------------------------------------------------------------------

\ this extension is used to create headerless words.  this allows you to
\ hide a definition from global scope and helps to keep forths name space
\ clean.
\
\ to start creating headerless words you would use the word <headers which
\ is pronounced "from headers".  to switch back into headerfull mode you
\ would use the word headers> (pronounced headers to).  Each of these
\ words can be though of as an arrow pointing towards those words that
\ have headers.
\
\ e.g.
\
\    <headers    \ turn off headers (points back to previous code)
\
\    : foo .... ;
\    : bar .... ;
\
\    headers>    \ turn headers on. points towards new definitions below
\
\    : bam  10 foo 3 bar ;
\
\ once you have reached the end of your module you would execute the word
\ behead.  this word removes all headers for all words defined as being
\ headerless.  the code for headerless words remains but their headers
\ are gone.

\ ------------------------------------------------------------------------

  vocabulary h-voc compiler definitions

\ ------------------------------------------------------------------------
\ make current headerless state headerless!

  0 var h-current         \ real current vocabulary
  0 var h-hp              \ hp true address
  0 var h-last            \ most recent headerfull word
  0 var beheading?        \ true if beheading disabled
  0 var h-state           \ current headerless state

\ 0 = no headerless words defined
\ 1 = headerless words created, headers are on
\ 2 = headerless words created, headers are off

\ ------------------------------------------------------------------------

\ when creating headerless words we store the temporary headers some
\ distance above the current head space pointer address.  we can now
\ switch between headerless and headerfull mode.  all headerfull word
\ headers are written into head space proper.  all headerless headers are
\ written into the headerless pad area.

\ when we have headerless word headers we can only create a certain amount
\ of headerfull words. if we create too many then we can overflow the
\ gap between headers proper and the temporary headerless header pad area.

  8192 const h-pad        \ hp offset to temp store for headerless headers

\ ------------------------------------------------------------------------

  ' h-voc     >body const 'h-voc
  ' h-hp      >body const 'h-hp
  ' h-last    >body const 'h-last
  ' h-current >body const 'h-current
  ' hp        >body const 'hp
  ' last      >body const 'last

\ ------------------------------------------------------------------------
\ enable or disable going headerless

: +heads      ( h-state ?exit)  off> beheading? ;
: -heads      ( h-state ?exit)  on> beheading? ;

\ ------------------------------------------------------------------------
\ swap pointers to real head space and headerless head space etc

: swap-hp       ( --- )  'h-hp   'hp   juggle ;
: swap-last     ( --- )  'h-last 'last juggle ;

\ ------------------------------------------------------------------------
\ state is not headerless but has been before.  go headerless again

: h1        ( --- )
  swap-last                 \ remember most recent headerfull word
  current !> h-current      \ remember true current
  swap-hp                   \ set hp to headerless space.  save real hp
  2 !> h-state              \ all words are created headerless
  h-voc definitions ;       \ adds h-voc to context and current

\ ------------------------------------------------------------------------
\ going headerless for first time (since last behead)

: h0
  off> h-last               \ no previous headerless words yet
  hhere h-pad + !> h-hp     \ point hp 8k beyond where it realy is
  h1 ;                      \ switch to headerless mode

\ ------------------------------------------------------------------------
\ turn headers off (silently ignores switch from headerless to headerless)

: <headers
  beheading? ?exit          \ dont go headerless if beheading disabled
  h-state
  exec: h0 h1 noop ;

\ ------------------------------------------------------------------------
\ turn headers on (silently ignores switch from headerfull to headerfull)

: headers>      ( --- )
  beheading? ?exit          \ dont go headerfull if beheading disabled
  h-state 2 <> ?exit        \ if were headerless go headerfull

  decr> h-state             \ headers are on again now
  swap-hp swap-last
  h-current !> current ;    \ h-voc is still in context though

\ ------------------------------------------------------------------------
\ beheading...
\ ------------------------------------------------------------------------

\ ------------------------------------------------------------------------
\ zero pointers to nfa at cfa -4 for all words in a headerless thread

: (nonames)     ( thread --- )
  begin                     \ for each header in thread do
    @ ?dup
  while
    dup name>               \ go from nfa to cfa
    cell- off               \ erase pointer to nfa at cfa -4
    n>link                  \ point to previous word in thread chain
  repeat ;

\ ------------------------------------------------------------------------
\ zero pointers to nfa at cfa -4 for all words in the h-voc vocabulary

: nonames
  'h-voc #threads
  for
    dup (nonames)           \ blank out nfa pointer at cfa -4 for thread
    cell+                   \ blank this thread out within h-voc
  nxt
  'h-voc 256 erase
  drop ;

\ ------------------------------------------------------------------------
\ erase all headers - gone forever

: behead
  headers>                  \ turn headers on again
  h-voc previous            \ remove h-voc from context
  off> h-state              \ no longer headerless
  off> h-current
  off> h-hp
  off> h-last
  nonames ;                 \ make all beheaded words noname

\ ------------------------------------------------------------------------
\ allows switching current while headerless

  root definitions

: h-defs
  context                   \ point to last item in context stack
  16 #context -
  []@ !> h-current ;        \ copy that to the saved current

\ ------------------------------------------------------------------------
\ wrap the 'definitions' word to account for headerless modes

: definitions               \ create new definition for this word
  h-state                   \ if we are headerless or have been
  if
    h-defs
  else
    definitions             \ this redefinition references the original
  then ;

\ ------------------------------------------------------------------------

  forth definitions

\ ========================================================================

