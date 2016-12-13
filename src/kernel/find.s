@ find.s
@ ------------------------------------------------------------------------

@ ------------------------------------------------------------------------
@ compute hash value of nfa string

@   ( a1 --- thread )

code "hash", hash
  ldrb r1, [r0], #1       @ r1 = name length
  and r1, #LEXMASK        @ mask out lex bits (immediate etc)
  ldrb r2, [r0], #1       @ fetch first char of word name
  adds r2, r2             @ char 1 times 2
  cmp r1, #1              @ is there only one character in name?
  ittt ne
  ldrbne r3, [r0]         @ if not fetch second char
  addne r2, r3            @ add it to first char
  addne r2, r2            @ multiply result by 2
  adds r0, r1, r2         @ add in length
  and r0, #0x3f           @ mask the result to 0-63
  lsls r0, #2             @ cells
  next

@ ------------------------------------------------------------------------
@ search one thread of vocab for word whose name is at hhere

@     ( thread --- cfa t | f )

code "(find)", pfind
  cbz r0, 2f                @ is specified thread empty?

  adr r2, hp                @ point r2 to 'hhere'
  ldr r2, [r2, #BODY]       @ r2 = name string of word to search for

  ldrb r1, [r2], #1         @ r1 = length of word name to search for
0:
  ldrb r3, [r0]             @ r3 = length of next word in specified thread
  and r8, r3, #LEXMASK      @ mask out lex bits from length byte
  cmp r8, r1                @ are lengths equal?
  beq 3f
1:
  ldr r0, [r0, #-4]         @ no.. scan back one word in thread
  cmp r0, #0                @ at end of thread?
  bne 0b
2:
  next                      @ not found. return r0 = false

  @ lengths match - compare strings...

3:
  adds r4, r0, #1           @ r4 = string in dictionary thread
  movs r5, r2               @ r5 = string to compare with
4:
  ldrb r6, [r4], #1         @ fetch next byte from both strings
  ldrb r7, [r5], #1
  cmp r6, r7                @ are they the same?
  bne 1b                    @ if not loop back to get next word from thread
  subs r8, #1               @ length--
  bne 4b                    @ till at end of string

  @ strings match - we found the word

  and r8, r3, #LEXMASK      @ add masked word length to nfa
  add r0, r8
  adds r0, #4               @ also count count byte as part of length
  bic r0, r0, #3            @ and align to cell
  ldr r1, [r0]              @ fetch cfa of word we found from header
  push { r1 }               @ return the cfa

  tst r3, #0x80             @ is this an immediate word?
  ite ne
  movne r0, #1              @ if not f1 = 1
  mvneq r0, #0              @ if so f1 = -1
  next

@ ------------------------------------------------------------------------
@ search all in-context vocs for word whose name is at hhere

@   ( --- cfa f1 | false )

colon "find", find
  bl hhere                @ compute hash (thread) of word name at hhere
  bl hash
  bl tocontext
  cliteral 16
  bl swap

  bl pdo                  @ for each vocabulary in context do...
  .hword (2f - .) + 1
0:
  bl dup                  @ keep address of vocab
  bl i                    @ index to next item on context stack
  bl cells_fetch
  bl tobody               @ point to the body of the vocab not the cfa
  bl pluck                @ index to correct thread within this voc
  bl plus
  bl fetch
  bl pfind                @ search thread for specified word name

  bl qdup
  bl qbranch              @ did we find it?
  .hword (1f - .) + 1

  @ yes - word was found

  bl undo                 @ discard loop index
  bl twoswap
  bl twodrop
  exit

1:
  bl ploop
  .hword (0b - .) + 1

2:
  bl twodrop
  bl false
  exit

@ ========================================================================
