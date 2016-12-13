\ struct.f      - structure defining words
\ ------------------------------------------------------------------------

  .( loading struct.f ) cr

\ ------------------------------------------------------------------------
\ idea stolen fair and square off MrReach - ill call this his code
\ ------------------------------------------------------------------------

  compiler definitions

\ ------------------------------------------------------------------------
\ initilize structure definition

\ this creates a constant but we dont know its value till we finish
\ the structure

: struct:       ( --- a1 0 )
  0 const                   \ create named structure
  here cell-                \ remember body field address
  0 ;                       \ current size of structure

\ ------------------------------------------------------------------------

: enum: struct: ;

\ ------------------------------------------------------------------------

: ;enum swap ! ;

\ ------------------------------------------------------------------------

: := ( n1 --- n2 )    dup const 1+ ;
: /= ( xx n1 --- n2 ) nip := ;

\ ------------------------------------------------------------------------
\ create a named field to index n1 of size n2

: db            ( n1 n2 --- n3 )
  create
  over + swap ,
  does>
    @ + ;

\ ------------------------------------------------------------------------

: dw    2*    db ;
: dd    cells db ;

\ ------------------------------------------------------------------------
\ complete structure definition - backfill struct size constant

: ;struct       ( a1 n1 --- )
  ;enum align, ;

\ ------------------------------------------------------------------------

  forth definitions

\ ========================================================================
