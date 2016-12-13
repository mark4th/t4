\ case.f        - case compilation and execution
\ ------------------------------------------------------------------------

  .( loading case.f ) cr

\ ------------------------------------------------------------------------

  compiler definitions

\ ------------------------------------------------------------------------

  <headers

  0 var [dflt]              \ default case vector
  0 var #case               \ number of case options

\ ------------------------------------------------------------------------
\ initiate a case statement

  headers>

: case:        ( --- 0 )
  compile docase            \ compile run time handler for case statement
  align,
  off> [dflt]               \ assume no default vector
  off> #case                \ number of cases is 0 so far
  here 0 ,                  \ case exit point compiled to here
  here 0 ,                  \ default vector filled in by ;case (maybe)
  here 0 ,                  \ number of cases compiled to here
  [compile] [ ; immediate

\ ------------------------------------------------------------------------
\ get default for case: statement

: dflt ( --- )
  ' !> [dflt] ;             \ compiled in later by ;case

\ ------------------------------------------------------------------------

: opt          ( opt --- )
  ,                         \ compile opt
  [compile] ['],            \ get vector and compile it too
  incr> #case ;             \ count number of cases in statement

\ ------------------------------------------------------------------------
\ i resisted the urge to call this word esac :p (phew!!!)

: ;case         ( a1 a2 a3 --- )
  #case swap !
  [dflt] swap !
  here swap ! ] ;

\ ------------------------------------------------------------------------

  behead forth definitions

\ ========================================================================
