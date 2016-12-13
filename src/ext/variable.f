\ variable.f    - constant and variable compilation words etc
\ -------------------------------------------------------------------------

  .( loading variable.f ) cr

\ ------------------------------------------------------------------------
\ create a new variable definition

: variable ( --- )
  create 0 , ;

\ -------------------------------------------------------------------------
\ compile new constant into dictionary

: constant      ( n1 --- )
  create , ;uses dovar ;

\ ------------------------------------------------------------------------
\ new definition for variable  - see note below

  ' constant alias var

\ -------------------------------------------------------------------------
\ new definition for constant

: const     ( n1 --- )
  create , immediate        \ create const, compile n1 into its body
  does>                     \ patch cfa of new const to do the following
    @ ?comp# ;              \ compile or return number based on state

\ var and const are my new definitions for variable and constant
\ renamed so as to not cause conflicts with existing code.  you
\ will notice the lack of the definition for 'value' which in my
\ opinion is a very badly named word which like all ans inventions
\ totally fails to describe its function.
\
\ my const definition is state smart.  if you are in compile mode
\ it will compile a literal into the : definition you are compiling.
\ if you are in interpret mode it will return the body field contents
\ as usual
\
\ !> const will work of corse but doing this is heavilly frowned upon
\
\ if you ask me this is the way variable and constant should have
\ worked from day one.

\ ------------------------------------------------------------------------
\ default action for a deferred word

: crash ." Crash!" abort ;

\ ------------------------------------------------------------------------
\ create a deferred word

: defer
  create                    \ create the new dictionary entry
  ;uses dodefer             \ modify its cfa to point to dodefer
  ['] crash , ;             \ set default action for a deferred word

\ ------------------------------------------------------------------------

: defers
  ' >body dup @ ,xt
  last name> swap ! ; immediate

\ ------------------------------------------------------------------------
\ compile xt2 and discard xt1 or discard xt2 and execute xt1 with data

: (!>) ( [ n1 xt1] | xt2 --- )
  state                     \ if we are in compile mode
  if
    nip ,xt                 \ discard xt1, compile xt2
  else
    drop
    >r ' >body              \ get body address of variable to modify
    r> execute              \ execute xt1
  then ;

\ ------------------------------------------------------------------------

: !>     ( | n1 --- )  ['] !    ['] %!>    (!>) ; immediate
: +!>    ( | n1 --- )  ['] +!   ['] %+!>   (!>) ; immediate
: incr>  ( --- )       ['] incr ['] %incr> (!>) ; immediate
: decr>  ( --- )       ['] decr ['] %decr> (!>) ; immediate
: on>    ( --- )       ['] on   ['] %on>   (!>) ; immediate
: off>   ( --- )       ['] off  ['] %off>  (!>) ; immediate

  ' !> alias is             \ for use on deferred words

\ ========================================================================
