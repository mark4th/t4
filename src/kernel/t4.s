@ t4.s   - arm thumb2 forth
@ ------------------------------------------------------------------------

  .thumb
  .syntax unified

@ ------------------------------------------------------------------------

ver     = 0x0001

MEMSZ   = 0x100000          @ memory size of process
STKSZ   = 0x1000            @ size of return stack buffer
FLDSZ   = 36 * 5            @ fload stack size
TIBSZ   = 0x400             @ terminal input buffer size

@ ------------------------------------------------------------------------
@ load macros to create word headers in own section etc

  .include "macros.s"       @ this is where the magic happens

@ ------------------------------------------------------------------------
@ red tape

  .section .text
  .global origin            @ none of that _________start stuff here :)

@ ------------------------------------------------------------------------
@ entry point to process must be a arm opcode

.arm                        @ process entry point must be in ARM mode
origin:                     @ address of start of process code space
  blx start                 @ this switches us to thumb mode
.thumb

@ ------------------------------------------------------------------------

  _forth_                   @ put words in the forth vocabulary

  _constant_ "origin",     org, origin
  _constant_ "version",    version, ver
  _constant_ "thead",      thead, 0
  _constant_ "head0",      bhead, 0

  _constant_ "arg0",       arg0, 0
  _constant_ "argc",       argc, 0
  _constant_ "argv",       argv, 0
  _constant_ "envp",       envp, 0
  _constant_ "auxp",       auxp, 0

  _constant_ "shebang",    shebang, 0
  _constant_ "intty",      intty,0
  _constant_ "outtty",     outtty, 0
  _constant_ "turnkeyd",   turnkeyd, 0

  _var_      "?tty",       qtty, 0

  _var_      "lsp",        lsp, 0

  _var_      "heap-prot",  heap_prot, 7
  _var_      "heap-flags", heap_flg, 0x22

@ ------------------------------------------------------------------------
@ extreme magic hackery

  _defer_    "rehash",     rehash, _rehash
  _defer_    "unpack",     unpack, kunpack

@ ------------------------------------------------------------------------
@ prioritized initialization chains

  _defer_    "pdefault",   pdefault, noop
  _defer_    "default",    default, noop
  _defer_    "ldefault",   ldefault, noop

@ ------------------------------------------------------------------------
@ cleanup prior to exit back to system

  _defer_    "atexit",     atexit, noop

@ ------------------------------------------------------------------------
@ useful debug words (defined in an extension)

  _defer_    ".s",         dots, noop
  _defer_    ".us",        udots, noop

@ ------------------------------------------------------------------------
@ check specified descriptor for being a controlling terminal

_chktty:                    @ ( --- f1 )
  movs r7, #0x36            @ sys_ioctl
  movw r1, #0x5401

  movw r2, #:lower16:hp     @ point r2 to hp
  movt r2, #:upper16:hp
  ldr r2, [r2, #BODY]       @ were not interested in the tios data

  swi 0                     @ only the return value from the syscall

  subs r0, r0, #1           @ set result = t/f
  sbcs r0, r0, r0
  bx lr

@ ------------------------------------------------------------------------
@ is stdin/stdout on a controlling terminal?

chk_tty:
  push { lr }
  movs r0, #0               @ is stdin a tty?
  bl _chktty
  adr r1, intty             @ put t/f result in constant
  str r0, [r1, #BODY]
  movs r0, #1               @ is stdout a tty?
  bl _chktty
  adr r1, outtty            @ put t/f result in constant
  str r0, [r1, #BODY]
  pop { pc }

@ ------------------------------------------------------------------------
@ initialize some of forths core variables

@ r8 holds address of start of .text section which is also the address
@    of this processes elf headers

init_vars:
  movs r0, #0               @ terminal properties not set yet
  adr r1, shebang           @ clear flag: launched from a #! script
  str r0, [r1, #BODY]

  mov r0, r8                @ point to start of text section

  @ add in memory size - fload stack size

  movw r2, #:lower16:MEMSZ-FLDSZ
  movt r2, #:upper16:MEMSZ-FLDSZ
  add r0, r0, r2
  adr r1, lsp               @ this is the address of the fload stack buffer
  str r0, [r1, #BODY]

  mov r2, #TIBSZ            @ subtract size of terminal input buffer
  subs r0, r0, r2
  adr r1, tib
  str r0, [r1, #BODY]       @ this is the address of the terminal input buffer

  adr r1, thead
  str r0, [r1, #BODY]       @ is the address of top of header space

  mov r0, r8                @ point to half way up memory
  mov r2, #MEMSZ / 2
  add r0, r0, r2

  movs r2, #0
  movw r2, #0x3ff           @ align to page
  add r0, r0, r2
  bic r0, r0, r2

  adr r1, bhead             @ bhead is needed by fsave so that it can tell
  str r0, [r1, #BODY]       @ where head space starts
  bx lr

@ ------------------------------------------------------------------------
@ save args for later processing

get_args:
  pop { r0, r2 }            @ r0 = argc, r2 = arg0

  adr r1, arg0
  str r2, [r1, #BODY]       @ name this process was launched under

  adr r1, argv              @ arg pointers are not moved off the stack
  str sp, [r1, #BODY]       @ we just need to remember where they are

  adds r2, sp, r0, lsl #2   @ point r2 past arg pointers on the stack **
  subs r0, r0, #1           @ argc does not count arg0 now
  adr r1, argc              @ remember arg count
  str r0, [r1, #BODY]
  adr r1, envp              @ ** r2 was set to point to the env above
  str r2, [r1, #BODY]       @ save address of array of env var pointers

0:
  ldr r0, [r2], #4          @ scan through env array next to null pointer
  cmp r0, #0
  bne 0b
  adr r1, auxp              @ this is the address of the aux variables
  str r2, [r1, #BODY]

  bx lr

@ ------------------------------------------------------------------------
@ primitive for memory allocation = fetch an anonumous memory mapping

_fetchmap:
  movs r0, #0               @ addr
  mvn r4, #0                @ fd = annonymous mapping
  movs r5, #0               @ start address
  movs r7, #0xc0            @ sys mmap2
  swi 0
  bx lr

@ ------------------------------------------------------------------------
@ allocate the return stack

alloc_ret:
  push { lr }
  mov r1, #STKSZ            @ size
  movs r2, #3               @ prot
  movs r3, #0x22            @ flags
  bl _fetchmap

  mov r1, #STKSZ            @ set rp address = top of return stack buffer
  add r0, r0, r1

  adr r1, rp0               @ point r1 at rp0 variable
  str r0, [r1, #BODY]       @ set constant bottom of return stack
  mov rp, r0                @ set rp = bottom of return stack
  adr r1, sp0               @ point r1 at sp0 variable
  str sp, [r1, #BODY]       @ set constant bottom of parameter stack

  pop { pc }

@ ------------------------------------------------------------------------
@ sys mprotect entire memory range of process to +rwx

init_mem:
  mov r0, r8                @ point r0 at start of memory
  mov r1, #MEMSZ            @ mem size = 1 meg
  movs r2, #7               @ +r +w +x
  movs r7, #0x7d            @ sys mprotect
  swi 0
  bx lr

@ ------------------------------------------------------------------------
@ used by the memory manager extension

@     ( size --- a1 f | t )

colon "@map", fmap
  adr r2, heap_prot         @ user selectable heap protection
  ldr r2, [r2, #BODY]
  adr r3, heap_flg          @ user selectable flags
  ldr r3, [r3, #BODY]
  movs r1, r0               @ size
  bl _fetchmap              @ get an anonymous mapping
  cmp r0, #0xfffff000       @ unable to allocate?
  blo 1f
  mvn r0, #0                @ yup, return failure
  exit

1:
  push { r0 }               @ success. return address of mapping
  movs r0, #0               @ return success indication
  exit

@ ------------------------------------------------------------------------
@ clear all memory from 'here' to head space

@ doing this also causes all the memory that linux has assigned to this
@ application to be physically allocated not just virtually allocated to
@ it.
@
@ this is somewhat greedy because linux will probably assign pages to us
@ that we never actuallyuse other than to clear them here.  during deve
@ and testing this is fine as it speeds up compilation slightly for
@ production you probably should not be doing this.

@ you can create two versions of the kernel, one with this function and
@ one without. during development use the one with. once development is
@ complete compile your application against the other and fsave or
@ turnkey a new application executable

clr_mem:
  movs r0, #0
  movw r1, #:lower16:dp
  movt r1, #:upper16:dp
  ldr r1, [r1, #BODY]
  adr r2, bhead             @ point r2 at bottom of head space
  ldr r2, [r2, #BODY]
0:
  str r0, [r1], #1
  cmp r1, r2
  bne 0b
  bx lr

@ ------------------------------------------------------------------------
@ entry point to forths initialization

start:
  mov r8, pc                @ address of start of process memory
  movw r0, #0xf000
  movt r0, #0xffff
  and r8, r8, r0

  bl init_mem               @ make process memory +rwx
  bl init_vars              @ initialize some forth variables
  bl get_args               @ initialize command line args
  bl alloc_ret              @ allocate return stack
  bl unpack                 @ unpack headers into head space
  bl rehash                 @ fixup for crippled gnu assembler
  bl clr_mem                @ erase code space from here to headers
  bl chk_tty                @ see if we have a controlling terminal

  bl pdefault               @ high priority init (stuff must happen early)
  bl default                @ normal priority init chain
  bl ldefault               @ low priority default init chain

  b quit                    @ start running forths inner loop

@ ------------------------------------------------------------------------
@ the beef

  .include "exec.s"         @ basic forth execution handlers
  .include "syscalls.s"     @ system calls and signals
  .include "stacks.s"       @ stack manipulation words
  .include "memory.s"       @ fetch, store etc
  .include "math.s"         @ basic math
  .include "logic.s"        @ more basic math
  .include "io.s"           @ basic i/o
  .include "expect.s"       @ query and expect
  .include "scan.s"         @ skip and scan
  .include "number.s"       @ number input words
  .include "interpret.s"    @ interpreting input

  _compiler_

  .include "compile.s"      @ creating and compiling
  .include "loops.s"        @ branching and looping
  .include "comma.s"        @ comma is the actual compiler
  .include "header.s"       @ forth word header creation
  .include "find.s"         @ dictionary searches
@  .include "variable.s"     @ variable and constant creation etc
  .include "fload.s"        @ input from file

  _root_

  .include "reloc.s"        @ header relocation
  .include "rehash.s"       @ one time fixup

  @ vocabs.s MUST be the last file included

  .include "vocabs.s"       @ vocabulary manipulation

@ ========================================================================
