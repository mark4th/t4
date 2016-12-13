\ scrdsp.f      - screen display update
\ ------------------------------------------------------------------------

  .( scrdsp.f )

\ ------------------------------------------------------------------------
\ write all attached windows into screen buffer 1

  <headers

: .windows      ( scr --- )
  dup scr-window@           \ get address of first window in chain
  begin
    ?dup                    \ reached end of chain?
  while
    dup .window             \ no, draw window into screen
    dup .borders
    next@                   \ link to next window in chain
  repeat
  .menus ;                  \ draw menu bar and pulldowns if they exist

\ ------------------------------------------------------------------------
\ this may go away... clears screen to all blanks (white spaces)

  headers>

: scr-clr       ( scr --- )
  dup>r buffer1@
  r> scr-size
  $0720 dfill ;

\ ------------------------------------------------------------------------
\ force a screen to redraw everything on next update

: scr-refresh   ( scr --- )
  dup>r buffer2@            \ get address of buffer 2
  r> scr-size               \ get size of screen in cells
  cells erase ;             \ erase buffer2.

\ ------------------------------------------------------------------------
\ position cursor to correct coordinates unless its already there

  <headers

: scr-at        ( x y --- )
  swap 2dup                 \ need coords in y/x order for at
  #line #out d=             \ is cursor already where we want it?
  ?:
    2drop                   \ if so just discard y/x
    at ;                    \ else reposition cursor

\ ------------------------------------------------------------------------

: (char@)       ( ix buffer --- n1 ) swap []@ ;
: (char!)       ( n1 ix buffer --- ) swap []! ;
: char1@        ( ix scr --- char ) buffer1@ (char@) ;
: char1!        ( ix scr char --- ) -rot buffer1@ (char!) ;
: char2@        ( ix scr --- char ) buffer2@ (char@) ;
: char2!        ( ix scr char --- ) -rot buffer2@ (char!) ;
: attr@         ( ix scr --- attr ) char1@ 8 >> $ffff and ;

\ ------------------------------------------------------------------------
\ return true if character at specified index has been modified

: ?modified     ( index scr --- f1 )
  2dup char1@ -rot          \ fetch char from buffer 1
  char2@ <> ;               \ compare with char from buffer 2

\ ------------------------------------------------------------------------
\ copy contents of buff1 at index to buff2 at index and emit it

: scr-emit      ( ix scr --- )
  2dup char1@               \ fetch char from buff 1, copy to buff 2
  3dup char2!               \ marks char as not modified
  $ff and -rot              \ discard attributes (they are already set)
  scr-width@ /mod           \ covert scr index into scr coordinates
  scr-at                    \ move cursor to that location
  emit incr> #out ;         \ emit character

\ ------------------------------------------------------------------------

\ : (update)
\   r@ ?modified            \ at the current index are buff1 and 2 diff?
\   if
\     dup r@ attr@          \ fetch attrib at current ix
\     pluck =               \ is it the same as the currently set attrib?
\     if                    \ if so, copy buffer1 to buffer2 and
\       dup r@ scr-emit     \ emit character and update buffer 2
\     then
\   then ;

\ ------------------------------------------------------------------------
\ attribs are set, output ALL modified characters that have these attribs

\ : update            ( attrib ix scr --- )
\   >r                        \ move screen out of the way
\   begin                     \ from current index to end of screen...
\     dup (update)
\     1+ dup                  \ increment index
\     r@ scr-size =           \ loop back if index is not at end of screen
\   until
\   r> 3drop ;                \ discard win, index and attrib

: update            ( attrib ix scr --- )
  >r                        \ move screen out of the way
  begin                     \ from current index to end of screen...
    dup r@ ?modified        \ at the current index are buff1 and 2 diff?
    if
      dup r@ attr@          \ fetch attrib at current ix
      pluck =               \ is it the same as the currently set attrib?
      if                    \ if so, copy buffer1 to buffer2 and
        dup r@ scr-emit     \ emit character and update buffer 2
      then
    then
    1+ dup                  \ increment index
    r@ scr-size =           \ loop back if index is not at end of screen
  until
  r> 3drop ;                \ discard win, index and attrib

\ ------------------------------------------------------------------------

: >attribs      ( attribs --- )
  dup $ff and >attrib       \ set fg/bg colors
  8 >> dup >pref            \ set bold, underline etc
  :alt: and
  if >alt else <alt then ;  \ set or clear alt charset

\ ------------------------------------------------------------------------

: (.screen)         ( scr --- )
  >r 0                      \ current index
  begin             ( ix --- )
    dup r@ ?modified        \ if screen buffers at current offset are
    if                      \ different then
      dup r@
      2dup attr@            \ get new attribute
      dup >attribs          \ set attribs
      -rot update           \ update buffer 2 and the display
    then
    1+ dup r@ scr-size =    \ increment index
  until
  r> 2drop ;

\ ------------------------------------------------------------------------
\ update entire screen

  headers>

: .screen       ( scr --- )
  attrib >r                 \ save current terminal attributes
  ['] .$buffer >body @ >r   \ save current string buffer writer
  ['] emit >body @ >r       \ save current character emitter

  ['] noop is .$buffer      \ nothing gets written out to display yet
  ['] c>$ is emit           \ characters are emitted into $buffer

  dup .windows              \ draw all windows into screen buffer

  (.screen)                 \ draw entier screen into $buffer

  r> is emit                \ restore emit
  r> is .$buffer            \ restore .$buffer

  .$buffer                  \ write $buffer out to the display

  r> dup $ff and >attrib    \ restore default attributes etc
  8 >> >pref ;

\ ========================================================================
