@ math.s
@ ------------------------------------------------------------------------

@ ------------------------------------------------------------------------
@ add top two items of parameter stack

@       ( n1 n2 --- n3 )

code "+", plus
  pop { r1 }
  adds r0, r0, r1
  next

@ ------------------------------------------------------------------------
@ compute difference between top two items of parameter stack

@       ( n1 n2 --- n3 )

code "-", minus
  pop { r1 }
  subs r0, r1, r0
  next

@ ------------------------------------------------------------------------
@ compute absolute value of top item of parameter stack

@       ( n1 --- n1` )

code "abs", abs
  movs r1, r0, asr #31
  eors r0, r0, r1
  subs r0, r0, r1
  next

@ ------------------------------------------------------------------------
@ shift left n1 by n2 bits

@       ( n1 n2 --- n3 )

code "<<", shll
  pop { r1 }
  movs r0, r1, lsl r0
  next

@ ------------------------------------------------------------------------
@ signed shift right n1 by n2 bits

@       ( n1 n2 --- n3 )

code ">>", shrr
  pop { r1 }
  movs r0, r1, asr r0
  next

@ ------------------------------------------------------------------------
@ unsigned shift right n1 by n2 bits

@       ( n1 n2 --- n3 )

code "u>>", ushr
  pop { r1 }
  movs r0, r1, lsr r0
  next

@ ------------------------------------------------------------------------
@ multiply top item of parameter stack by two

@       ( n1 --- n2 )

code "2*", twostar
  lsls r0, #1
  next

@ ------------------------------------------------------------------------
@ multiply top item of parameter stack by three

@       ( n1 --- n2 )

code "3*", threestar
  adds r0, r0, r0, lsl #1
  next

@ ------------------------------------------------------------------------
@ multiply top item of parameter stack by four

@       ( n1 --- n2 )

code "4*", fourstar
  lsls r0, #2
  next

@ ------------------------------------------------------------------------
@ signed divide top item of parameter stack by two

@       ( n1 --- n2 )


code "2/", twoslash
  asrs r0, #1
  next

@ ------------------------------------------------------------------------
@ unsigned divide top item of parameter stack by two

@       ( n1 --- n2 )

code "u2/", u2slash
  lsrs r0, #1
  next

@ ------------------------------------------------------------------------
@ divide top item of parameter stack by four

@       ( n1 --- n2 )

code "4/", fourslash
  asrs r0, #2
  next

@ ------------------------------------------------------------------------
@ add one to top item of parameter stack

@       ( n1 --- n2 )

code "1+", oneplus
  adds r0, r0, #1
  next

@ ------------------------------------------------------------------------
@ subtract one from top item of parameter stack

@       ( n1 --- n2 )

code "1-", oneminus
  subs r0, r0, #1
  next

@ ------------------------------------------------------------------------
@ add two to top item of parameters stack

@       ( n1 --- n2 )

code "2+", twoplus
  adds r0, r0, #2
  next

@ ------------------------------------------------------------------------
@ subtract two from top item of parameter stack

@       ( n1 --- n2 )

code "2-", twominus
  subs r0, r0, #2
  next

@ ------------------------------------------------------------------------
@ add three to top item of parameter stack

@       ( n1 --- n2 )

code "3+", threeplus
  adds r0, r0, #3
  next

@ ------------------------------------------------------------------------
@ subtract three from top item of parameter stack

@       ( n1 --- n2 )

code "3-", threeminus
  subs r0, r0, #3
  next

@ ------------------------------------------------------------------------
@ add four to top item of parameter stack

@       ( a1 --- a2 )

code "4+", fourplus
  adds r0, r0, #4
  next

@ ------------------------------------------------------------------------
@ subtract four from top item of parameter stack

@       ( a1 --- a2 )

code "4-", fourminus
  subs r0, r0, #4
  next

@ ------------------------------------------------------------------------
@ twos complement top of parameter stack

@       ( n1 --- n2)

code "negate", negate
  rsbs r0, r0, #0
  next

@ ------------------------------------------------------------------------
@ conditionally twos complement second of parameter stack

@       ( n1 n2 --- n2)

code "?negate", qnegate
  cmp r0, #0
  pop { r0 }
  it ne
  rsbne r0, r0, #0
  next

@ ------------------------------------------------------------------------
@ twos complement double

@       ( d1 --- d2 )

code "dnegate", dnegate
  pop { r1 }
  movs r2, #0
  rsbs r1, r1, #0
  sbc r0, r2, r0
  push { r1 }
  next

@ ------------------------------------------------------------------------
@ add top two double numbers

@       ( d1 d2 --- d3 )

code "d+", dplus
  pop { r1, r2, r3 }
  adds r1, r3, r1
  adcs r0, r2, r0
  push { r1 }
  next

@ ------------------------------------------------------------------------
@ compute difference between top two double numbers

@       ( d1 d2 --- d3 )

colon "d-", dminus
  bl dnegate
  bl dplus
  exit

@ ------------------------------------------------------------------------
@ compute absolute value of top double number

@       ( d1 --- d2 )

code "dabs", dabs
  cmp r0, #0
  bmi dnegate
  next

@ ------------------------------------------------------------------------
@ sign extend single to double

@       ( n1 --- d1 )

code "s>d", s2d
  push { r0 }
  movs r0, r0, asr #31
  next

@ ------------------------------------------------------------------------
@ unsigned multiply double by single

@       ( d1 n1 --- d2 )

code "um*", umstar
  pop { r1 }
  umull r2, r3, r0, r1
  push { r2 }
  mov r0, r3
  next

@ ------------------------------------------------------------------------
@ signed multiply double by single

@       ( d1 n1 --- d2 )

code "m*", mstar
  pop { r1 }
  smull r2, r3, r0, r1
  push { r2 }
  mov r0, r3
  next

@ ------------------------------------------------------------------------
@ compute product of top two items of parameter stack

@       ( n1 n2 --- n3 )

code "*", star
  pop { r1 }
  mul r0, r1
  next

@ ------------------------------------------------------------------------
@ multiply top two items of parameter stack then add the third

@       ( n1 n2 n3 --- n4 )

code "*+", star_plus
  pop { r1, r2 }
  mul r0, r1
  add r0, r2
  next

@ ------------------------------------------------------------------------
@ signed 32 / 32 divide  (fast)

@     ( n1 n2 --- rem quo )

code "sdiv", sdiv
  pop { r1 }
  sdiv r2, r1, r0
  mls r3, r2, r0, r1
  adds r2, r2, r3, asr #31
  ands r0, r0, r3, asr #31
  adds r3, r3, r0
  push { r3 }
  movs r0, r2
  next

@ ------------------------------------------------------------------------
@ unsigned 32 / 32 divide (fast)

@     ( n1 n2 --- rem quo )

code "udiv", udiv
  pop { r1 }
  udiv r2, r1, r0
  mls r0, r2, r0, r1
  push { r0 }
  movs r0, r2
  next

@ ------------------------------------------------------------------------
@ software 64/32 division (slow)

@   ( d1 n1 --- rem quo )

code "um/mod", ummod
  pop { r1, r2 }

  movs r3, #0
  movs r5, #64
1:
  adds r2, r2, r2
  adcs r1, r1, r1
  adcs r3, r3, r3
  itee cc
  subscc r4, r3, r0
  subcs r3, r3, r0
  addcs r2, r2, #1
  subs r5, r5, #1
  bne 1b

  push { r3 }

  mov r0, r2
  next

@ ------------------------------------------------------------------------
@ fast NEON 64/32 divide

@     ( d1 n1 --- rem quo )

code "vdiv", vdiv
  vpop { s0, s1 }           @ pop d1 into s0 and s1
  vcvt.f64.u32 d1, s1       @ convert s1 to 64 bit float
  vcvt.f64.u32 d0, s0       @ convert s0 to 64 bit float

  vshl.i64 d0, d0, #32      @ shift d0 to hi 32 bits and add to low 32
  vadd.f64 d0, d0, d1       @ D0 = 64 bit d1 in floating point

  vmov s2, r0               @ convert divisor to 64 bit float
  vcvt.f64.u32 d1, s2       @ D1 = divisor

  vdiv.f64 d2, d0, d1       @ divide d0 by d1, result in d2

  vcvt.u32.f64 s4, d2
  vmov r0, s4               @ r0 = quotient
  vcvt.f64.u32 d2, s4       @ convert result back to float sans fraction

  vmul.f64 d3, d2, d1       @ D3 = result * divisor
  vsub.f64 d4, d0, d3       @ calculate remainder
  vcvt.u32.f64 s0, d4

  vpush { s0 }
  next

@ ------------------------------------------------------------------------
@ zero extend 16 bit r0 to 32 bits

@     ( h1 --- n1 )

code "uxth", uxth
  uxth r0, r0
  next

@ ------------------------------------------------------------------------
@ sign extend 16 bit r0 to 32 bits

@     ( h1 --- n1 )

code "sxth", sxth
  sxth r0, r0
  next

@ ------------------------------------------------------------------------
@ divide double by single, return double q, single r

@       ( d1 n1 --- rem quo )

colon "mu/mod", musmod
  bl tor
  cliteral 0
  bl rfetch
  bl vdiv                   @ bl ummod
  bl rto
  bl swap
  bl tor
  bl vdiv                   @ bl ummod
  bl rto
  exit

@ ------------------------------------------------------------------------

colon "(/mod)", psmod
  bl dup
  bl zless
  bl pluck
  bl zless
  bl xor
  bl twotor
  bl abs
  cliteral 0
  bl rto
  bl abs
  bl vdiv                   @ bl ummod
  bl rto
  bl qnegate
  exit

@ ------------------------------------------------------------------------
@ wrapper for (/mod) to floor result

colon "/mod", smod
  bl twodup
  bl xor
  bl zless
  bl qbranch
  .hword (3f - .) + 1
  bl duptor
  bl psmod
  bl over
  bl qbranch
  .hword (1f - .) + 1
  bl oneminus
  bl swap
  bl rto
  bl minus
  bl negate
  bl swap
  bl branch
  .hword (2f - .) + 1
1:
  bl rdrop
2:
  bl branch
  .hword (4f - .) + 1
3:
  bl psmod
4:
  exit

@ ------------------------------------------------------------------------

colon "mod", mod
  bl smod
  bl drop
  exit

@ ------------------------------------------------------------------------

colon "/", slash
  bl smod
  bl nip
  exit

@ ------------------------------------------------------------------------
@ neat arm code stolen from the net

code "bswap", bswap
  rev r0, r0                @ armv6 or higher
  next

@ ========================================================================
