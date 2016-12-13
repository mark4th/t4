@ vocabs.s
@ ------------------------------------------------------------------------

@ ------------------------------------------------------------------------
@ the default context stack = the search order

  _variable_ "context0", context0, 0
  .int 0, 0, 0, 0, 0, 0
  .int 0, 0, 0, 0, 0, 0
  .int forth
  .int compiler
  .int root

@ ------------------------------------------------------------------------

  _var_ "voclink", voclink, root
  _var_ "current", current, forth
  _var_ "context", context, context0 + BODY
  _var_ "#context", numcontext, 3

@ ------------------------------------------------------------------------

  _constant_ "#threads", numthreads, 64
  _constant_ "'dovoc", tdovoc, dovoc

@ ------------------------------------------------------------------------
@ return true if voc r8 is in context

find_voc:
  adr r1, context           @ point r1 at context stack
  ldr r1, [r1, #BODY]
  adr r2, numcontext        @ set r3 = context depth
  ldr r3, [r2, #BODY]

  rsb r4, r3, #16           @ set r4 = index to next item on stack
0:
  ldr r5, [r1, r4, lsl #2]
  cmp r5, r8
  it eq
  bxeq lr                   @ return with "eq" condition

  add r4, r4, #1
  subs r3, r3, #1
  bne 0b

  cmp r8, #123              @ return with "ne" condition
  bx lr

@ ------------------------------------------------------------------------
@ run time handler for all vocabularies

@     ( a1 --- )

dovoc:
  mov r8, lr
  sub r8, r8, #9            @ body> (also dethumbificates the address)
  bl find_voc               @ is r8 in context?
  beq 0f

  @ vocabulary is not in context, put it there

  ldr r3, [r2, #BODY]       @ r3 = #context
  add r3, r3, #1            @ increment #context
  str r3, [r2, #BODY]
  rsb r3, r3, #16           @ r3 = index to stuff new into
  str r8, [r1, r3, lsl #2]  @ stuff vocabulary r8 in context
  exit

  @ vocabulary is in context, rotate it out to top

0:
  ldr r3, [r2, #BODY]       @ set r3 = index to top of context stack
  rsb r3, r3, #16

1:
  ldr r9, [r1, r3, lsl #2]
  str r8, [r1, r3, lsl #2]
  movs r8, r9
  cmp r3, r4                @ current index = index to w1 ?
  itt ne
  addne r3, r3, #1
  bne 1b
  exit

@ ------------------------------------------------------------------------
@ return context stack address and index to top item of context stack

@     ( --- a1 n1 )

colon ">context", tocontext
  bl context
  cliteral 16
  bl numcontext
  bl minus
  exit

@ ------------------------------------------------------------------------

colon "definitions", definitions
  bl tocontext
  bl cells_fetch
  bl zstoreto
  bl current
  exit

@ ------------------------------------------------------------------------
@ drop top of context stack

colon "previous", previous
  bl tocontext
  bl cells_plus
  bl off
  bl zdecrto
  bl numcontext
  exit

@ ------------------------------------------------------------------------
@ create the 3 system vocabulary arrays

  _vocab_ "forth",    forth,    forth_link
  _vocab_ "compiler", compiler, comp_link
  _vocab_ "root",     root,     8b

@ ------------------------------------------------------------------------
@ pointer to nfa of last header in system

  .set last_hdr, _thread

@ ========================================================================

