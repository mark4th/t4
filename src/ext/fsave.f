\ fsave.f       - saves out elf executable
\ ------------------------------------------------------------------------

  .( loading fsave.f ) cr

\ ------------------------------------------------------------------------

  compiler definitions

  <headers

\ ------------------------------------------------------------------------
\ elf header structure

struct: elf_header
  16 db e_ident             \ $7f $45 $4c $46 etc etc
   1 dw e_type              \ 2 = executable
   1 dw e_machine           \ 3 = X86   20 = ppc
   1 dd e_version           \ 1 = current
   1 dd e_entry             \ entry point of process (origin)
   1 dd e_phoff             \ offset to start of program headers
   1 dd e_shoff             \ offset to start of section headers
   1 dd e_flags             \
   1 dw e_ehsize            \ byte size of elf header
   1 dw e_phentsize         \ byte size of program header
   1 dw e_phnum             \ number of program headers
   1 dw e_shentsize         \ size of section header
   1 dw e_shnum             \ number of section header entreis
   1 dw e_shstrndx          \ index to string sections section header
;struct

\ ------------------------------------------------------------------------
\ e_type

  0 const ET_NONE           \ no file type
  1 const ET_REL            \ relocatble file
  2 const ET_EXEC           \ executable file
  3 const ET_DYN            \ shared object
  4 const ET_CORE           \ ok so why am i including this one again?

\ ------------------------------------------------------------------------
\ e_machine

  3 const EM_386            \ intel
  8 const EM_MIPS           \ todo!
 20 const EM_PPC            \ not in my copy of the std but i trust tathi
 40 const EM_ARM            \ discovered via readelf -a

\ ------------------------------------------------------------------------
\ arm specific e_flags

  $05000000 const EF_ARM_ABIMASK
  $00800000 const EF_ARM_BE8
  $00000400 const EF_ARM_ABI_FLOAT_HARD
  $00000200 const EF_ARM_ABI_FLOAT_SOFT

  EF_ARM_ABIMASK 2 or const EF_FLAGS

\ ------------------------------------------------------------------------
\ structure of a program header

struct: prg_header
   1 dd p_type
   1 dd p_offset
   1 dd p_vaddr
   1 dd p_paddr
   1 dd p_filesz
   1 dd p_memsz
   1 dd p_flags
   1 dd p_align
;struct

\ ------------------------------------------------------------------------

  0 const PT_NULL
  1 const PT_LOAD
  2 const PT_DYNAMIC
  3 const PT_INTERP
  4 const PT_NOTE
  5 const PT_SHLIB
  6 const PT_PHDR

\ ------------------------------------------------------------------------

  1 const PF_X
  2 const PF_W
  4 const PF_R

  PF_X PF_R or const PF_RX
  PF_R PF_W or const PF_RW

\ ------------------------------------------------------------------------
\ section header structure

struct: sec_header
  1 dd sh_name              \ offset in $ table to name
  1 dd sh_type              \ 1 = progbits
  1 dd sh_flags             \ 6 = AX
  1 dd sh_addr              \ where this section lives
  1 dd sh_offset            \ file offset to start of section
  1 dd sh_size              \ how big is the section (deja vu)
  1 dd sh_link
  1 dd sh_info
  1 dd sh_addralign
  1 dd sh_entsize
;struct

\ ------------------------------------------------------------------------
\ sh_type

  0 const SHT_NULL
  1 const SHT_PROGBITS
  2 const SHT_SYMTAB
  3 const SHT_STRTAB
  4 const SHT_RELA
  5 const SHT_HASH
  6 const SHT_DYNAMIC
  7 const SHT_NOTE
  8 const SHT_NOBITS
  9 const SHT_REL
 10 const SHT_SHLIB
 11 const SHT_DYNSYM

\ ------------------------------------------------------------------------
\ sh_flags

  1 const SHF_WRITE
  2 const SHF_ALLOC
  4 const SHF_EXEC

  SHF_ALLOC SHF_EXEC  or const SHF_AX
  SHF_ALLOC SHF_WRITE or const SHF_WA

\ ------------------------------------------------------------------------
\ string section

\ note (,') and ,' are identical except the latter cell aligns the
\ dictionary pointer after each string.  the former does not

create $table
  0 c,                      \ 0 index is empty string.
  (,') .text' 0 c,          \ 1
  (,') .bss' 0 c,           \ 7
  (,') .shstrtab' 0 c,      \ 12

  here $table -
  align,
  const st_len

\ ------------------------------------------------------------------------
\ decompiler needs this too

  origin $fffff000 and const elf0
  origin elf0 - const headsize

\ ------------------------------------------------------------------------
\ used to calculate bss size

  $00100000 const 1MEG      \ this minus .text size = .bss size

\ ------------------------------------------------------------------------

  1 const ELFCLASS32        \ 32 bit class
  2 const ELFCLASS64        \ todo

  1 const ELFDATA2LSB
  2 const ELFDATA2MSB

\ ------------------------------------------------------------------------
\ constants for things that change between ports.

    \ ppc Linux:    enc = 1   abi = 2
    \ x86 Linux:    enc = 1   abi = 1
    \ x86 FreeBSD:  enc = 1   abi = 1

  ELFCLASS32  const CLS     \ 32 bit
  ELFDATA2LSB const ENC     \ data encoding (endianness) (big endian)

  1 const VER               \ current version
  0 const ABI               \ ABI (SysV)    (not in elf std?)

\ ------------------------------------------------------------------------
\ elf identity

create identity
  $7f c, $45 c, $4c c, $46 c, CLS c, ENC c, VER c, ABI c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,

\ ------------------------------------------------------------------------

  0 var ss-addr       \ address where string section will be placed
  0 var sh-addr       \ address where section headers will be placed
  0 var BSS_SIZE      \ depends on size of .text

\ ------------------------------------------------------------------------
\ initilize elf headers at start of process address space

: ehdr!         ( --- )
  elf0 identity over e_ident 16 cmove

  ET_EXEC        over e_type      w!
  EM_ARM         over e_machine   w!
  1              over e_version    !
  origin         over e_entry      !
  elf_header     over e_phoff      !
  sh-addr elf0 - over e_shoff      !
  EF_FLAGS       over e_flags      !
  elf_header     over e_ehsize    w!
  prg_header     over e_phentsize w!
  2              over e_phnum     w!
  sec_header     over e_shentsize w!
  4              over e_shnum     w!
  3              swap e_shstrndx  w! ;

\ ------------------------------------------------------------------------
\ initialize program headers

: phdr!         ( --- )
  elf0 elf_header + dup     \ get address of program headers
  dup prg_header 2* erase   \ start fresh

  \ .text

  PT_LOAD        over p_type   !
  0              over p_offset !
  elf0           over p_vaddr  !
  elf0           over p_paddr  !
  ss-addr elf0 - over p_filesz !
  ss-addr elf0 - over p_memsz  !
  PF_RX          over p_flags  !
  $1000          over p_align  !

  \ .bss

  prg_header +

  PT_LOAD        over p_type   !
  ss-addr elf0 - over p_offset !
  ss-addr        over p_vaddr  !
  ss-addr        over p_paddr  !
  0              over p_filesz !
  BSS_SIZE       over p_memsz  !
  PF_RW          over p_flags  !
  $1000          swap p_align  ! ;

\ ------------------------------------------------------------------------
\ write string section

: $sec!         ( --- )
  $table ss-addr st_len cmove ;

\ ------------------------------------------------------------------------
\ write data into one section header

: (shdr!)       ( ... struct --- struct' )
  tuck sh_entsize   !       \ length of section header entry
  tuck sh_addralign !       \ alignment for section
  tuck sh_info      !
  tuck sh_link      !
  tuck sh_size      !       \ size ofsection within file
  tuck sh_offset    !       \ file offset to start of section
  tuck sh_addr      !       \ memory address of section
  tuck sh_flags     !
  tuck sh_type      !
  tuck sh_name      !       \ offset into string table
  sec_header + ;            \ point to next secton header

\ ------------------------------------------------------------------------
\ write all section headers

: shdr!        ( --- )
  sh-addr                   \ get address for section headers
  dup sec_header erase      \ first section header is always null

  \ .text

  sec_header + >r
  1 SHT_PROGBITS SHF_AX origin
  headsize hhere origin -
  0 0 16 0 r> (shdr!)

  \ .bss

  >r
  7 SHT_NOBITS SHF_WA ss-addr
  ss-addr elf0 - BSS_SIZE
  0 0 4 0 r> (shdr!)

  \ .shstrtab

  >r
  12 SHT_STRTAB 0 0
  ss-addr elf0 - st_len
  0 0 1 0 r> (shdr!)

  drop ;

\ ------------------------------------------------------------------------
\ save elf file image in memory to file

: ((fsave))
  hp dup>r $800 + !> hp     \ 'bl word' below uses hhere :/

  \777                      \ rwxrwxrwx
  \1101                     \ O_TRUNC O_CREAT O_WRONLY

  bl word                   \ parse filename from input
  hhere count s>z           \ convert name to ascii z
  <open3>                   \ create new file

  r> !> hp

  dup -1 <>                 \ created?
  if
    >r                      \ save fd to return stack
    off> >in off> #tib      \ so targets tib is empty on entry
    sh-addr                 \ calculate length of file...
    sec_header 4 * +        \ i.e. address of end of section headers
    elf0 -                  \ minus address of start of process
    elf0 r@ <write>         \ start address of file data
    <close>                 \ write/close file
  else
    ." fsave failed!" cr
  then
  bye ;

\ ------------------------------------------------------------------------
\ save out extended kernel - headers may or may not have been stripped

: (fsave)
  ['] query is refill       \ fsaving or turnkeying from an fload leaves
  off> floads               \ these in a wrong state for the target
  hhere dup !> ss-addr      \ set string section and section headers
  st_len +  !> sh-addr      \ address

  1MEG ss-addr elf0 - - !> BSS_SIZE

  ehdr!                     \ write elf headers into memory
  phdr!                     \ write program headers into memory
  $sec!                     \ write string table into memory
  shdr!                     \ write section headers into memory

  ((fsave)) ;               \ save out memory :)

\ ------------------------------------------------------------------------

  headers>

  ' elf0 alias elf0          \ decompiler uses this value

\ ------------------------------------------------------------------------
\ pack all headers to 'here' and save out executable

: fsave
  pack (fsave) ;            \ pack headers onto end of list space

\ ------------------------------------------------------------------------
\ same as fsave but does not pack headers onto end of list space

: turnkey
  here $3ff + -400 and !> hp \ obliterate all of head space
  on> turnkeyd              \ target doesn't try to relocate non existent
  (fsave) ;                 \   headers when it loads in !!!

\ ------------------------------------------------------------------------

  behead

\ ========================================================================
