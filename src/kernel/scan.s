@ scan.s
@ ------------------------------------------------------------------------

@ when you type bl word ... parse-word will scan the next token out of
@ the input buffer up to the specified delimiting character (the blank)
@ but it will also delimit on either a tab or an end of line.  In the case
@ of delimiting on an end of line we have a minor issue we need to deal
@ with..
@
@ if the word we just parsed is the \ line comment word then the next
@ line of the sorce file will be treated as a comment (\ parses to the
@ next eol which in this case is the end of the line immediatly following)

  _constant_ "wchar", wchar, 0

@ ------------------------------------------------------------------------
@ skip leading characters equal to c1 within a string

@     ( a1 n1 c1 --- a2 n2 )

code "skip", skip
  pop { r1, r2 }
  cmp r1, #0                @ zero length?
  beq 1f

0:
  ittt eq
  addeq r2, r2, #1          @ address++
  subseq r1, r1, #1         @ count--
  beq 1f

  ldrb r3, [r2]             @ is next char same as skip char?
  cmp r3, r0
  beq 0b

1:
  push { r2 }               @ addr of first char not equal to skip
  mov r0, r1                @ new length of string
  next

@ ------------------------------------------------------------------------
@ scan string for specified character

@     ( a1 n1 c1 --- a2 n2 )

code "scan", scan
  pop { r1, r2 }
  cmp r1, #0                @ zero length scan?
  beq 1f

0:
  ldrb r3, [r2]             @ compare next char of string to c1
  cmp r3, r0
  ittt ne
  addne r2, r2, #1          @ advance address
  subsne r1, r1, #1         @ length--
  bne 0b

1:
  push { r2 }               @ return address of char (or end of string)
  mov r0, r1                @ number of chars from addr to end of string
  next

@ ------------------------------------------------------------------------

@     ( a1 n1 n2 --- a2 n2 )

@code "dscan", dscan
@  pop { r1, r2 }            @ pop length and address
@  cmp r1, #0                @ zero length scan?
@  beq 1f
@
@0:
@  ldr r3, [r2]              @ compare next cell of data to n2
@  cmp r3, r0
@  itt ne
@  addne r2, r2, #4          @ advance address
@  subsne r1, r1, #1         @ length--
@  bne 0b
@
@1:
@  push { r2 }               @ address of found item (or end)
@  mov r0, r1                @ number of cells from addr to end of string
@  next

@ ------------------------------------------------------------------------

@     ( a1 n1 c1 --- a2 n2 )

code "scan-word", scan_word
  pop { r1, r2 }
  cmp r1, #0
  beq 2f

0:
  ldrb r3, [r2]
  cmp r3, r0
  beq 2f

  cmp r0, #0x20           @ if we are scanning for blanks then include
  it eq
  cmpeq r3, #0x09         @ the evil tab
  beq 2f
  adds r2, r2, #1
  subs r1, r1, #1
  bne 0b
  mov r3, r1              @ we did not delimit, we ran out of string

2:
  push { r2 }

  adr r2, wchar
  str r3, [r2, #BODY]
  mov r0, r1
  next

@ ========================================================================
