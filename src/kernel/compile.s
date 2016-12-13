@ compile.s
@ ------------------------------------------------------------------------

@ ------------------------------------------------------------------------

  _var_ "state",   state, 0       @ current compile state
  _var_ "last",    last, last_hdr @ nfa of most recently created word
  _var_ "thread",  thread, 0      @ which voc thread to attach word to

  @ last_hdr above is defined in the linker script

@ ------------------------------------------------------------------------
@ clear instruction cache for a given range

@   ( end start --- )

code "clrcache", clrcache   @ reveal automatically does this
  pop { r1 }                @ get end address to clear icache for
  movw r7, 0x02             @ funky syscall number
  movt r7, 0x0f
  movs r2, #0
  swi 0
  pop { r0 }
  next

@ ------------------------------------------------------------------------
@ align address a1 to 4 byte boundry

@     ( a1 --- a2 )

code "align", align
  adds r0, r0, #3
  bic r0, r0, #3
  next

@ ------------------------------------------------------------------------
@ like (lit) but different

@ not used in this thumb2 kernel

@ code "param", param
@   push { r0 }               @ save top of stack
@   rpop r2                   @ get return address
@   bic r2, #1                @ return addresses are always odd
@   ldrh r0, [r2]             @ fetch 32 bit xt as 2 16 bit reads
@   ldrh r1, [r2, #2]         @ because 32 bit fetches must be 32 bit aligned
@   add r0, r0, r1, lsl #16   @ combine the two 16 bit fetches
@   add r2, r2, #5            @ make sure return address is odd
@   rpush r2                  @ return address was advanced past data
@   next

@ ------------------------------------------------------------------------
@ at address a2, compile a bl opcode to address a1

@ 1111 0... .... .... 11.1 .... .... ....   template
@ .... .SII IIII IIII ..J. Jiii iiii iiii   opcode
@ .... .... SJJI IIII IIII Iiii iiii iiii   address / 2

@     ( a1 a2 --- )

code "call!", callstore
  pop { r1 }                @ get target address
  movw r7, #0xd000          @ template for bl opcode
  movt r7, #0xf000

  subs r1, r1, r0           @ calculate branch delta
  subs r1, r1, #4
  asrs r1, r1, #1

  ubfx r2, r1, #0, #11      @ R2 = I11
  ubfx r3, r1, #11, #10     @ R3 = I10
  ubfx r4, r1, #21, #1      @ R4 = I2
  ubfx r5, r1, #22, #1      @ R5 = I1
  ubfx r6, r1, #31, #1      @ R6 = S

  eors r4, r4, r6           @ J1 = !(S ^ I1)
  eors r5, r5, r6           @ J2 = !(S ^ I2)
  mvns r4, r4
  mvns r5, r5

  bfi r7, r2, #0, #11       @ stitch it all together
  bfi r7, r3, #16, #10
  bfi r7, r4, #11, #1
  bfi r7, r5, #13, #1
  bfi r7, r6, #26, #1

  strh r7, [r0, #2]         @ write opcode
  lsrs r6, r7, #16
  strh r6, [r0]

  pop { r0 }
  next

@ ------------------------------------------------------------------------
@ compile a bl to address a1 at 'here'

@     ( a1 --- )

colon ",xt", commaxt
  bl here                   @ get address to compile
  bl cell                   @ allocate one cell for opcode
  bl allot
  bl callstore              @ compile bl to address a1
  exit

@ ------------------------------------------------------------------------
@ disassemble a bl opcode into its target address

@   ( a1 --- a2 )

code "xt@", xtfetch
  movs r1, r0               @ <bl wants r1 = address of bl opcode
  ldrh r2, [r1]             @ fetch xt opcode
  ldrh r3, [r1, #2]
  add r0, r3, r2, lsl #16

  push { lr }
  bl from_bl                @ this does the actual work (in loops.s)
  pop { lr }

  add r0, r1, r2            @ add branch delta to branch address
  add r0, r0, #5
  next

@ ------------------------------------------------------------------------
@ fetch xt to be compiled. xt is a bl opcode, we need the target address

@     ( --- a1 )

colon "(compile)", pcompile
  push { r0 }               @ save top of stack
  ldr r0, [rp, #4]          @ fetch our callers return address
  adds r2, r0, #4           @ advance it past the xt to be compiled
  str r2, [rp, #4]
  bic r0, #1                @ de-thumbificate the address
  bl xtfetch                @ fetch and disassemble bl opcode
  exit

@ ------------------------------------------------------------------------

@     ( --- )

colon "compile", compile
  bl pcompile               @ fetch address to bl to (to call)
  bl commaxt                @ compile call to target address at 'here'
  exit

@ ------------------------------------------------------------------------
@ compile next space delimited token from input stream as an xt

  _imm_

colon "[compile]", bcompile
  bl tick                   @ parse input stream, find address of word
  bl commaxt                @ compile a bl to this address
  exit

@ ------------------------------------------------------------------------
@ same as above but does not comma in an xt but an address (no bl opcode)

@ in some forths this would be how [compile] would be defined

colon "['],", btcomma
  bl tick                   @ parse input stream, find address of word
  bl comma                  @ compile this address (not as a bl opcode)
  exit

@ ------------------------------------------------------------------------
@ construct a movw or a movt opcode

@     ( w1 op-bit ---- opcode )

@ OPBIT ------------V
@ MOVT  = 1111 0.10 1100 .... 0... rrrr .... ....
@ MOVW  = 1111 0.10 0100 .... 0... rrrr .... ....

code"(literal)", pliteral
  pop { r1 }                @ get literal w1
  movs r7, #0               @ r7 = opcode template
  movw r7, #0xf240

  ubfx r2, r1, #0, #8       @ r2 = imm8
  ubfx r3, r1, #8, #3       @ r3 = imm3
  ubfx r4, r1, #11, #1      @ r5 = imm1
  ubfx r5, r1, #12, #4      @ r4 = imm4

  bfi r7, r0, #7, #1        @ insert op-bit (movw = 0, movt = 1)
  bfi r7, r2, #16, #8       @ insert imm8
  bfi r7, r3, #28, #3       @ insert imm3
  bfi r7, r4, #10, #1       @ insert imm1
  bfi r7, r5, #0, #4        @ insert imm4

  movs r0, r7
  next

@ when using movw and movt opcodes you must do the movw operation first
@ as movw is zero extending.

@ ------------------------------------------------------------------------
@ compile an inline 16 bit literal

@     ( w1 --- )

wliteral:
  rpush lr
  cliteral 0              @ op-bit for movw
1:
  bl pliteral             @ construct opcode
  bl comma                @ compile opcode
  exit

@ ------------------------------------------------------------------------
@ compile an inline 32 bit literal

@     ( n1 --- )

dliteral:
  rpush lr
  bl dup                  @ compile a movw r0, #n1.low16
  bl wliteral
  cliteral 16             @ shift upper 16 bits of literal down
  bl shrr
  cliteral 1              @ op-bit for movt
  b 1b

@ ------------------------------------------------------------------------
@ compile an 8 bit literal

@     ( c1 --- )

cliteral:
  rpush lr
  movw r1, #0x2000        @ opcode template
  ands r0, #0xff          @ movs r0, #0xNN
  orr r0, r1
  bl wcomma
  exit

@ ------------------------------------------------------------------------

  _imm_

colon "literal", literal
  bl wlitc                  @ compile a push r0
  push { r0 }

  bl dup                    @ pick most efficient coding for the literal
  wliteral 0x100
  bl uless
  bl qbranch
  .hword (1f - .) + 1
  bl cliteral               @ mov r0, #literal
  exit

1:
  bl dup                    @ test if literal fits in 16 bits
  wliteral 0xffff
  bl ugreater
  bl qbranch
  .hword (2f - .) + 1
  bl dliteral               @ compile a 32 bit literal movw/movt
  exit

2:
  bl wliteral               @ compile a 16 bit literal (movw r0, #lit)
  exit

@ ------------------------------------------------------------------------
@ switch into interpret mode

  _imm_

code "[", lbracket
  movs r2, #0               @ turn state off
0:
  adr r1, state             @ point to state variable
  str r2, [r1, #BODY]
  next

@ ------------------------------------------------------------------------
@ switch into compile mode

code "]", rbracket
  mvn r2, #0                @ turn state on
  b 0b

@ ------------------------------------------------------------------------
@ compile an rpush lr

@     ( a1 --- a2 )

rpushlr:                    @ this needs to be balign 4
  movw r1, #0xf84c          @ rpush lr
  movt r1, #0xed04
  str r1, [r0], #4          @ first word of CFA = push return address
  next

@ ------------------------------------------------------------------------
@ patch most recent words cfa to be a call word following ;uses

colon ";uses", suses
  bl pcompile               @ fetch address to "use"
1:
  bl last                   @ get nfa of word to be patched
  bl nameto                 @ to cfa
  bl rpushlr                @ compile an rpush lr
  bl callstore              @ second word of CFA = call to handler
  exit

@ ------------------------------------------------------------------------
@ patch most recent words cfa to be a call to asm directly after ;code

@ this is an implied exit

code ";code", scode
  push { r0 }               @ get address of code to "use"
  movs r0, lr
  bic r0, #1                @ de-thumbificate the address
  b 1b                      @ patch most recent cfa to call this addres

@ ------------------------------------------------------------------------
@ make most recently created word an immediate word

colon "immediate", immediate
  cliteral IMM              @ seting bit 7 of the words NFA count byte
  bl last                   @ makes the word immediate
  bl cset
  exit

@ ------------------------------------------------------------------------
@ create a new word.  this is always assumed to be a variable

colon "create", create
  bl headcomma              @ create a new word header

  cliteral BODY             @ allocate cfa
  bl allot
  bl suses                  @ compile dovariable into cfa of created word
  bl dovariable
  bl reveal                 @ reveal newly created word to the world
  exit

@ ------------------------------------------------------------------------
@ create a new high level (colon) definition

colon ":", colon
  bl headcomma              @ create a header for the : def
  bl litc                   @ compile its cfa (two opcodes)
  nop.w                     @ first opcode is a nop for colon definitions
  bl litc
  rpush lr                  @ second opcode is a push lr
  bl rbracket               @ sewitch into compile mode
  exit

@ ------------------------------------------------------------------------
@ complete a high level definition

  _imm_

colon ";" semi
  bl litc                   @ compile an exit opcode onto end of : def
  exit
  bl lbracket               @ switch out of compile mode
  bl reveal                 @ reveal it to the word and clear the
  exit                      @ instruction cache so it can be executed

@ ========================================================================

