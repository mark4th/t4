@ comma.s
@ ------------------------------------------------------------------------

@ ------------------------------------------------------------------------
@ align dictionary pointer (possibly after compilation of a string)

code "align,", alignc
  adr r1, dp                @ point r1 at dictionary pointer variable
  ldr r2, [r1, #BODY]       @ fetch contents of body of variable
  adds r2, r2, #3           @ align it to cell (4 bytes)
  bic r2, r2, #3
  str r2, [r1, #BODY]       @ store r0 into body of variable
  next

@ ------------------------------------------------------------------------
@ allot n1 bytes of dictionary space

@     ( n1 --- )

code "allot", allot
  adr r1, dp                @ point r1 at dictionary pointer variable
0:                          @ common entry point 1
  ldr r2, [r1, #BODY]       @ fetch contents of body of variable
  adds r2, r2, r0           @ add size to allocate to address
1:                          @ common entry point 2
  str r2, [r1, #BODY]       @ store r2 back in body of variable
  pop { r0 }                @ pop new top of stack
  next

@ ------------------------------------------------------------------------
@ allot n1 bytes of head space

@     ( n1 --- )

code "hallot", hallot
  adr r1, hp                @ point r1 at head space pointer variable
  b 0b                      @ run common code above

@ ------------------------------------------------------------------------
@ compile character c1 into dictionary space

@     ( c1 --- )

code "c,", ccomma
  adr r1, dp                @ point r1 at variable dp
  ldr r2, [r1, #BODY]       @ fetch body of variable dp into r2
  strb r0, [r2], #1         @ store char c1 at address r2, advance r2
  b 1b

@ ------------------------------------------------------------------------
@ compile word (16 bits) w1 into dictionary space

@     ( w1 --- )

code "w,", wcomma
  adr r1, dp                @ point r1 at variable dp
  ldr r2, [r1, #BODY]       @ fetch body of variable dp into r2
  strh r0, [r2], #2         @ store w1 at address r2, advance r2
  b 1b

@ ------------------------------------------------------------------------
@ compile n1 into dictionary space

@     ( n1 --- )

code ",", comma
  adr r1, dp                @ point r1 at variable dp
2:
  ldr r2, [r1, #BODY]       @ fetch body of variable dp into r2
  strh r0, [r2], #2         @ compile lower half of 32 bits to compile
  lsrs r0, #16              @ get upper half
  strh r0, [r2], #2         @ compile that too.
  b 1b                      @ store r2 back into dp = allot space

@ ------------------------------------------------------------------------
@ compile n1 into head space

@     ( n1 --- )

code "h,", hcomma
  adr r1, hp                @ point r1 at variable hp
  b 2b

@ ------------------------------------------------------------------------
@ fetch an inline literal and comma it

@ this is very similar to compile but compile is used to compile execution
@ tokens which in this forth are always bl opcodes.  this does the same
@ thing as compile but does not construct a bl opcode of the item being
@ commad in

@ this and the following word are generally used wtihin the kernel to
@ fetch an opcode that the assembler layed down and compiling it into
@ the definition currently being created.

code "lit,", litc
  push { r0 }               @ save top of stack
  bic lr, #1                @ thumb interworking is a PITA
  ldrh r0, [lr]             @ fetch 32 bits. might not be 32 bit aligned
  ldrh r1, [lr, #2]         @ lr is advanced past literal
  orr r0, r0, r1, lsl #16   @ combine two 16 but fetches
  add lr, lr, #5            @ lr must be odd
  b comma                   @ compile in the literal

@ ------------------------------------------------------------------------
@ as aabove but fetches a 16 bit literal

code "wlit," wlitc
  push { r0 }
  bic lr, #1
  ldrh r0, [lr]
  add lr, lr, #3
  b wcomma

@ ========================================================================
