@ interpret.s   - the inner interpreter
@ ------------------------------------------------------------------------

@ ------------------------------------------------------------------------

  _defer_ "quit", quit, pquit
  _defer_ "abort", abort, pabort
  _defer_ "(interpret)", pinterpret, pxinterpret
  _defer_ ".status", dotstatus, noop
  _defer_ ".line#", dotl, noop
  _var_ "ok?",     qok, -1

@ ------------------------------------------------------------------------

colon "parse", parse
  bl tor                    @ i did not write these two words but took
  bl source                 @ them from tom zimmers FPC.  He took them
  bl toin                   @ from laxen and perrys F83.
  bl sstring                @ im seriously considering rewriting them
  bl over                   @ because they are very clever with how
  bl swap                   @ they work making them almost completely
  bl rto                    @ unreadable.
  bl scan_word
  bl tor
  bl over
  bl minus
  bl dup
  bl rto
  bl znotequ
  bl minus
  bl zplusstoreto
  bl toin
  exit

@ ------------------------------------------------------------------------

colon "parse-word", parseword
  bl tor
  bl source
  bl tuck
  bl toin
  bl sstring
  bl rfetch
  bl skip
  bl over
  bl swap
  bl rto
  bl scan_word
  bl tor
  bl over
  bl minus
  bl rot
  bl rto
  bl dup
  bl znotequ
  bl plus
  bl minus
  bl zstoreto
  bl toin
  exit

@ ------------------------------------------------------------------------
@ return numer of charcters left to parse out of input buffers

@     ( --- n1 )

colon "left", left
  bl numtib                 @ get total number of characters in tib
  bl toin                   @ get current parse point
  bl minus                  @ compute difference
  exit

@ ------------------------------------------------------------------------
@ refill terminal input buffer if there is nothing left to parse

colon "?refill", qrefill
  bl left                   @ get number of chars left to parse
  bl qexit                  @ if its not zero then exit
  bl refill                 @ otherwise refill tib
  exit

@ ------------------------------------------------------------------------
@ parse next c1 delimited token out of the input buffer

@     ( c1 --- )

colon "word", word_
  bl qrefill                @ first: refill if we have to
  bl parseword              @ parse c1 delimited string from tib
  bl hhere                  @ copy the parsed string to hhere as a counted
  bl strstore               @ string
  exit

@ ------------------------------------------------------------------------
@ search context for next space delimited token from input stream

@     ( --- cfa f1 | false )

colon "defined", defined
  bl bl_                    @ parse next space delimited token out of
  bl word_                  @ the input stream
  bl find                   @ see if a word with this name is defined
  exit                      @ and in context

@ ------------------------------------------------------------------------
@ abort if parsed string is not a known word

@     ( f1 --- )

colon "?missing", qmissing
  bl not                    @ if f1 is false word is defined
  bl qexit                  @ so exit
  bl hhere                  @ otherwise emit the offending string
  bl count
  bl space
  bl type
  bl true                   @ force an unconditional abort
  bl pabortq                @ and display the following string
  hstring " ?"
@ exit

@ ------------------------------------------------------------------------
@ search context for next token from input stream, abort if not found

@     ( --- a1 )

colon "'", tick
  bl defined                @ parse token, search dictionary
  bl not                    @ invert flag indicating success or failure
  bl qmissing               @ abort if parsed string is not a known word
  exit

@ ------------------------------------------------------------------------
@ compile a number or return its value

@       ( n1 --- n1 | )

colon "?comp#", qcompnum
  bl state                  @ if we are currently in interpret mode then
  bl not                    @ return n1
  bl qexit
  bl literal                @ otherwise compile it as a literal
  exit

@ ------------------------------------------------------------------------
@ input not a know word. is it a valid number in current radix?

@       ( --- n1 | )

colon "?#", qnum
  bl hhere                  @ null input is not a number nor an error
  bl cfetch
  bl zequals
  bl qexit
  bl hhere                  @ input is not null, pass string to number
  bl number                 @ ( --- n1 t | f )
  bl not                    @ if number was not found then
  bl qmissing               @ abort
  bl qcompnum               @ otherwise return number or compile it
  exit

@ ------------------------------------------------------------------------
@ input is a known word. compile it or execute it

@       ( xt [ t | 1 ] --- )

colon "?exec", qexec
  bl state                @ if current state is interpret not compile
  bl xor                  @ or if the word is immediate

  bl qcolon
  bl execute              @ then execute the word
  bl commaxt              @ else compile an xt to it
  exit

@ ------------------------------------------------------------------------

@       ( xt [t | 1] | f --- n1 | )

colon "(xinterpret)", pxinterpret
  bl qdup                 @ was the word found?
  bl qcolon
  bl qexec                @ if so execute or compile it
  bl qnum                 @ else see if its a number
  exit

@ ------------------------------------------------------------------------
@ interpret all input till no input left in buffer

colon "interpret", interpret
0:
  bl defined              @ parse space delimited token out, find it
  bl pinterpret           @ interpret or compile it
  bl qstack               @ check stack for under/overflow
  bl left                 @ is there is anything left in the input stream
  bl zequals
  bl qbranch              @ repeat until nothing left
  .hword (0b - .) + 1
  exit

@ ------------------------------------------------------------------------

colon ".ok", dotok
  bl floads                 @ dont display oks if floading
  bl qexit
  bl state                  @ or if in compile mode
  bl not
  bl qok                    @ or if there was an abort
  bl and_
  bl qbranch
  .hword (1f - .) + 1
  bl pdotq
  hstring " ok"
1:
  bl cr_
  bl zonto                  @ clear any previous abort condition
  bl qok
  exit

@ ------------------------------------------------------------------------
@ forths inner interpret loop

colon "(quit)", pquit
  bl lbracket               @ turn compile state off
  bl rp0                    @ reset the return stack
  bl rpstore
  bl sp0                    @ reset the parameter stack
  bl spstore
0:                          @ an infinite loop
  bl dotstatus              @ display status line (an extension)
  bl dotok                  @ display ok (maybe)
  bl interpret              @ interpret next line of imput
  b 0b                      @ only an abort can break out of this

@ ------------------------------------------------------------------------

colon "(abort)", pabort
  bl dotl                   @ kludgy. display line number of abort
0:                          @ break out of all floads
  bl floads                 @ while we are still floading something
  bl qbranch
  .hword (1f - .) + 1
  bl abort_fload            @ abort current file
  bl branch                 @ and repeat
  .hword (0b - .) + 1
1:
  bl zoffto                 @ clear tib
  bl numtib
  bl zoffto                 @ reset interpret index
  bl toin
  bl zoffto                 @ an abort is never ok
  bl qok
  bl quit                   @ jump back into main interpret loop

@ ========================================================================
