@ fload.s   - interpret a forth source file
@ ------------------------------------------------------------------------

@ ------------------------------------------------------------------------

  _var_ "fd", fd, 0         @ file handle of file being loaded
  _var_ "line#", linenum, 0 @ current line number of file
  _var_ "floads", floads, 0 @ current depth of floading (max = 5)
  _var_ "flsize", flsize, 0 @ file size
  _var_ "fladdr", fladdr, 0 @ address of memory mapping
  _var_ "fl>in", fltoin, 0  @ pointer to current line of file

@ ------------------------------------------------------------------------
@ total number of bytes of all loaded files

  _constant_ "ktotal", ktotal, 0

@ ------------------------------------------------------------------------
@ assert requested file was opend ok

@       ( n1 --- )

colon "?open", qopen
  bl zgreater               @ if fd is not zero
  bl qexit                  @ then exit
  bl cr_                    @ else display file name
  bl hhere
  bl count
  bl type
  bl true                   @ and abort
  bl pabortq
  hstring " Open Error"

@ ------------------------------------------------------------------------
@ get file size from fd

@   ( fd --- zize )

colon "?fl-size", qfs
  cliteral 2                @ SEEK_SET
  cliteral 0                @ offset 0 = start of file
  bl rot                    @ fd
  bl sys_lseek              @ execute lseek system call
  exit

@ ------------------------------------------------------------------------
@ memory map a forth sourcew file

colon "fmmap", fmmap
  bl twotor
  bl dup
  bl qfs
  bl tuck
  cliteral 0
  bl drot
  bl tworto
  bl rot
  cliteral 0
  bl sys_mmap2
  bl swap
  exit

@ ------------------------------------------------------------------------
@ list giving order of varibles to save when nesting floads

pushlist:
  .int tib
  .int numtib
  .int fd
  .int toin
  .int refill
  .int fltoin
  .int fladdr
  .int flsize
  .int linenum
  .int 0

@ ------------------------------------------------------------------------
@ list giving order of variables to restore when unnesting floads

poplist:
  .int linenum
  .int flsize
  .int fladdr
  .int fltoin
  .int refill
  .int toin
  .int fd
  .int numtib
  .int tib
  .int 0

@ ------------------------------------------------------------------------
@ safe current input state when nesting floads

save_state:
  adr r1, pushlist
  movw r2, #:lower16:lsp    @ point to fload stack pointer variable
  movt r2, #:upper16:lsp
  ldr r3, [r2, #BODY]       @ set r3 = fload stack address
0:
  ldr r4, [r1], #4          @ get next item from above list
  cmp r4, #0                @ end of list?
  ittt ne
  ldrne r5, [r4, #BODY]     @ if not then fetch the item it points to
  stmiane r3!, { r5 }       @ push item onto fload stack
  bne 0b

  str r3, [r2, #BODY]       @ update stack pointer
  next

@ ------------------------------------------------------------------------

restore_state:
  adr r1, poplist
  movw r2, #:lower16:lsp    @ point to fload stack pointer variable
  movt r2, #:upper16:lsp
  ldr r3, [r2, #BODY]       @ set r4 = fload stack address
0:
  ldr r4, [r1], #4          @ get address of next variable to restore
  cmp r4, #0                @ end of list?

  ittt ne
  ldmdbne r3!, { r5 }       @ pop item off of fload stack
  strne r5, [r4, #BODY]     @ restore saved variable
  bne 0b

  str r3, [r2, #BODY]       @ update stack pointer
  next

@ ------------------------------------------------------------------------

colon "end-fload", end_fload
  bl flsize
  bl dup
  bl zplusstoreto
  bl ktotal
  bl fladdr
  bl sys_munmap
  bl fd
  bl sys_close
  bl twodrop
  bl restore_state
  bl zdecrto
  bl floads
  exit

@ ------------------------------------------------------------------------

colon "abort-fload", abort_fload
  bl linenum
  bl end_fload
  bl zstoreto
  bl linenum
  exit

@ ------------------------------------------------------------------------

colon "(flrefill)", pflrefill
  bl zincrto                @ count total lines interpreted
  bl linenum
  bl fltoin                 @ set tib = address of next line of file
  bl dup
  bl zstoreto
  bl tib
@ TODO: make this #chars left in file not 1023
  wliteral 1024             @ scan for end of line
  cliteral 0x0a
  bl scan
  bl zequals                @ coder needs a new ENTER key
  bl pabortq
  hstring "Fload Line Too Long"
  bl dup
  bl oneplus                @ point past end of line
  bl swap
  bl fltoin                 @ calculate length of line
  bl minus
  bl zstoreto
  bl numtib                 @ set #tib = length of line
  bl zstoreto               @ point fl>in to next line to interpret
  bl fltoin
  bl zoffto
  bl toin                 @ reset interpret point on new line
  exit

@ ------------------------------------------------------------------------

colon "flrefill", flrefill
  bl fladdr                 @ if file address plus file size
  bl flsize
  bl plus
  bl fltoin                 @ is equal to our file parse address
  bl equals
  bl qbranch
  .hword (1f - .) + 1
  bl end_fload              @ then were done with this file
  exit
1:
  bl pflrefill              @ else refill from this file
  exit

@ ------------------------------------------------------------------------
@ set refill to use floads refill mechanism

@    ( fd map-addr size --- )

colon "fstate", fstate
  push { r0 }
  adr r0, flrefill          @ make fload-refill the refill method
  bl zstoreto
  bl refill
  bl zstoreto               @ remember size of file mapping
  bl flsize
  bl dup
  bl zstoreto               @ set address of mapping
  bl fladdr
  bl zstoreto
  bl fltoin
  bl zstoreto
  bl fd                     @ save file descriptor
  bl zincrto
  bl floads
  bl zoffto                 @ reset current line numbr
  bl linenum
  exit

@ ------------------------------------------------------------------------

colon "?fdepth", qfdepth
  bl floads                 @ nesting floads deeper than 2 is dumb
  cliteral 5
  bl equals
  bl pabortq
  hstring "Floads Nested Too Deep"
  exit

@ ------------------------------------------------------------------------

colon "(fload)", pfload
  bl sys_open3              @ attempt to open specified file
  bl dup                    @ abort if not opened
  bl qopen
  bl dup
  cliteral 2                @ map private
  cliteral 3                @ prot read
  bl fmmap                  @ memory map the file
  bl save_state             @ save state of previous fload if any
  bl fstate                 @ set state to floading
  bl refill                 @ do initial refill for fload
  exit

@ ------------------------------------------------------------------------

colon "fload", fload
  bl qfdepth                @ assert floads not nested too deep
  cliteral 0                @ file permissions and flags
  bl dup
  bl bl_                    @ parse in file name
  bl word_
  bl hhere                  @ make it ascii z
  bl count
  bl s2z
  bl pfload
  exit

@ ========================================================================
