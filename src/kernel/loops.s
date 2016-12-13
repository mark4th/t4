@ loops.s
@ ------------------------------------------------------------------------

@ ------------------------------------------------------------------------

@     ( n1 --- )

code "docase", docase
  bic lr, #1

  add lr, lr, #3            @ following items are cell alligned for
  bic lr, lr, #3            @  ease of fetching them

  ldr r7, [lr], #4          @ case exit point
  ldr r6, [lr], #4          @ default vector
  ldr r5, [lr], #4          @ case count

0:
  ldr r1, [lr], #4          @ get case option
  cmp r0, r1                @ same as n1?
  itee ne
  ldrne r1, [lr], #4
  ldreq r6, [lr], #4
  beq 1f
  subs r5, r5, #1
  bne 0b

  @ n1 is not an option, take default if there is one

  cbz r6, 2f                @ do we have a default vector?
1:
  pop { r0 }
  add lr, r7, #1            @ set lr = case exit point
  adds r6, r6, #1
  bx r6

2:
  pop { r0 }                @ branch to case exit point
  bx r7

@ ------------------------------------------------------------------------
@ get target address from bl opcode

@       65              4  32               register
@ .... .SII IIII IIII ..J. Jiii iiii iiii   opcode
@ .... .... SJJI IIII IIII Iiii iiii iiii   address / 2

@ r0 = bl opcode on entry
@ r1 = address of bl opcode

@ r2 = offset to bl target on exit

@ does not alter r0 or r1

code "<bl", from_bl
  mov r2, r0                @ R2 = I11

  ubfx r3, r0, #11, #1      @ R3 = J2
  ubfx r4, r0, #13, #1      @ R4 = J1
  ubfx r5, r0, #16, #10     @ R5 = I10
  ubfx r6, r0, #26, #1      @ R6 = S

  eors r3, r3, r6           @ J2 = !(J2 ^ S)
  eors r4, r4, r6           @ J1 = !(J1 ^ S)
  mvns r3, r3
  mvns r4, r4

  bfi r2, r5, #11, #10      @ add I10 to result
  bfi r2, r3, #21, #1       @ add J2  to result
  bfi r2, r4, #22, #1       @ add J1  to result
  bfi r2, r6, #23, #1

  lsls r2, #8               @ propogate sign bit and
  asrs r2, #7               @ multiply result by 2

  @ return offset from bl opcode to its target address

  bx lr

@ ------------------------------------------------------------------------
@ execute one or other of next two xts

@     ( n1 --- )

code "?:", qcolon
  mov r1, lr                @ advance return address past true/false
  add lr, lr, #8            @ vectors, point r1 at true vector
  bic r1, #1
  cmp r0, #0                @ is n1 false?

  it eq
  addeq r1, r1, #4          @ if so, point r0 at false vector

  ldrh r2, [r1]             @ get xt to execute (actually a bl to it)
  ldrh r3, [r1, #2]
  add r0, r3, r2, lsl #16   @ r0 = full 32 bit bl opcode

  push { lr }
  bl from_bl                @ extract address
  pop { lr }

  add r2, r2, r1
  adds r2, r2, #5           @ 4 for pipe, 1 for thumb

  pop { r0 }
  bx r2

@ ------------------------------------------------------------------------
@ executte n1th xt after exec:. this is an implied exit

@ like ?: this word is somewhat inefficient in thumb2 due to the ammount
@ of work it has to do just to calculate the target address of the bl
@ opcode selected

@     ( n1 --- )

code "exec:", execc
  bic lr, #1
  add r0, lr, r0, lsl #2    @ point r1 at xt to execute
  bl xtfetch                @ get target address of chosen xt
  rpop lr                   @ exec: is an implied unnest
  movs r1, r0
  pop { r0 }
  bx r1

@ ------------------------------------------------------------------------

code "branch", branch
  bic lr, #1                @ clear odd bit from lr
  ldrh r1, [lr]             @ lr points to branch vector
  sxtah lr, lr, r1
  next

@ ------------------------------------------------------------------------

code "?branch", qbranch
  cmp r0, #0
  pop { r0 }
  beq branch
  add lr, lr, #2
  next

@ ------------------------------------------------------------------------

code "undo", undo
  add rp, rp, #12
  next

@ ------------------------------------------------------------------------

code "(leave)", pleave
  add rp, rp, #8
  exit

@ -----------------------------------------------------------------------

code "(?leave)", pqleave
  cmp r0, #0
  pop { r0 }
  itt ne
  addne rp, rp, #8
  ldmfdne rp!, { pc }
  next

@ ------------------------------------------------------------------------

code "(loop)", ploop
  ldr r1, [rp]              @ increment loop index
  adds r1, r1, #1
  bvs 2f                    @ exit loop on overflow
1:
  str r1, [rp]              @ else store back new loop index
  bic lr, #1                @ and branch back to start of loop
  ldrh r1, [lr]             @ lr points to branch vector
  sxtah lr, lr, r1
  next

@ ------------------------------------------------------------------------

@     ( n1 --- )

code "(+loop)", pploop
  ldr r1, [rp]              @ add n1 to loop index
  adds r1, r1, r0
  pop { r0 }                @ pop new top of stack
  bvc 1b                    @ branch back to start of loop if no overflow
2:
  add rp, rp, #8            @ else clean loop parameters off stack
  exit                      @ and branch to loop exit point

@ ------------------------------------------------------------------------

code "(do)", pdo
  pop { r1 }                @ r0 = start index, r1 = end index
_do:
  bic lr, #1
  ldrh r2, [lr]             @ fetch compiled in loop exit point
  sxth r2, r2               @ sign extend 16 bit relative branch vector
  add r2, r2, lr
  add lr, lr, #3
  rpush r2                  @ push it to the return stack
  add r1, r1, #0x80000000   @ fudge loop indicies
  subs r0, r0, r1
  rpush r1
  rpush r0
  pop { r0 }
  next

@ ------------------------------------------------------------------------

@     ( n1 n2 --- )

code "(?do)", pqdo
  pop { r1 }
  cmp r0, r1
  bne _do
  pop { r0 }

  bic lr, #1
  ldrh r1, [lr]             @ lr points to branch vector
  sxtah lr, lr, r1
  next

@ ------------------------------------------------------------------------

code "i", i
  movs r2, #0
ijk:
  push { r0 }
  add r2, rp
  ldr r0, [r2], #4
  ldr r2, [r2]
  add r0, r2
  next

@ ------------------------------------------------------------------------

code "j", j
  movs r2, #12
  b ijk

@ ------------------------------------------------------------------------

code "k", k
  movs r2, #24
  b ijk

@ ------------------------------------------------------------------------

@     ( n1 --- )

code "dofor", dofor
  subs r0, r0, #1           @ zero base n1
  bpl 0f
  pop { r0 }                @ if n1 went negative branch to end of loop
  b branch
0:
  rpush r0                  @ else put loop count on r stack
  pop { r0 }
  next

@ ------------------------------------------------------------------------

code "(nxt)", pnxt
  ldr r1, [rp]              @ get loop count
  subs r1, r1, #1           @ decrement it
  bmi 1f                    @ if it did not go negative
  str r1, [rp]              @ store it back
  b branch
1:
  add rp, rp, #4            @ loops completed. discard loop count
  add lr, lr, #2            @ advance lr past branch vector
  next

@ ------------------------------------------------------------------------
@ execute a repeat statement (repeats code at specified cfa n1 times)

@     ( ... n1 cfa --- )

colon "(rep)", prep
  bl swap                   @ ( ... cfa n1 --- ) get repeat count n1
  bl dofor                  @ for n1 itterations do...
  .hword (2f - .) + 1       @ exit vector if n1 is zero
1:
  bl duptor                 @ keep copy of cfa to be repeatedly called
  bl execute                @ call specified cfa
  bl rto                    @ get copy of cfa back
  bl pnxt                   @ repeat till n1 goes negative
  .hword (1b - .) + 1
2:
  bl drop                   @ discard cfa, were done with it now
  exit

@ ------------------------------------------------------------------------
@ execute a compiled rep statement

@      ( n1 --- )

colon "dorep", dorep
  bl pcompile               @ disassemble xt of word to repeat
  bic r0, #1                @ dethumbificate the address
  bl prep                   @ execute this word n1 times
  exit

@ ------------------------------------------------------------------------
@ convert address and length to start and end addresses

@    ( a1 n1 --- a1 a2 )

code "bounds", bounds
  pop { r1 }
  add r0, r0, r1
  push { r0 }
  mov r0, r1
  next

@ ========================================================================
