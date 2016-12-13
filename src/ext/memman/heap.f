\ heap.f    - memory manager heap creation/destruction
\ ------------------------------------------------------------------------

  .( heap.f )

\ ------------------------------------------------------------------------
\ calculate space required for buffer of mem-blks for a new heap

  #BLOCKS mem-blk * MEM-MAP 2* + const BLK-MAP-SIZE

\ ------------------------------------------------------------------------
\ fetch new heap structure from array of heap structures

: new-heap@   ( --- heap t | f )
  hcache head@              \ any heap structures we can recycle?
  dup 0= ?exit drop         \ if not return false
  hcache <head              \ if so detach one
  dup heap erase true ;     \ erase it and return success

\ ------------------------------------------------------------------------
\ all our ducks are in a row. put the ducks in a heap structure

: (creat-heap)  ( psize pool bsize blks heap --- )
  >r                        \ save address of heap structure

  dup r@ h.mapa! MEM-MAP +  \ put free mem-map array in blocks buffer
  dup r@ h.mapf! MEM-MAP +  \ put allocated mem-map array in blocks buffer

  r@ h.blocks !             \ set address of mem-blk cache
  r@ h.bsize !              \ save size of mem-blk buffer

  ( psize pool --- )

  2dup

  r@ h.pool !               \ store size of and address of pool in heap
  r@ h.psize !              \ remember size of this mapping

  swap r@ describe          \ create descriptor for entire heap pool

  ( mem-blk --- )

  r@ h.mapf@ swap add-free  \ add single mem-blk descriptor for entire
  r> heaps >head ;          \ heap pool. add heap struct to list of heaps

\ ------------------------------------------------------------------------
\ memmap buffers for and initialize a new heap

: creat-heap    ( size --- f1 )
  HEAP-SIZE max             \ heap-size is smallest heap size allowed

  dup @map                  \ allocate the heap pool
  if                        \ oom?
    drop false exit
  then

  ( size pool --- )

  BLK-MAP-SIZE dup @map     \ allocate buffer for mem-blks etc
  if
    3drop <munmap>          \ oopts
    drop false exit
  then

  ( psize pool bsize blks --- )

  new-heap@ 0=              \ get a new heap structure if we can
  if                        \ if we cant return failure
    <munmap> 2drop          \ return mem-blk buffer to BIOS
    <munmap> 2drop          \ return pool to BIOS
    false exit
  then

  (creat-heap) true ;       \ ducks heap !

\ ------------------------------------------------------------------------
\ allocate first heap or die

: first-heap   ( --- )
  defers default
  HEAP-SIZE creat-heap ?exit
  ." Out Of Memory" cr bye ;

\ -----------------------------------------------------------------------
\ remove heap structure from list of used, add to list of unused heaps

: discard-heap  ( heap --- )
  <list                     \ remove heap struct from list of used heaps
  hcache >head ;            \ add to list of cached heap structures

\ -----------------------------------------------------------------------
\ return heap pool to BIOS (linux :)

: destroy-heap   ( heap --- )
  dup>r                     \ save address of heap

  h.bsize @ r@ h.mapa@      \ deallocate mem-blk buffer
  <munmap>

  r@ h.psize @ r@ h.pool @  \ deallocate heap pool buffer
  <munmap> 2drop            \ discard <munmap> results.

  r> discard-heap ;         \ attach heap struct to list of cached

\ ========================================================================
