@ reloc.s     - relocate word headers (on load and fsave)
@ ------------------------------------------------------------------------

@ when forth loads the memory map looks like the following

@ +------+------+-------------+
@ | list | head | empty space |
@ +------+------+-------------+
@
@ but we need it to look like this
@
@ +------+-------+------+-------+
@ | list | empty | head | empty |
@ +------+-------+------+-------+
@
@ so we can append new code to list space and new headers to head space
@ when we save out the kernel we need to relocate everything back to the
@ compacted map state.

@ ------------------------------------------------------------------------

@ r5  = source
@ r6  = destination
@ r7  = address of last header
@ r8  = header we just relocated
@ r9  = location header was moved to

@ ------------------------------------------------------------------------

@ we just relocated a header.  if the relocated headers original address
@ is pointed to by a thread of any vocabulary then we need to adjust
@ that thread pointer within the vocabulary to reflect the new address of
@ the header

rethread:
  adr r2, voclink           @ point r2 at list of vocabularies
  ldr r2, [r2, #BODY]
0:
  adds r2, r2, #BODY
  movs r3, #64              @ threads per vocabulary
1:
  ldr r4, [r2]              @ compare each thread of vocabulary with
  cmp r4, r8                @ source address of header we just relocated
  it eq
  streq r9, [r2]            @ if equal, set thread pointing to destination
  beq 2f                    @ and break out of loop
  adds r2, r2, #4           @ else point to next thread in vocab
  subs r3, r3, #1           @ and loop till all 64 threads are checked
  bne 1b
  ldr r2, [r2]              @ reached end of vocab, point to next vocab
  cmp r2, #0                @ in chain and loop if not at end of chain
  bne 0b
2:
  bx lr

@ ------------------------------------------------------------------------
@ relocate one header

@   r5 = source
@   r6 = destination
@   r9 = nfa of destination

@ returns
@   r8 = address of next header to relocate

hreloc:
  ldr r1, [r5]              @ look in lfa of header to relocate
  cmp r1, #0                @ is there a previous header in the chain?
  it ne
  ldrne r1, [r1, #-4]       @ yes. fetch the relocated address of prev hdr

  str r1, [r6], #4          @ write new lfa to destination header
  str r6, [r5], #4          @ save relocated address of current header

  mov r8, r5                @ used by caller to check for reloc complete
  mov r9, r6                @ save dst nfa address (used below)

  ldrb r1, [r5]             @ get nfa count byte
  mov r3, r1                @ make copy of lex bits
  and r1, r1, #LEXMASK      @ and mask them out of the length counter
  adds r1, r1, #1           @ make length include length byte

1:                          @ relocate headers nfa
  ldrb r2, [r5], #1
  strb r2, [r6], #1
  subs r1, r1, #1
  bne 1b

  adds r5, r5, #3            @ align src and dst to the cell
  bic r5, r5, #3
  adds r6, r6, #3
  bic r6, r6, #3

  ldr r1, [r5], #4          @ relocate headers CFA pointer
  str r1, [r6], #4
  ands r3, #0x40            @ test lex bits saved above. is this an alias?
  it eq
  streq r9, [r1, #-4]       @ if not an alias, adjust NFA pointer at CFA-4
  bx lr                     @ to point to the relocated NFA

@ ------------------------------------------------------------------------
@ relocate all headers

relocate:
  push { lr }
0:
  bl hreloc                 @ relocate one header
  bl rethread               @ adjust vocab thread need be
  cmp r8, r7                @ did we just relocate the LAST header?
  bne 0b                    @ loop till done blah blah
  pop { pc }

@ ------------------------------------------------------------------------
@ special verison of unpack for kernel

kunpack:
  rpush lr
  movw r5, #:lower16:unpack
  movt r5, #:upper16:unpack
  adr r6, eunpack
  str r6, [r5, #BODY]

  adr r5, dp               @ point to source data
  ldr r5, [r5, #BODY]
  movw r6, #:lower16:bhead @ point to destination address
  movt r6, #:upper16:bhead
  ldr r6, [r6, #BODY]
  adr r7, last             @ point to last header
  ldr r7, [r7, #BODY]

  bl relocate               @ relocate all headers

  adr r1, hp               @ set address of hhere
  str r6, [r1, #BODY]
  adr r1, last
  str r9, [r1, #BODY]
  exit

@ ------------------------------------------------------------------------
@ version of unpack used on extended kernel

eunpack:
  rpush lr
  movw r5, #:lower16:turnkeyd @ turnkeyd apps have no headers to relocate
  movt r5, #:upper16:turnkeyd
  ldr r5, [r5, #BODY]
  cmp r5, #0
  it ne
  ldmfdne rp!, { pc }

  adr r5, dp                @ point r5 to where headers got relocated to
  ldr r5, [r5, #BODY]
  movw r6, #:lower16:bhead  @ point to their real home
  movt r6, #:upper16:bhead
  ldr r6, [r6, #BODY]
  adr r7, hp                @ point to end of relocated headers
  ldr r8, [r7, #BODY]

0:
  ldrb r0, [r5], #1
  strb r0, [r6], #1
  cmp r5, r8
  bne 0b

  str r6, [r7, #BODY]       @ set real head space pointer address

  next

@ ------------------------------------------------------------------------
@ relocate all headers to here, set hp = end of relocated headers

code "pack", pack
  push { lr }               @ save return address

  adr r0, eunpack           @ make unpack run extended unpack
  movw r1, #:lower16:unpack @ the reverse of this pack
  movt r1, #:upper16:unpack
  str r0, [r1, #BODY]

  movw r5, #:lower16:bhead  @ point r5 at bottom of head space
  movt r5, #:upper16:bhead

  ldr r5, [r5, #BODY]
  adr r6, dp                @ point r6 to end of dictionary space
  ldr r6, [r6, #BODY]
  adr r7, hp                @ point r7 to head space variable
  ldr r8, [r7, #BODY]       @ point r8 at end of head space

0:
  ldrb r0, [r5], #1         @ copy data from head space to end of
  strb r0, [r6], #1         @ dictionary
  cmp r5, r8                @ reached end of head space?
  bne 0b

  str r6, [r7, #BODY]

  pop { pc }

@ ========================================================================
