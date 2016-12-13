\ compile.f   - some compilation utils not in the kernel
\ ------------------------------------------------------------------------

  .( loading compile.f ) cr

\ ------------------------------------------------------------------------
\ shorthand for when you do [ ..... ] literal

: ]#    ]  [compile] literal ; immediate
: ],    ]  , ; immediate
: [']   ' [compile] literal ; immediate

\ ------------------------------------------------------------------------

\     ( cfa --- )

: alias
  head,                     \ create a name for the alias
  $40 last cset             \ mark new header as an alias
  \ the above call to head, did two things we now need to undo.  it
  \ alotted dictionary space and it alloted a pointer within the
  \ header it created to point to the new words cfa.  we need to
  \ unalot both of these now

  -4 dup allot hallot       \ remove list:nfa-> and head:cfa->

  dup h,                    \ write passed in cfa into new words header

  \ if the word we are aliasing is immediate then the alias will also be
  \ immediate.  see if the aliased word has a header and check immediate

  \ NOTE: you can create an alias for any word you know the cfa of even
  \ if it does not already have a header

  >name ?dup                \  the word has a name
  if
    c@ $80 and              \  is bit 7 of the first byte of its nfa set?
    if immediate then
  then

  reveal ;

\ ------------------------------------------------------------------------
\ create a handler for a new system call

\     ( #params sys# --- )

: syscall
  create                    \ create a new system call word
  ;uses dosyscall           \ patch its cfa to be a call to do_syscall
  w, w, ;                   \ compile sys # and parameter count

\ ------------------------------------------------------------------------

: does>
  compile ;code             \ compile ;code into new does> word
  $b401 w,                  \ push { r0 }
  $4670 w,                  \ mov r0, lr
  $0001f020 , ; immediate   \ bic r0, #1

\ ------------------------------------------------------------------------
\ compile string into dictionary space


: s,            ( a1 n1 --- )
  here swap                 \ ( a1 here n1 --- )
  dup allot                 \ allot space them move string into it
  cmove ;

\ ------------------------------------------------------------------------
\ compile a " or ' delimited sting with or without aligning the dictionary

: (,")    '"' parse dup c, s, ;
: (,')    ''' parse s, ;
: ,"      (,") align, ;
: ,'      (,') align, ;

\ ------------------------------------------------------------------------
\ compile a conditional abort with error message

: abort"
  compile (abort")
  ," align, ; immediate

\ ------------------------------------------------------------------------
\ compile a string to be printed at run time

: ."
  compile (.")
  ," align, ; immediate

\ ========================================================================
