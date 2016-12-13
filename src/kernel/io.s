@ io.s    - basic i/o
@ ------------------------------------------------------------------------

@ ------------------------------------------------------------------------

  _constant_ "rows", rows, 25
  _constant_ "cols", cols, 80
  _constant_ "bl",   bl_,  0x20

@ ------------------------------------------------------------------------

  _defer_ "source", source, psource
  _defer_ "refill", refill, query
  _defer_ "emit", emit, pemit
  _defer_ "type", type, ptype
  _defer_ "key", key, pkey

  _var_ "fdout", fdout, 1

  _var_ "#tib", numtib, 0
  _var_ ">in", toin, 0
  _var_ "#out", numout, 0
  _var_ "#line", numline, 0
  _var_ "tib", tib, 0

@ ------------------------------------------------------------------------
@ return address and filled size of current input buffer

@    ( --- a1 n1 )

colon "(source)", psource
  bl tib                    @ default input source is the terminal
  bl numtib                 @ input buffer. return its address and the
  exit                      @ number of characters it contains

@ ------------------------------------------------------------------------
@ emit character to stdout

@       ( c1 --- )

colon "(emit)", pemit
  bl fdout                  @ file descriptor
  bl spfetch                @ point to data to write
  bl cellplus
  cliteral 1                @ length of data to write
  bl sys_write
  bl twodrop                @ discard return result and character
  bl zincrto
  bl numout                 @ count chars on line
  exit

@ ------------------------------------------------------------------------
@ return true if a keypress is ready to read (key wont block)

@       ( --- f1 )

colon "key?", qkey
  cliteral 0                @ timeout
  cliteral 1                @ number of file descriptors in the following
  push { r0 }               @ address of pollfd structure
  adr r0, 1f
  bl sys_poll               @ poll for key presses
  cliteral 1
  bl equals                 @ return t/f
  exit
1:                          @ an anonymous pollfd structure
  .int 0                    @ file descriptor (stdin)
  .hword 1                  @ requested events = POLLIN
  .hword 0                  @ returned events

@ ------------------------------------------------------------------------

@       ( --- c1 )

colon "(key)", pkey
  cliteral 0                @ push place holder to read into
  cliteral 1                @ number of characters to read
  bl spfetch                @ point at read buffer (the place holder)
  bl cellplus
  cliteral 0                @ file descriptor = stdin
  bl sys_read

  bl qexit                  @ not a very elegant way of handling read
  bl intty                  @ failures
  bl qexit
  bl bye
  exit

@ ------------------------------------------------------------------------

@       ( a1 n1 --- )

colon "(type)", ptype
  bl bounds                 @ ( a2 a1 --- )
  bl pqdo
  .hword (1f - .) + 1
0:
  bl i
  bl cfetch
  bl emit
  bl ploop
  .hword (0b - .) + 1
1:
  exit

@ ------------------------------------------------------------------------

colon "cr", cr_
  bl eol                    @ emit an end of line character
  bl emit
  bl numline                @ get current line number plus 1
  bl oneplus
  bl rows                   @ or total # rows which ever is smaller
  bl min
  bl zstoreto               @ set that as the current line
  bl numline
  bl zoffto                 @ no characters have been emitted to this line
  bl numout
  exit

@ ------------------------------------------------------------------------
@ emit one space

colon "space", space
  bl bl_
  bl emit
  exit

@ ------------------------------------------------------------------------
@ emit n1 spaces

@       ( n1 --- )

colon "spaces", spaces
  bl dorep
  bl space
  exit

@ ------------------------------------------------------------------------
@ type an inline counted string

colon "(.\")", pdotq
  bl rto                    @ get address of inline string
  bl oneminus               @ address is thumbificated
  bl count                  @ ( a1 n1 --- )
  bl twodup                 @ set our return address to the end of
  bl plus                   @ the string (aligned)
  bl align
  bl oneplus                @ thumbificate the return address
  bl tor
  bl type                   @ type the string
  exit

@ ------------------------------------------------------------------------
@ conditionally type an inline abort message

@       ( f1 --- )

colon "(abort\")", pabortq
  bl rto                    @ get address of message
  bl oneminus               @ dethumbificate the address
  bl count                  @ ( a1 n1 --- )
  bl rot                    @ do we abort or no?
  bl qbranch
  .hword (1f - .) + 1

  bl type                   @ yes. type string
  bl cr_
  bl abort                  @ and jump back into top of quit

1:
  bl plus                   @ not aborting. set return address to the
  bl align                  @ end of the string (aligned)
  bl oneplus                @ thumbificate the return address
  bl tor
  exit

@ ------------------------------------------------------------------------
@ return scratch pad address

@       ( --- a1 )

colon "pad", pad
  bl here                   @ forth custom puts the scratchpad at 80
  cliteral 80               @ bytes above 'here'
  bl plus                   @ custom is law!
  exit

@ ------------------------------------------------------------------------
@ add n2 to a1 (advance address), sub n2 from n1 (decrement count by n2)

@       ( a1 n1 n2 --- a2 n3 )

code "/string", sstring
  pop { r1, r2 }
  adds r2, r2, r0
  subs r0, r1, r0
  push { r2 }
  next

@ ========================================================================
