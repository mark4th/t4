\ number.f      - pictured number output words
\ ------------------------------------------------------------------------

  .( loading number.f ) cr

\ ------------------------------------------------------------------------

  0 var hld                 \ points to place to construct number

\ ------------------------------------------------------------------------
\ initiate pictured number construction

: <#            ( --- )
  pad !> hld ;              \ point hold at pad

\ ------------------------------------------------------------------------
\ store one digit/char of number, decrement pointer

: hold      ( c1 --- )
  decr> hld                 \ decrement pointer to pad area
  hld c! ;                  \ store char c1 at address pointed to by hld

\  -------------------------------------------------------------------------
\  hold a '-' if number is negative

: sign          ( n1 --- )
  0< not ?exit
  '-' hold ;

\ ------------------------------------------------------------------------
\ add one digit in current radix to number string

: #         ( d1 --- d2 )
  base mu/mod rot           \ divide number d1 by current radix.
  dup 9 > 7 and +           \ adjust remainder if above 9, add 7
  '0' + hold ;              \ convert to printable character and add it

\ -------------------------------------------------------------------------
\ convert rest of number n1 in current base

: #s            ( d1 --- 0 0 )
  begin
    #                       \ convert next digit
    2dup or 0=              \ anything left to convert ?
  until ;                   \ if so, keep going

\ ------------------------------------------------------------------------
\ complete conversion of number to a string

: #>        ( d1 --- a1 n1 )
  2drop                     \ clean up
  hld pad over - ;          \ return anddress and length of new string

\ ------------------------------------------------------------------------
\ convert a double number to string

: (d.)      ( d1 --- a1 n1 )
  tuck dabs                 \ retain sign, make positive
  <# #s rot sign #> ;       \ convert number, add possible neg sign

\ ------------------------------------------------------------------------
\ display string representation of double number d1 in current radix

: d.        ( d1 --- )
  (d.) type space ;

\ ------------------------------------------------------------------------
\ display right justified number

: d.r       ( d1 n1 --- )
  >r (d.)
  r> over - spaces
  type ;

\ ------------------------------------------------------------------------
\ convert a single to a double ( these dot words work on doubles only )

: .         ( n1 --- )
  s>d d. ;

\ ------------------------------------------------------------------------
\ display right justified single

: .r        ( n1 n2 --- )
  >r s>d r>
  d.r ;

\ ------------------------------------------------------------------------
\ display unsigned single

: u.        ( u1 --- )
  0 d. ;

\ ------------------------------------------------------------------------
\ display right justified unsigned single

: u.r       ( u1 --- )
  0 swap d.r ;

\ ------------------------------------------------------------------------

: radix         ( n1 --- )  !> base ;

\ ------------------------------------------------------------------------
\ forth can use almost any damned base it wants to

: hex           ( --- )  16 radix ;
: decimal       ( --- )  10 radix ;
: binary        ( --- )   2 radix ;
: octal         ( --- )   8 radix ;

\ ========================================================================
