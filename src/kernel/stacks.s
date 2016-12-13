@ stacks.s    - stack manipulation words
@ ------------------------------------------------------------------------

@ ------------------------------------------------------------------------

  _var_ "sp0", sp0, 0
  _var_ "rp0", rp0, 0

@ ------------------------------------------------------------------------
@ duplicate top of stack unless it is zero

@     ( n1 --- n1 n1 | n1 )

code "?dup", qdup
  cmp r0, #0
  it ne
  pushne { r0 }
  next

@ ------------------------------------------------------------------------
@ duplicate top of stack

@     ( n1 --- n1 n1 )

code "dup", dup
  push { r0 }
  next

@ ------------------------------------------------------------------------
@ duplicate top two items of stack

@     ( n1 n2 --- n1 n2 n1 n2 )

code "2dup", twodup
  mov r1, sp
  ldr r1, [r1]
  push { r0 }
  push { r1 }
  next

@ ------------------------------------------------------------------------
@ duplicate top three items of stack

@     ( n1 n2 n3 --- n1 n2 n3 n1 n2 n3 )

code "3dup", threedup
  pop { r1, r2 }
  push { r0, r1, r2 }
  push { r1, r2 }
  next

@ ------------------------------------------------------------------------
@ swap order of top two items of stack

@     ( n1 n2 --- n2 n1 )

code "swap", swap
  pop { r1 }
  push { r0 }
  mov r0, r1
  next

@ ------------------------------------------------------------------------
@ swap order of top two pairs of items on stack

@   ( n1 n2 n3 n4 --- n3 n4 n1 n2 )

code "2swap", twoswap
  pop { r1, r2, r3 }
  push { r0, r1 }
  push { r3 }
  movs r0, r2
  next

@ ------------------------------------------------------------------------
@ discard top item of stack

@     ( n1 --- )

code "drop", drop
  pop { r0 }
  next

@ ------------------------------------------------------------------------
@ discard top two items of stack

@     ( n1 n2 --- )

code "2drop", twodrop
  add sp, sp, #4
  pop { r0 }
  next

@ ------------------------------------------------------------------------
@ discard top three items of stacl

@     ( n1 n2 n3 --- )

code "3drop", threedrop
  add sp, sp, #8
  pop { r0 }
  next

@ ------------------------------------------------------------------------
@ copy second item on stack over top of top item

@     ( n1 n2 --- n1 n2 n1 )

code "over", over
  push { r0 }
  ldr r0, [sp, #4]
  next

@ ------------------------------------------------------------------------
@ discard second item on stack

@     ( n1 n2 --- n2 )

code "nip", nip
  add sp, sp, #4
  next

@ ------------------------------------------------------------------------
@ copy top item of stack under second item

@     ( n1 n2 --- n2 n1 n2 )

code "tuck", tuck
  ldr r1, [sp]
  str r0, [sp]
  push { r1 }
  next

@ ------------------------------------------------------------------------
@ copy third item of stack out to top

@     ( n1 n2 n3 --- n1 n2 n3 n1 )

code "pluck", pluck
  push { r0 }
  ldr r0, [sp, #8]
  next

@ ------------------------------------------------------------------------
@ copy n1th item of stack

@     ( ... n1 --- n2 )

code "pick", pick
  ldr r0, [sp, r0, lsl #2]
  next

@ ------------------------------------------------------------------------
@ rotate third item of stack out to top

@     ( n1 n2 n3 --- n2 n3 n1 )

code "rot", rot
  pop { r1, r2 }
  push { r0, r1 }
  movs r0, r2
  next

@ ------------------------------------------------------------------------
@ rotate top item of stack down to third slot

@     ( n1 n2 n3 --- n3 n1 n2 )

code "-rot", drot
  movs r2, r0
  pop { r0, r1 }
  push { r1, r2 }
  next

@ ------------------------------------------------------------------------
@ move top item of parameter stack to the return stack

@     ( n1 --- )

code ">r", tor
  rpush r0
  pop { r0 }
  next

@ ------------------------------------------------------------------------
@ move top two items of stack to return stack

@     ( n1 n2 --- )

code "2>r", twotor
  pop { r1, r2 }
  rpush r0
  rpush r1
  movs r0, r2
  next

@ ------------------------------------------------------------------------
@ move top item of return stack to the parameter stack

@     ( --- n1 )

code "r>", rto
  push { r0 }
  rpop r0
  next

@ ------------------------------------------------------------------------
@ move top two items of return stack to the parameter stack

@     ( --- n1 n2 )

code "2r>", tworto
  push { r0 }
  ldmia rp!, { r0, r1 }
  push { r0 }
  mov r0, r1
  next

@ ------------------------------------------------------------------------
@ copy top item of parameter stack to the return stack

@     ( n1 --- n1 )

code "dup>r", duptor
  rpush r0
  next

@ ------------------------------------------------------------------------

code "r>drop", rdrop
  add rp, rp, #4
  next

@ ------------------------------------------------------------------------
@ copy top item of return stack to the parameter stack

@   ( --- n1 )

code "r@", rfetch
  push { r0 }
  ldr r0, [rp]
  next

@ ------------------------------------------------------------------------
@ get address of parameter stack

@     ( --- a1 )

code "sp@", spfetch
  push { r0 }
  mov r0, sp
  next

@ ------------------------------------------------------------------------
@ set address of parameter stack

@     ( a1 --- )

code "sp!", spstore
  mov sp, r0
  pop { r0 }
  next

@ ------------------------------------------------------------------------
@ get address of return stack

@     ( --- a1 )

code "rp@", rpfetch
  push { r0 }
  mov r0, rp
  next

@ ------------------------------------------------------------------------
@ set address of return stack

@     ( a1 --- )

code "rp!", rpstore
  mov rp, r0
  pop { r0 }
  next

@ ------------------------------------------------------------------------
@ not sure where this really belongs (math.s ?)

@     ( n1 --- lo hi )

code "split", split
  ubfx r1, r0, #16, #16
  ubfx r0, r0, #0, #16
  push { r1 }
  next

@ ------------------------------------------------------------------------

@     ( lo hi --- n1 )

code "join", join
  pop { r1 }
  add r0, r1, r0, lsl #16
  next

@ ------------------------------------------------------------------------
@ get number of items on parameter stack

colon "depth", depth
  bl spfetch
  bl sp0
  bl swap
  bl minus
  asrs r0, #2
  exit

@ ------------------------------------------------------------------------

colon ".under", dotunder
  bl pdotq
  hstring "Stack Underflow!"
  bl abort

@ ------------------------------------------------------------------------

colon ".over", dotover
  bl pdotq
  hstring "Stack Overflow!"
  bl abort

@ ------------------------------------------------------------------------

colon "?stack", qstack
  bl spfetch                @ get current stack pointer address
  bl sp0                    @ get address of bottom of stack
  bl ugreater               @ make sure we are below this address
  bl qbranch
  .hword (1f - .) + 1
  bl dotunder

1:
  bl rpfetch                @ get current return stack pointer address
  bl rp0                    @ get address of bottom of return stack
  bl ugreater               @ make sure we are below this address
  bl qbranch
  .hword (2f - .) + 1
  bl dotunder

2:
  bl rpfetch                @ get currrent return stack pointer address
  bl rp0                    @ get address of top of return stack
  wliteral 0x1000           @ if you need more than 4k of return stack then
  bl minus                  @ what you really need is a different job! :)
  bl ugreater               @ make sure we are above this address
@bl not
  bl qexit
  bl dotunder

  exit

@ ========================================================================
