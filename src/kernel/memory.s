@ memory.s
@ ------------------------------------------------------------------------

@ ------------------------------------------------------------------------

  _constant_ "cell", cell, 4

@ ------------------------------------------------------------------------

  _alias_ "cell+", fourplus,  cellplus
  _alias_ "cell-", fourminus, cellminus
  _alias_ "cells", fourstar,  cells

@ ------------------------------------------------------------------------

code "cell/", cellslash
  lsrs r0, #2
  next

@ ------------------------------------------------------------------------
@ compute address of cell indexed into array

@     ( array index --- a1 )

code "[]", cells_plus
  pop { r1 }
  add r0, r1, r0, lsl #2
  next

@ ------------------------------------------------------------------------

code "[w]", wplus
  pop { r1 }
  add r0, r1, r0, lsl #1
  next

@ ------------------------------------------------------------------------
@ fetch indexed cell of specified array

@     ( array index --- n1 )

code "[]@", cells_fetch
  pop { r1 }
  add r1, r1, r0, lsl #2
  ldrh r0, [r1]
  ldrh r1, [r1, #2]
  add r0, r0, r1, lsl #16
  next

@ ------------------------------------------------------------------------
@ store data at indexed cell of array

@     ( n1 array index --- )

code "[]!", cells_store
  pop { r1, r2, r3 }
  add r1, r1, r0, lsl #2
  strh r2, [r1]
  lsrs r2, #16
  strh r2, [r1, #2]
  mov r0, r3
  next

@ ------------------------------------------------------------------------

@     ( array index --- w1 )

code "[w]@", wxfetch
  pop { r1 }
  ldrh r0, [r1, r0, lsl #1]
  next

@ ------------------------------------------------------------------------

@   ( w1 array index --- )

code "[w]!", wxstore
  pop { r1, r2, r3 }
  strh r2, [r1, r0, lsl #1]
  mov r0, r3
  next

@ ------------------------------------------------------------------------

code "[c]@", cxfetch
  pop { r1 }
  ldrb r0, [r0, r1]
  next

@ ------------------------------------------------------------------------

code "[c]!", cxstore
  pop { r1, r2, r3 }
  strb r2, [r0, r1]
  mov r0, r3
  next

@ ------------------------------------------------------------------------
@ part of the memory manager extension

@ returns contents of specified address then increments contents for
@ next read ... dup @ swap incr

@     ( a1 --- n1 )

code "@^", fetch_up
  ldr r1, [r0]                  @ r1 = variable contents
  adds r3, r1, #1               @ r1 = var + 1
  str r3, [r0]                  @ var = var + 1
  mov r0, r1                    @ return unincremented value of var
  next

@ ------------------------------------------------------------------------

@     ( a1 --- n1 )

code "@", fetch
  ldrh r1, [r0]
  ldrh r0, [r0, #2]
  add r0, r1, r0, lsl #16
  next

@ ------------------------------------------------------------------------

@     ( n1 a1 --- )

code "!", store
  pop { r1, r2 }
  strh r1, [r0]
  lsrs r1, #16
  strh r1, [r0, #2]
  movs r0, r2
  next

@ ------------------------------------------------------------------------

@     ( a1 --- c1 )

code "c@", cfetch
  ldrb r0, [r0]
  next

@ ------------------------------------------------------------------------

@     ( c1 a1 --- )

code "c!", cstore
  pop { r1, r2 }
  strb r1, [r0]
  mov r0, r2
  next

@ ------------------------------------------------------------------------

@     ( a1 --- w1 )

code "w@", wfetch
  ldrh r0, [r0]
  next

@ ------------------------------------------------------------------------

@     ( w1 a1 --- )

code "w!", wstore
  pop { r1, r2 }
  strh r1, [r0]
  mov r0, r2
  next

@ ------------------------------------------------------------------------

@       ( n1 --- )

code "\%!>", zstoreto
  bic lr, #1
  mov r8, r0                @ save n1
  mov r9, lr                @ save lr
  mov r0, lr                @ xt@ needs r0 = address of bl opcode
  bl xtfetch
  str r8, [r0, #BODY - 1]   @ store n1 in body of xt target
  pop { r0 }
  add lr, r9, #5            @ advance lr past xt
  next

@ ------------------------------------------------------------------------

@       ( n1 --- )

code "\%+!>", zplusstoreto
  bic lr, #1                @ de-thumbficate lr adedress
  mov r8, r0                @ save n1
  mov r9, lr                @ save link address
  mov r0, lr                @ xt@ wants opcode address in r0
  bl xtfetch                @ calculate target address of bl opcode at r0
  ldr r1, [r0, #BODY - 1]   @ fetch contents of variable body
  add r1, r1, r8            @ add n1
  str r1, [r0, #BODY - 1]   @ store result back in variable bodu
  pop { r0 }                @ pop new top of stack
  add lr, r9, #5            @ advance lr past item we updated
  next

@ ------------------------------------------------------------------------

@       ( --- )

code "\%incr>", zincrto
  bic lr, #1
  mov r8, r0
  mov r9, lr
  mov r0, lr
  bl xtfetch
  ldr r1, [r0, #BODY - 1]
  adds r1, r1, #1
  str r1, [r0, #BODY - 1]
  mov r0, r8
  add lr, r9, #5
  next

@ ------------------------------------------------------------------------

@       ( --- )

code "\%decr>", zdecrto
  bic lr, #1
  mov r8, r0
  mov r9, lr
  mov r0, lr
  bl xtfetch
  ldr r1, [r0, #BODY - 1]
  subs r1, r1, #1
  str r1, [r0, #BODY - 1]
  mov r0, r8
  add lr, r9, #5
  next

@ ------------------------------------------------------------------------

@       ( --- )

code "\%on>", zonto
  bic lr, #1
  mov r8, r0
  mov r9, lr
  mov r0, lr
  bl xtfetch
  mvn r1, #0
  str r1, [r0, #BODY - 1]
  mov r0, r8
  add lr, r9, #5
  next

@ ------------------------------------------------------------------------

@       ( --- )

code "\%off>", zoffto
  bic lr, #1
  mov r8, r0
  mov r9, lr
  mov r0, lr
  bl xtfetch
  movs r1, #0
  str r1, [r0, #BODY - 1]
  mov r0, r8
  add lr, r9, #5
  next

@ ------------------------------------------------------------------------
@ convert a counted string to an address and count

@     ( a1 --- a2 c1 )

code "count", count
  mov r1, r0
  ldrb r0, [r1], #1
  push { r1 }
  next

@@ ------------------------------------------------------------------------

@@     ( a1 --- a2 w1 )

@code "wcount", wfetch_plus
@  mov r1, r0
@  ldrh r0, [r1], #2
@  push { r1 }
@  next

@ ------------------------------------------------------------------------

@     ( a1 --- a2 n1 )

code "dcount", fetch_plus
  mov r1, r0
  ldrh r0, [r1]
  ldrh r2, [r1, #2]
  adds r1, #4
  add r0, r0, r2, lsl #16
  push { r1 }
  next

@ ------------------------------------------------------------------------
@ move cell from address a1 to address a2

@     ( a1 a2 --- )

@code "dmove", dmove
@  pop { r1, r2 }
@  ldr r1, [r1]
@  str r1, [r0]
@  mov r0, r2
@  next

@ ------------------------------------------------------------------------
@ swap contents of two memory cells

@ note: requires aligned addresses

@     ( a1 a2 --- )

code "juggle", juggle
  pop { r1 }
  ldr r2, [r0]
  ldr r3, [r1]
  str r2, [r1]
  str r3, [r0]
  pop { r0 }
  next

@ ------------------------------------------------------------------------
@ get length of asciiz string

@     ( a1 --- a2 n1 )

code "strlen", strlen
  movs r1, #0
0:
  ldrb r2, [r0, r1]
  cmp r2, #0
  it ne
  addne r1, r1, #1
  bne 0b
  push { r0 }
  mov r0, r1
  next

  mvn r1, #0
0:
  adds r1, r1, #1
  ldrb r2, [r0, r1]
  cmp r2, #0
  bne 0b
  push { r0 }
  mov r0, r1
  next

@ ------------------------------------------------------------------------
@ set bits of data at specified address

@     ( n1 a1 --- )

code "cset", cset
  pop { r1, r2 }
  ldr r3, [r0]
  orrs r3, r3, r1
  str r3, [r0]
  mov r0, r2
  next

@ ------------------------------------------------------------------------
@ clear bits of data at specified address

@     ( n1 a1 --- )

@ code "cclr", cclr
@   pop { r1, r2 }
@   mvns r1, r1
@   ldr r3, [r0]
@   ands r3, r3, r1
@   str r3, [r0]
@   mov r0, r2
@   next

@ ------------------------------------------------------------------------
@ set data at address to true

@     ( a1 --- )

code "on", on
  mvn r1, #0
  strh r1, [r0]
  strh r1, [r0, #2]
  pop { r0 }
  next

@ ------------------------------------------------------------------------
@ set data at address to false

@     ( a1 --- )

code "off", off
  movs r1, #0
  strh r1, [r0]
  strh r1, [r0, #2]
  pop { r0 }
  next

@ ------------------------------------------------------------------------
@ increment data at specified address

@     ( a1 --- )

code "incr", incr
  ldrh r1, [r0]
  ldrh r2, [r0, #2]
  add r1, r1, r2, lsl #16
  adds r1, r1, #1
  strh r1, [r0]
  lsrs r1, #16
  strh r1, [r0, #2]
  pop { r0 }
  next

@ ------------------------------------------------------------------------
@ decrement data at specified address

@     ( a1 --- )

code "decr", decr
  ldrh r1, [r0]
  ldrh r2, [r0, #2]
  add r1, r1, r2, lsl #16
1:
  subs r1, r1, #1
  strh r1, [r0]
  lsrs r1, #16
  strh r1, [r0, #2]
  pop { r0 }
  next

@ ------------------------------------------------------------------------
@ decrement data at specified address but dont decrement below zero

@     ( a1 --- )

code "0decr", zdecr
  ldrh r1, [r0]
  ldrh r2, [r0, #2]
  add r1, r1, r2, lsl #16
  cmp r1, #0
  bne 1b
  pop { r0 }
  next

@ ------------------------------------------------------------------------
@ add n1 to data at a1

@     ( n1 a1 --- )

code "+!", plusstore
  pop { r1, r2 }
  ldrh r3, [r0]
  ldrh r4, [r0, #2]
  add r3, r3, r4, lsl #16
  add r1, r1, r3
  strh r1, [r0]
  lsrs r1, #16
  strh r1, [r0, #2]
  mov r0, r2
  next

@ ------------------------------------------------------------------------
@ copy bytes from src to dest for specified length

@     ( src dst len --- )

code "cmove", cmove
  pop { r1, r2, r3 }
  cmp r0, #0                @ zero length move?
  beq 2f

1:
  ldrb r4, [r2], #1
  strb r4, [r1], #1
  subs r0, r0, #1
  bne 1b

2:
  mov r0, r3                @ put new top of stack item in r0
  next

@ ------------------------------------------------------------------------
@ cmove data from src to dst starting from the end of the buffers

@     ( src dst len --- )

code "cmove>", cmoveto
  pop { r1, r2, r3 }
  cmp r0, #0                @ zero length move?
  beq 2f

  subs r0, r0, #1           @ point src and dst at end of data
  adds r2, r2, r0
  adds r1, r1, r0

1:
  ldrb r4, [r2], #-1        @ copy one byte
  strb r4, [r1], #-1
  subs r0, r0, #1           @ count down till we go negative
  bpl 1b                    @ i.e. we DO want to copy the 0th byte

2:
  mov r0, r3                @ put new top of stack item in r0
  next

@ ------------------------------------------------------------------------
@ fill buffer with specified data

@   ( a1 n1 c1 --- )

code "fill", fill
  pop { r1, r2, r3 }

_fill1:
  add r1, r1, r2            @ point r1 beyond end of data
0:
  cmp r2, r1                @ does r2 point beyond end of data?
  itt ne
  strbne r0, [r2], #1       @ if not store next byte
  bne 0b                    @ and repeat
  mov r0, r3
  next

@ ------------------------------------------------------------------------
@ fill buffer with spaces

@     ( a1 n1 --- )

@ code "blank", blank
@   pop { r2, r3 }
@   mov r1, r0
@   movs r0, #0x20
@   b _fill1

@ ------------------------------------------------------------------------
@ fill buffer with zeros

@     ( a1 n1 --- )

code "erase", erase
  pop { r2, r3 }
  mov r1, r0
  movs r0, #0
  b _fill1

@ ------------------------------------------------------------------------

@     ( a1 n1 n2 --- )

code "dfill", dfill
  pop { r1, r2, r3 }
  movs r1, r1, lsl #2
  add r1, r1, r2

0:
  cmp r2, r1
  it ne
  strne r0, [r2], #4
  bne 0b
  mov r0, r3
  next

@ ------------------------------------------------------------------------
@ ascii uppercase translation table

atbl:
 .byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
 .byte 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
 .byte 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17
 .byte 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f
 .byte 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27
 .byte 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f
 .byte 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37
 .byte 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f
 .byte 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47
 .byte 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f
 .byte 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57
 .byte 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f
 .byte 0x60, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47
 .byte 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f
 .byte 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57
 .byte 0x58, 0x59, 0x5a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f

@ ------------------------------------------------------------------------
@ upper case a character

@     ( c1 --- c2 )

code "upc", upc
  and r0, r0, #0x7f
  adr r1, atbl
  ldrb r0, [r1, r0]
  next

@ ------------------------------------------------------------------------
@ compare strings of specified length

@     ( a1 a2 n1 --- f1 )

code "comp", comp
  pop { r1, r2 }
  cmp r0, #0                @ zero length data
  beq 1f
0:
  ldrb r4, [r1]             @ fetch one char from src and dst
  ldrb r5, [r2]
  cmp r4, r5                @ compare them
  bne 1f                    @ if not same then exit from this loop
  adds r1, r1, #1
  adds r2, r2, #1
  subs r0, r0, #1           @ count length down by 1
  bne 0b                    @ loop till done
  next                      @ return 0 == strings the same

1:
  ite gt
  movgt r0, #1
  mvnle r0, #0
  next

@ ------------------------------------------------------------------------
@ store zero char at end of string

@ this is useful when passing strings to system calls.

@     ( a1 n1 --- a1 )

code "s>z", s2z
  mov r1, r0                @ set r0 = address, r1 = length
  pop { r0 }
  adds r2, r0, r1           @ point r2 at end of string
  movs r3, #0               @ store zero byte at end of string
  strb r3, [r2]
  next

@ ------------------------------------------------------------------------

@    ( a1 n1 a2 --- )

colon "$!", strstore
  bl twodup
  bl cstore
  bl oneplus
  bl swap
  bl cmove
  exit

@ ------------------------------------------------------------------------
@ append a counted string to end of another (assumes space)

@     ( a1 n1 a2 --- )

colon "$+", strplus
  bl duptor
  bl count
  bl duptor
  bl plus
  bl drot
  bl tor
  bl swap
  bl rfetch
  bl cmove
  bl tworto
  bl plus
  bl rto
  bl cstore
  exit

@ ========================================================================
