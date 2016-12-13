@ expect.s - read in line of code from keyboard
@ ------------------------------------------------------------------------

  _defer_ "expect", expect, pexpect

@ ------------------------------------------------------------------------

  _constant_ "bs", bs_ , 8
  _constant_ "eol", eol, 0xa

@ ------------------------------------------------------------------------

@ does not support any editing of the input line other than deleting
@ characters and retyping them.  this functionality will be added to the
@ as part of the history extension (eventually :)

@ ------------------------------------------------------------------------

@     ( --- )

colon "(bs)", pbs
  bl bs_                    @ backspace over the top of the charactger
  bl emit
  cliteral 2                @ we need to subtract two from #out.  one
  mvn r0, r0                @ for the character we deleted and one because
  bl zplusstoreto           @ the emit of the backspace added 1 to #out
  bl numout                 @ too
  exit

@ ------------------------------------------------------------------------
@ delete one character from buffer and delete it visually too

@     ( count --- )

colon "bsin", bsin
  bl dup                    @ if buffer is empty get out
  bl zequals
  bl qexit
  bl oneminus               @ decrement count
  bl pbs                    @ blot out and char and retreat cursor
  bl space
  bl pbs
  exit

@ ------------------------------------------------------------------------
@ user terminated input...

#     (  max addr count c1 --- max addr max )

colon "crin", crin
  bl drop                   @ discard cr char
  bl duptor
  bl zstoreto               @ make tib count = input count
  bl numtib
  bl over                   @ fake it, we entered max # chars
  bl rto                    @ if input was not empty emit a space
  bl zequals
  bl qexit
  bl space
  exit

@ ------------------------------------------------------------------------
@ user entered a control character. was it a backspace?

@     ( c1 --- )

colon "?bsin", qbsin
  bl bs_                    @ exit if c1 is not a backspace
  bl notequals
  bl qexit
  bl bsin                   @ otherwise process character deletion
  exit

@ ------------------------------------------------------------------------
@ user entered a control char, it was a bs or a cr or we ignore it

@     ( c1 --- )

colon "^char", ctrlchr
  bl dup                    @ is c1 a cr
  cliteral 0x0d
  bl equals
  bl over
  cliteral 0x0a             @ or an lf
  bl equals
  bl or_
  bl qcolon
  bl crin                   @ if so terminate input of string
  bl qbsin                  @ else test for backspace
  exit

@ ------------------------------------------------------------------------
@ user entered a normal character

@     ( addr #in c1 --- addr #in )

colon "norm-char", normchar
  bl threedup               @ make copy of parameters
  bl emit                   @ display the char the user typed
  bl plus                   @ add count to address
  bl cstore                 @ store c1 at this address
  bl oneplus                @ bump count by one
  exit

@ ------------------------------------------------------------------------
@ input max of n1 characters to address a1

@    ( a1 n1 --- )

colon "(expect)", pexpect
  bl swap
  cliteral 0                @ number so far
0:
  bl pluck                  @ max length
  bl over                   @ number so far
  bl minus                  @ not equal while...
  bl qbranch
  .hword (1f - .) + 1

  bl key                    @ input character
  bl dup
  bl bl_                    @ if it is a ctrl char
  bl less
  bl qcolon
  bl ctrlchr                @ handle ctrl chars
  bl normchar               @ else handle normal chars

  bl branch
  .hword (0b - .) + 1

@ note: we simply terminate the input loop if we have recieved the max
@ number of characters. a better way would be to allow input of only
@ a backspace or an enter

1:
  bl threedrop              @ max length reachedd
  exit                      @

@ ------------------------------------------------------------------------
@ expect a max of 256 characters into the terminal input buffer

colon "query", query
  bl tib                    @ address of input buffer
  wliteral 256              @ max nuber of chars to input
  bl expect                 @ input text
  bl zoffto                 @ reset terminal parse point
  bl toin
  exit

@ ========================================================================
