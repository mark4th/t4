\ gpio.f   - cubieboard gpio driver
\ ------------------------------------------------------------------------

\ Prior to any GPIO access you must call gpio-init.  This memory maps
\ the registers so that they can be accessed by your code.  Once mapped
\ you can read and write GPIO registers as described below.

\ Most access should be done via a working copy of a specified register.
\ First you would read the register into the working copy, then modify
\ the working copy and then write it back out to the register.  This
\ allows you to modify multiple configurations within a single register
\ and then write them out to the physical register in one write.  This
\ also allows you to modify only those bits within the register that need
\ to be modified, leaving the rest untouched.

\ I have supplied a set of words which will read registers in to the
\ work register and another set to write the work register back out.

\ in some instances a direct access on the register is desired.  For
\ example, when a read/modify/write is not necessary such as when you
\ know the exact value you need to write to "all bits" of the register.
\ To this end I have supplied another set of words which simply return
\ the address of the specified register.  You can then @ or ! here as
\ required.

\ this extension currently does not support interrupts on gpio pins and
\ does not configure any of the multiplexed peripheral devices.

\ ------------------------------------------------------------------------

  <headers

  $1c20800 const GPIO       \ start of mem page containing gpio registers
  0 var gpio_map            \ address where gpio is memory mapped to
  0 var work                \ working copy of a register

\ ------------------------------------------------------------------------
\ so we can memory map the registers...

  create /dev/mem
    ,' /dev/mem' 0 c, align,

\ ------------------------------------------------------------------------
\ returns 0 on success

  headers>

: gpio-init    ( --- f1 )
   2 /dev/mem <open> dup    \ open /dev/mem
   0< ?exit >r              \ exit with -1 on failure

   GPIO 12 u>>              \ addr of gpio registers / page size
   r@                       \ fd
   1                        \ map shared
   3                        \ prot rw
   8192                     \ two times page size
   0                        \ address to place mapping at

   <mmap2>                  \ ( --- a1 )
   r> <close>               \ close /dev/mem
   dup -1 <>                \ was mapping successfull?
   if
     GPIO $fff and          \ gpio register offset within mapped page
     + !> gpio_map
     0                      \ success
   then ;

\ ------------------------------------------------------------------------
\ read specifid register to work, write work to specified register

  <headers

: read      ( reg-offset --- ) gpio_map + @ !> work ;
: write     ( reg-offset --- ) gpio_map + work swap ! ;

\ ------------------------------------------------------------------------
\ create a register reader, create a register writer

: (r@:)    ( n1 --- n2 ) dup create , cell+ does> @ read ;
: (r!:)    ( n1 --- n2 ) dup create , cell+ does> @ write ;

\ ------------------------------------------------------------------------
\ create a register direct access (not through work)

: (r:)     ( n1 --- n2 ) dup create , cell+
  does>    ( --- a1 )
    @ gpio_map + ;

\ ------------------------------------------------------------------------
\ create a block of 9 read/write/direct register accesses

: r@:    ( n1 --- n2 )  9 rep (r@:) ;
: r!:    ( n1 --- n2 )  9 rep (r!:) ;
: r:     ( n1 --- n2 )  9 rep (r:) ;

\ ------------------------------------------------------------------------
\ create register readers/writers for every gpio register

  headers>

   0 r@: PACFG0@ PACFG1@ PACFG2@ PACFG3@ PADAT@ PADRV0@ PADRV1@ PAPULL0@ PAPULL1@
     r@: PBCFG0@ PBCFG1@ PBCFG2@ PBCFG3@ PBDAT@ PBDRV0@ PBDRV1@ PBPULL0@ PBPULL1@
     r@: PCCFG0@ PCCFG1@ PCCFG2@ PCCFG3@ PCDAT@ PCDRV0@ PCDRV1@ PCPULL0@ PCPULL1@
     r@: PDCFG0@ PDCFG1@ PDCFG2@ PDCFG3@ PDDAT@ PDDRV0@ PDDRV1@ PDPULL0@ PDPULL1@
     r@: PECFG0@ PECFG1@ PECFG2@ PECFG3@ PEDAT@ PEDRV0@ PEDRV1@ PEPULL0@ PEPULL1@
     r@: PFCFG0@ PFCFG1@ PFCFG2@ PFCFG3@ PFDAT@ PFDRV0@ PFDRV1@ PFPULL0@ PFPULL1@
     r@: PGCFG0@ PGCFG1@ PGCFG2@ PGCFG3@ PGDAT@ PGDRV0@ PGDRV1@ PGPULL0@ PGPULL1@
     r@: PHCFG0@ PHCFG1@ PHCFG2@ PHCFG3@ PHDAT@ PHDRV0@ PHDRV1@ PHPULL0@ PHPULL1@
     r@: PICFG0@ PICFG1@ PICFG2@ PICFG3@ PIDAT@ PIDRV0@ PIDRV1@ PIPULL0@ PIPULL1@

   0 r!: PACFG0! PACFG1! PACFG2! PACFG3! PADAT! PADRV0! PADRV1! PAPULL0! PAPULL1!
     r!: PBCFG0! PBCFG1! PBCFG2! PBCFG3! PBDAT! PBDRV0! PBDRV1! PBPULL0! PBPULL1!
     r!: PCCFG0! PCCFG1! PCCFG2! PCCFG3! PCDAT! PCDRV0! PCDRV1! PCPULL0! PCPULL1!
     r!: PDCFG0! PDCFG1! PDCFG2! PDCFG3! PDDAT! PDDRV0! PDDRV1! PDPULL0! PDPULL1!
     r!: PECFG0! PECFG1! PECFG2! PECFG3! PEDAT! PEDRV0! PEDRV1! PEPULL0! PEPULL1!
     r!: PFCFG0! PFCFG1! PFCFG2! PFCFG3! PFDAT! PFDRV0! PFDRV1! PFPULL0! PFPULL1!
     r!: PGCFG0! PGCFG1! PGCFG2! PGCFG3! PGDAT! PGDRV0! PGDRV1! PGPULL0! PGPULL1!
     r!: PHCFG0! PHCFG1! PHCFG2! PHCFG3! PHDAT! PHDRV0! PHDRV1! PHPULL0! PHPULL1!
     r!: PICFG0! PICFG1! PICFG2! PICFG3! PIDAT! PIDRV0! PIDRV1! PIPULL0! PIPULL1!

  2drop

\ ------------------------------------------------------------------------
\ direct access, not through work

   0 r: PACFG0 PACFG1 PACFG2 PACFG3 PADAT PADRV0 PADRV1 PAPULL0 PAPULL1
     r: PBCFG0 PBCFG1 PBCFG2 PBCFG3 PBDAT PBDRV0 PBDRV1 PBPULL0 PBPULL1
     r: PCCFG0 PCCFG1 PCCFG2 PCCFG3 PCDAT PCDRV0 PCDRV1 PCPULL0 PCPULL1
     r: PDCFG0 PDCFG1 PDCFG2 PDCFG3 PDDAT PDDRV0 PDDRV1 PDPULL0 PDPULL1
     r: PECFG0 PECFG1 PECFG2 PECFG3 PEDAT PEDRV0 PEDRV1 PEPULL0 PEPULL1
     r: PFCFG0 PFCFG1 PFCFG2 PFCFG3 PFDAT PFDRV0 PFDRV1 PFPULL0 PFPULL1
     r: PGCFG0 PGCFG1 PGCFG2 PGCFG3 PGDAT PGDRV0 PGDRV1 PGPULL0 PGPULL1
     r: PHCFG0 PHCFG1 PHCFG2 PHCFG3 PHDAT PHDRV0 PHDRV1 PHPULL0 PHPULL1
     r: PICFG0 PICFG1 PICFG2 PICFG3 PIDAT PIDRV0 PIDRV1 PIPULL0 PIPULL1

  drop

\ ------------------------------------------------------------------------

  <headers

: select     ( sel gpio# --- )
  2 <<                      \ 4 bits per pin in cfg register
  dup>r <<                  \ shift select up to position
  work                      \ get copy of work
  $0f r> << not and         \ mask out pin cfg for selected pin
  or !> work ;              \ write new selection to work

\ ------------------------------------------------------------------------
\ create a gpio pin configuration selector

: (select:)  ( gpio# sel --- )
  2dup create , , 1+
  does>
    dup @ swap cell+
        @ swap select ;

: select: rep (select:) ;

\ ------------------------------------------------------------------------

  headers>

  \ pin# dir count

  %000 $00 4 select: 00.in 01.in 02.in 03.in
           4 select: 04.in 05.in 06.in 07.in 2drop
  %000 $00 4 select: 08.in 09.in 10.in 11.in
           4 select: 12.in 13.in 14.in 15.in 2drop
  %000 $00 4 select: 16.in 17.in 18.in 19.in
           4 select: 20.in 21.in 22.in 23.in 2drop

  %001 $00 4 select: 00.out 01.out 02.out 03.out
           4 select: 04.out 05.out 06.out 07.out 2drop
  %001 $00 4 select: 08.out 09.out 10.out 11.out
           4 select: 12.out 13.out 14.out 15.out 2drop
  %001 $00 4 select: 16.out 17.out 18.out 19.out
           4 select: 20.out 21.out 22.out 23.out 2drop

\ ------------------------------------------------------------------------

\ : my-gpio-config
\    gpio-init              \ initialize for gpio access
\    0<> abort" bad mojo error"
\    PACFG0@                \ copy port a config reg 0 to work register
\    00.in 01.in 02.in      \ modify config within work register
\    04.out 05.out
\    PACFG0!                \ write work register back out to port a cfg 0
\
\    \ set the state of the output pins on port a ...
\    some-value PADAT !     \ write some value out to port a data register
\    \ read the state of the input pins on port a...
\    PADAT @ !> good-stuff

\ ------------------------------------------------------------------------

  behead

\ ========================================================================
