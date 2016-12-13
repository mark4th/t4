@ macros.s
@ ------------------------------------------------------------------------
@ return stack pointer is r12

  rp .req r12

@ ------------------------------------------------------------------------

  .set lex,        0        @ marks next word as immediate, alias etc
  .set _thread,    0        @ link to previous word in current vocabulary

  .set forth_link, 0        @ link to previous word in each vocabulary
  .set comp_link,  0        @ these are only set when some other
  .set root_link,  0        @ vocabulary is current

  .set _voclink,   0        @ assembly voc linkage

@ ------------------------------------------------------------------------
@ vocabulary ids

  .set FORTH,    1
  .set COMPILER, 2
  .set ROOT,     3

@ ------------------------------------------------------------------------

  LEXMASK   = 0x3f          @ mask for nfa count byte
  IMM       = 0x80          @ marks nfa count byte: word as immediate
  ALIAS     = 0x40          @ marks nfa count byte: word is an alias
  BODY      = 8             @ distance from cfa to body = 2 opcodes

@ ------------------------------------------------------------------------
@ make next assembled word an immediate word

.macro _imm_
  .set lex, IMM
.endm

@ ------------------------------------------------------------------------
@ macros to push and pop from both stacks

.macro rpush reg
  str \reg, [rp, #-4]!
.endm

.macro rpop reg
  ldr \reg, [rp], #4
.endm

@ ------------------------------------------------------------------------
@ return from coded definition, execute next token from high level def

.macro next
  bx lr
.endm

@ ------------------------------------------------------------------------
@ return from high level definition

.macro exit
  rpop pc
.endm

@ ------------------------------------------------------------------------
@ assemble a counted string (nfa of word etc)

.macro hstring name
  .byte lex + 9f-(.+1)      @ compile length byte plus lex bits
  .ascii "\name"            @ compile string
9:
  .balign 4, 0              @ end of streaing must be word aligned
.endm

@ ------------------------------------------------------------------------
@ make new header but dont assemble anything to cfa

.macro _header_ name, cfa
  .section .data            @ assemble into head space
  .int _thread
  .set _thread, .
8:                          @ address to link next word header against
  hstring "\name"
  .set lex, 0
  .int \cfa                 @ point header at new words cfa
  .previous                 @ assemble into list space
.endm

@ ------------------------------------------------------------------------
@ assemble a new word header, set cfa -4 = pointer to nfa

.macro header name, cfa
  _header_ "\name", \cfa
  .balign 4, 0              @ make sure cfa aligned so body data will be
  .int _thread              @ cfa -4 points to nfa
.endm

@ ------------------------------------------------------------------------
@ create a second header for an already existing word

.macro _alias_ name, cfa, label
  .set lex, ALIAS
  _header_ "\name", \cfa
  .set \label, \cfa
.endm

@ ------------------------------------------------------------------------
@ assemble a coded definition

.macro code name, cfa
  header "\name", \cfa
\cfa:
.endm

@ ------------------------------------------------------------------------
@ assemble a colon definition

.macro colon name, cfa
  header "\name", \cfa
\cfa:
  nop.w                     @ nest
  rpush lr                  @ save current ip to return stack
.endm

@ ------------------------------------------------------------------------
@ assemble a constant

.macro _constant_ name, cfa, value
  header "\name", \cfa
\cfa:
  rpush lr
  bl dovar
  .int \value
.endm

@ ------------------------------------------------------------------------
@ assemble a variable

.macro _variable_ name, cfa, value
  header "\name", \cfa
\cfa:
  rpush lr
  bl dovariable
  .int \value
.endm

@ ------------------------------------------------------------------------

.macro _var_ name, cfa, value
  header "\name", \cfa
\cfa:
  rpush lr
  bl dovar
  .int \value
.endm

@ ------------------------------------------------------------------------
@ assemble a deferred word

.macro _defer_ name, cfa, value
  header "\name", \cfa
\cfa:
  rpush lr
  bl dodefer
  .int \value
.endm

@ ------------------------------------------------------------------------
@ assebmel a system call

.macro _syscall_ name, cfa, sysnum, pcount
  header "\name", \cfa
\cfa:
  rpush lr
  bl do_syscall
  .hword \sysnum            @ syscall number
  .hword \pcount            @ parameter count
.endm

@ ------------------------------------------------------------------------

.macro _vocab_ name, cfa, thread
  header "\name", \cfa
\cfa:
  rpush lr
  bl dovoc
  .int \thread
  .fill 63, 4, 0
  .int _voclink
  .set _voclink, \cfa
.endm

@ ------------------------------------------------------------------------

.macro literal n1
  push { r0 }
  movw r0, #:lower16:\n1
  movt r0, #:upper16:\n1
.endm

@ ------------------------------------------------------------------------

.macro wliteral n1
  push { r0 }
  movw r0, #\n1
.endm

@ ------------------------------------------------------------------------

.macro cliteral n1
  push { r0 }
  movs r0, #\n1
.endm

@ ------------------------------------------------------------------------

.macro _forth_
  .if voc != forth
  .if voc == compiler       @ if vocabulary currently set to compiler
    .set comp_link, _thread   @ save compilers voc link
  .endif

  .if voc == root           @ if vocabulary currently set to root
    .set root_link, _thread   @ save roots voc link
  .endif

  .set voc, forth
  .set _thread, forth_link
  .endif
.endm

@ ------------------------------------------------------------------------

.macro _compiler_
  .if voc != compiler
  .if voc == forth          @ if vocabulary currently set to forth
    .set forth_link, _thread  @ save forths voc link
  .endif

  .if voc == root           @ if vocabulary currently set to root
    .set root_link, _thread   @ save roots voc link
  .endif

  .set voc, compiler
  .set _thread, comp_link
  .endif
.endm

@ ------------------------------------------------------------------------

.macro _root_
  .if voc != root
  .if voc == forth          @ if vocabulary currently set to forth
    .set forth_link, _thread  @ save forths voc link
  .endif

  .if voc == compiler       @ if vocabulary currently set to compiler
    .set comp_link, _thread   @ save compilers voc link
  .endif

  .set voc, root
  .set _thread, root_link
  .endif
.endm

@ ========================================================================
