@ header.s    - forth word header creating and scanning (not search)
@ ------------------------------------------------------------------------

@ ------------------------------------------------------------------------

  _var_ "dp",     dp, _headers      @ defined in linker script
  _var_ "hp",     hp, 0
  _var_ "old_dp", old_dp _headers   @ lower bounds to clear icache

  _alias_ "here", dp, here
  _alias_ "hhere", hp, hhere

@ ------------------------------------------------------------------------
@ mask lex bits from nfa length byte

@     ( c1 --- c2 )

code "lexmask", lexmask
  and r0, r0, #LEXMASK
  next

@ ------------------------------------------------------------------------
@ given cfa compute body address

@     ( a1 --- a2 )

code ">body", tobody
  adds r0, r0, #BODY
  next

@ ------------------------------------------------------------------------
@ given body address compute cfa

@     ( a1 --- a2 )

code "body>", bodyto
  subs r0, r0, #BODY
  next

@ ------------------------------------------------------------------------
@ given nfa compute lfa

@     ( a1 --- a2 )

  _alias_ "n>link", cellminus, ntolink

@ ------------------------------------------------------------------------
@ given lfa compute nfa

@     ( a1 --- a2 )

  _alias_ "l>name", cellplus, ltoname

@ ------------------------------------------------------------------------
@ given cfa compute nfa

@     ( a1 --- a2 )

code ">name", toname
  ldr r0, [r0, #-4]
  next

@ ------------------------------------------------------------------------
@ given nfa compute cfa

@     ( a1 --- a2)

colon "name>", nameto
  bl count                  @ get address and length of string
  bl lexmask                @ mask out lex bits from count byte
  bl plus                   @ add count byte to address
  bl align                  @ align to cell boundry
  bl fetch                  @ fetch address of cfa from header
  exit

@ ------------------------------------------------------------------------

@     ( a1 n1 --- )

colon "(head,)", phead
  bl alignc                 @ make sure here is balign 4
  bl hhere                  @ keep current head space address
  bl tor                    @ save lfa (see below **)
  cliteral 0                @ compile a dummy lfa into head space
  bl hcomma
  bl hhere                  @ this is the new headers nfa
  bl dup
  bl zstoreto               @ save address of most recent words nfa
  bl last
  bl dup
  bl comma                  @ comma address of nfa into cfa -4

  bl strstore               @ this is not allotted yet... see below

  bl current                @ get current vocabulary
  bl tobody
  bl hhere                  @ compute thread for new word
  bl hash
  bl plus
  bl dup                    @ remember address of vocabulary thread
  bl zstoreto
  bl thread                 @ we are attaching the new header to

  bl fetch                  @ fetch address of previous header on this thread
  bl rto
  bl store                  @ store it in our lfa (see above **)

  bl hhere                  @ now allocate the nfa in head space
  bl cfetch
  bl oneplus
  bl align
  bl hallot
  bl here                   @ compile pointer to cfa into header
  bl hcomma
  exit

@ ------------------------------------------------------------------------

colon "head,", headcomma
  bl bl_                    @ parse the next space delimited token out of
  bl parseword              @ the input stream (the name for the new word)
  bl phead                  @ create a new header with this name
  exit

@ ------------------------------------------------------------------------
@ reveal the most recently created word and flush the icache for it

colon "reveal", reveal
  bl last                   @ get nfa of word we just created
  bl thread                 @ which voc thread should we add it to
  bl store                  @ add it to thread - make it visisble

  @ we just wrote new data (code) into memory. we now need to invalidate
  @ the instruction cache for this memory so that if we try to execute
  @ this new word the cpu will see what we just wrote

  push { r0 }               @ point r0 at where new word starts in code
  adr r2, old_dp
  ldr r0, [r2, #BODY]
  adr r1, dp                @ point where new word ends in code
  ldr r1, [r1, #BODY]
  str r1, [r2, #BODY]       @ new end = next start
  movw r7, #0x02
  movt r7, #0x0f
  movs r2, #0
  swi 0
  pop { r0 }
  exit

@ ========================================================================
