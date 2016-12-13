@ number.s      - convert parsed in string to a number in specified base
@ ------------------------------------------------------------------------

  _var_ "base", base, 10    @ default radix is decimal

@ ------------------------------------------------------------------------
@ see if char c1 is a valid digit in specified number base

@     ( base c1 --- n1 t | f )

digit:
  pop { r1 }                @ get radix in r1
  subs r0, #'0'             @ de-asciify the character
  blo 2f                    @ if char was < '0' then not a digit
  cmp r0, #9                @ else if char < '9' then digit ok
  bls 1f
  cmp r0, #17               @ if char < 'A' then not a digit
  blo 2f
  subs r0, #7
1:
  cmp r0, r1                @ if char >= radix then not a digit
  bhs 2f
  push { r0 }               @ char is a digit, retutn the value of the
  mvn r0, #0                @ char and a true result
  next
2:                          @ char is not a digit
  movs r0, #0               @ return false result
  next

@ ------------------------------------------------------------------------

@     ( a1 n1 radix --- n1 t | f )

pnumber:
  rpush lr
  cliteral 0                @ result = 0
  bl twoswap                @ ( radix result a1 n1 --- )
  bl bounds                 @ get a1 a2 of string to convert
  bl pdo
  .hword (2f - .) + 1
0:                          @ ( radix result --- )
  bl over
  bl i                      @ get next char of string to convert
  bl cfetch
  bl upc                    @ make the char upper case
  bl digit                  @ is it a valid digit?
  bl not
  bl qbranch
  .hword (1f - .) + 1
  bl threedrop              @ if not clean up
  bl undo                   @ abort the loop
  bl false                  @ and return failure
  exit
1:
  bl swap                   @ ( radix n1 result --- )
  bl pluck                  @ multiply result by radix
  bl star                   @ and add it value of digit n1
  bl plus
  bl ploop
  .hword (0b - .) + 1
2:
  bl nip                    @ ( --- result true )
  bl true
  exit

@ ------------------------------------------------------------------------

@     ( sign a1 n1 radix --- n1 t | f )

pnum:
  rpush lr
  bl pnumber              @ attempt conversion of string to number
  bl dup                  @ if we did not succeed returl false
  bl not
  bl qexit
  bl tor                  @ otherwise save true flag
  bl swap                 @ ( n1 sign --- n1 )
  bl qnegate              @ conditionally negate the result
  bl rto                  @ return result and true flag
  exit

@ ------------------------------------------------------------------------
@ return character number 'c'

@     ( sign a1 n1 --- n1 t | f )

chrnum:
  rpush lr
  bl over                 @ must have the closing tick
  bl twoplus
  bl cfetch
  cliteral 0x27
  bl equals
  bl not
  bl pabortq              @ or else
  hstring "Missing '"
  bl drop                 @ discard string length
  bl oneplus              @ fetch the charcater from between the ticks
  bl cfetch
  bl swap                 @ conditionally negate the char
  bl qnegate
  bl true                 @ reeturn result and true
  exit

@ ------------------------------------------------------------------------

@     ( sign a1 n1 --- n1 t | f )

binnum:
  rpush lr
  cliteral 1              @ scan past the % prefix
  bl sstring
  cliteral 2              @ convert string to number using binary as
  bl pnum                 @ the radix
  exit

@ ------------------------------------------------------------------------

@     ( sign a1 n1 --- n1 t | f )

octnum:
  rpush lr
  cliteral 1              @ scan past the \ prefix
  bl sstring
  cliteral 8              @ convert the string to a number using octal as
  bl pnum                 @ the radix
  exit

@ ------------------------------------------------------------------------

@     ( sign a1 n1 --- n1 t | f )

hexnum:
  rpush lr
  cliteral 1              @ scan past the $ prefix
  bl sstring
  cliteral 16             @ convert the string to a number using hex as
  bl pnum                 @ the radix
  exit

@ ------------------------------------------------------------------------

defnum:
  rpush lr
  bl base
  bl pnum
  exit

@ ------------------------------------------------------------------------
@ see if string has a '-' prefix

@     ( a1 n1 --- sign a1' n1' )

qnegative:
  rpush lr
  bl over                 @ fetch first character of the string
  bl cfetch
  cliteral '-'            @ compare it with a '-' character
  bl equals
  bl drot                 @ save result for later but...
  bl pluck                @ make a copy of the result to test here too
  bl qbranch
  .hword (1f - .) + 1     @ if the number did have a '-' prefix then
  cliteral 1              @ skip past this prefix
  bl sstring
1:
  exit

@ ------------------------------------------------------------------------
@ attempt to convert parsed in input to a number (input is at address a1)

@     ( a1 --- n1 t | f )

colon "number", number
  bl count                @ get address and length of string
  bl qnegative            @ test if input specifies a negative value
  bl over                 @ get first character of number string
  bl cfetch               @ to see if it is a radix prefix
  bl docase
  .int 1f                 @ case exit point
  .int defnum             @ defalt when no radix prefix specified
  .int 4                  @ case option count
  .int '$', hexnum
  .int '\\', octnum
  .int '%', binnum
  .int 0x27, chrnum
1:
  exit

@ ========================================================================
