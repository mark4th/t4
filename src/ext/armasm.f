\ armasm.f
\ ------------------------------------------------------------------------

  <headers

  0 var cc                  \ condition code
  0 var sh                  \ shift type
  0 var ss                  \ s flag
  0 var in{}                \ true if within {}
  0 var rlist               \ register list
  0 var regs,               \ up to 4 registers             rn,
  0 var rcount              \ how many registers specified
  0 var reg                 \ source registers              rn
  0 var ##                  \ true if immediate given
  0 var delayed             \ true if were processing a delayed mnemonic

\ ------------------------------------------------------------------------

: cc! ( condition --- ) !> cc ;
: !s  ( n1 --- )        !> ss ;
: !#  ( n1 --- )        !> ## ;

\ ------------------------------------------------------------------------
\ create destination/intermediate registers

: reg:,    ( n1 --- n2 )
  dup create , 1+           \ create register contsant value
  does>
    @ in{}                  \ get register value. are we within braces?
    if
      1 swap << +!> rlist   \ yes add selected register to register list
    else                    \ not within braces
      $80 or                \ make non zero
      rcount << +!> regs    \ add register value to array of registers
      incr> rcount          \ used in opcode
      \ abort if rcount = 5 ?
    then ;

  headers>

  0 8 rep reg:, r0, r1, r2,  r3,  r4,  r5,  r6,  r7,
    8 rep reg:, r8, r9, r10, r11, r12, r13, r14, r15,

  ' r12, alias rp,
  ' r13, alias sp,
  ' r14, alias lr,
  ' r15, alias pc,

\ ------------------------------------------------------------------------
\ ceate destination pointer register (must be used with ldm/stm)

: reg:!,
  dup create, 1+
  does>
    @ in{}                  \ cant be inside braces for this
    if
      abort" syntax error"
    else
      $800 or !> reg        \ set destination pointer register
    then

  0 8 rep reg:!, r0!, r1!, r2!,  r3!,  r4!,  r5!,  r6!,  r7!,
    7 rep reg:!, r8!, r9!, r10!, r11!, r12!, r13!, r14!,

  ' r12!, alias rp,
  ' r13!, alias sp,
  ' r14!, alias lr,

\ ------------------------------------------------------------------------
\ create source registers

  <headers

: reg: ( n1 --- n2 )
  dup create , 1+           \ create register constant
  does>
    @ in{}                  \ last register in register list?
    if
      1 swap << +!> rlist   \ add to list
    else
      !> reg                \ set destination register
    then

  0 8 rep reg: r0 r1 r2  r3  r4  r5  r6  r7
    8 rep reg: r8 r9 r10 r11 r12 r13 r14 r15

  ' r12 alias rp
  ' r13 alias sp
  ' r14 alias lr
  ' r15 alias pc

\ ------------------------------------------------------------------------
\ constants used when creating various conditional opcodes

: <cc> ( n1 --- n2 )
  create dup , 1+
  does> @ !> cc ;

   0 8 rep <cc> EQ NE CS CC MI PL VS VC
     7 rep <cc> HI LS GE LT GT LE AL     drop

\ ------------------------------------------------------------------------
\ not called directly, returned into after each opcode is compiled

: reset
  AL                        \ reset condition to "always"
  off> in{}                 \ not constructing a register list
  off> rcount               \ no destination/intermediate regs yet
  off> delayed              \ not within delay line yet

  ' reset const 'reset

\ ------------------------------------------------------------------------
\ assembler delay line

: asm>
  on> delayed               \ we are now processing a delayed mnemonic
  <a>                       \ get return address into previous mnemonic
  r> !> <a>                 \ get return address of current mnemonic
  'reset >r                 \ force reset after completing previous
  ?dup ?: >r noop ;         \ if there was a previous, return into it

\ -----------------------------------------------------------------------
\ data processing register

\ e.g. and<s><cc> <Rd>, <Rn>, <Rm> {, <shift>}

: (dpr)     ( [ imm ] --- )
  dpth >r                   \ tells us if there is an immediate shift
  cc 28 <<                  \ shift condition code into position
  opcode 21 << or           \ shift opcode int position

  regs dup>r
           $ff and dup 0= abort" Missing Rd"  $0f and 12 << or
  r@  8 >> $ff and dup 0= abort" Missing Rn"  $0f and 16 << or
  r> 16 >> $ff and dup 0= abort" Missing Rm"  $0f and       or

  S 20 << or                \ shift s flag into position
  r>                        \ is there an immediate shift
  if
    swap 7 << or
    tt 5 << or
  then
  , ;                       \ assemble opcode

\ -----------------------------------------------------------------------

: ops:
  dup create , 1+
  does>
    @ !> opcode
    opcode
    case:
      8 opt set-s
      9 opt set-s
      a opt set-s
      b opt set-s
    ;case ;

  0 8 rep ops: and eor sub rsb add adc sbc rsc
    8 rep ops: tst teq cmp cmn orr mov lsl lsr
    5 rep ops: asr ror rrx bic mvn   drop


\ =======================================================================
