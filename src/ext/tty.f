\ tty.f     - terminal initialization
\ ------------------------------------------------------------------------

  .( loading tty.f ) cr

\ ------------------------------------------------------------------------

  <headers

  create intios 15 cells allot   \ 60 bytes in size

\ ------------------------------------------------------------------------

 headers>

  3 $36 syscall <ioctl>

\ ------------------------------------------------------------------------
\ get terminal size (columns and rows)

\ terminal extensions (text ui) need this visible

: get-tsize                 \ terminal size can change on the fly too
  pad $5413 0 <ioctl> drop  \ get window size using ioctl
  pad w@ !> rows            \ update terminal width and height
  pad 1 [w]@ !> cols

  #out cols >
  if
    cols 1- !> #out
  then
  #line rows >
  if
    rows 1- !> #line
  then  ;

\ ------------------------------------------------------------------------

  <headers

: termget       ( --- )  intios $5401 0 <ioctl> drop ;
: termset       ( --- )  intios $5402 0 <ioctl> drop ;

\ ------------------------------------------------------------------------
\ extend needs to call this so terminal does not go screwy on us

  headers>

: (init-term)
  termget                   \ read stdin tios
  [ intios 3 cells + ]#     \ point to c_cflag
  dup @ 2dup                \ fetch c_cflag
  $fffffff4 and swap !      \ set non canonical
  termset                   \
  swap !                    \ restore intios state for atexit
  get-tsize ;               \ initialize cols and rows constants

\ ------------------------------------------------------------------------

  <headers

: init-term     ( --- )
  defers default          \ link into med priority default chain
  (init-term) ;

\ ------------------------------------------------------------------------

: reset-term    ( --- )
  defers atexit
  termset ;

\ ------------------------------------------------------------------------

  behead

\ ========================================================================
