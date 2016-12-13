@ exec.s    - forth execution primitives
@ ------------------------------------------------------------------------

@ ------------------------------------------------------------------------
@ useful place to stuff a breakpoint if your unlucky enough to have to
@ debug this kernel using gdb... God save us from gnu dev tools!
@ and for debugging real code (assembler) lldb wont be any better.

@  _imm_

code "break", break
  nop.w                     @ because gdb is too stupid to actually
  nop.w                     @ break on the symbol unless these are here
  nop.w                     @ because it is defined within a macro?
  next

@ ------------------------------------------------------------------------
@ most useful forth word ever!

code "noop", noop
  next

@ ------------------------------------------------------------------------
@ used in extensions to compile an exit from colon definitions

  _imm_

colon "exit", xit
  bl litc                   @ compile the following exit token into the
  exit                      @ definition currently being created
  exit

@ ------------------------------------------------------------------------
@ conditionally exit from a colon definition

@   ( f1 --- )

code "?exit", qexit
  cbz r0, 1f                @ if f1 is zero dont exit
  rpop lr                   @ else pop return address of return stack
1:
  pop { r0 }                @ either way pop new top of stack
  next

@ ------------------------------------------------------------------------
@ execute word whose cfa is at top of stack

@     ( cfa --- )

code "execute", execute
  adds r1, r0, #1           @ thumbificate the target address
  pop { r0 }
  bx r1

@ ------------------------------------------------------------------------
@ execute a deferred word

code "dodefer", dodefer
  bic lr, #1                @ fetch body of deferred word
  ldr r1, [lr]
  rpop lr
  adds r1, #1               @ thumbificate the address
  bx r1

@ ------------------------------------------------------------------------
@ return value of a constant

@     ( --- n1 )

code "dovar", dovar
  push { r0 }
  bic lr, #1
  ldr r0, [lr]
  exit

@ ------------------------------------------------------------------------
@ return address of a variable

@     ( --- a1 )

code "dovariable", dovariable
  push { r0 }
  bic lr, #1
  mov r0, lr
  exit

@ ------------------------------------------------------------------------

colon "bye", bye
  bl atexit                 @ run deferred atexit chain
  bl cr_
  bl cr_
  bl pdotq
  hstring "Au Revoir!"
  bl cr_
  bl cr_
  bl errno                  @ return errno to system
  bl sys_exit

@ ========================================================================
