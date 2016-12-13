@ rehash.s  - this file will be disappeared as soon as im meta compiling
@ ------------------------------------------------------------------------

@ ------------------------------------------------------------------------
@ i only need this because the gnu assembler is brain dead

  _var_ "voc", voc, 0

@ ------------------------------------------------------------------------
@ store header h1 in vocab in correct hashed thread

@    ( h1 --- )

chain:
  rpush lr
  bl duptor                 @ keep copy of header to rehash
  bl hash                   @ get hash value for this header
  bl voc
  bl plus                   @ point to thread in scratchpad
  bl dup
  bl fetch                  @ fetch header from this thread
  bl rfetch                 @ get header were linking back
  bl ntolink                @ point to its LFA
  bl store                  @ link header to one that was in the thread
  bl rto
  bl swap
  bl store                  @ store our header in the thread
  exit

@ ------------------------------------------------------------------------
@ rehash one complete vocabulary

@    ( voc[] --- )

prehash:
  rpush lr
  bl voc

  bl dup
  bl fetch                  @ fetch chain on first thread of vocab
  bl swap                   @ erase first thread. entire vocabulary
  bl off

  @   ( thread --- )

1:
  bl dup                    @ next header in chain
  bl ntolink
  bl fetch
  bl swap
  bl chain                  @ link this into correct thread of #tmp
  bl qdup                   @ loop till end of chain
  bl zequals
  bl qbranch
  .hword (1b - .) + 1
  exit

@ ------------------------------------------------------------------------

_rehash:
  rpush lr

  movw r0, #:lower16:rehash @ neuter rehash
  movt r0, #:upper16:rehash
  movw r1, #:lower16:noop
  movt r1, #:upper16:noop
  str r1, [r0, #BODY]

  bl voclink                @ point to last vocabulary defined
1:
  bl tobody                 @ fetch pointer to vocs hash buffer
  bl zstoreto
  bl voc

  bl prehash                @ rehash this vocabulary

  bl voc                    @ get address of next header in chain
  bl numthreads
  bl cells_fetch
  bl qdup                   @ loop till no more vocabularies in chain
  bl zequals
  bl qbranch                @ until
  .hword (1b - .) + 1
  exit

@ ========================================================================
