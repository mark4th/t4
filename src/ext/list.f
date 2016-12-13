\ list.f        - linked list words
\ ------------------------------------------------------------------------

  .( loading list.f ) cr

\ ------------------------------------------------------------------------

  vocabulary lists lists definitions

\ ------------------------------------------------------------------------
\ linked list structure

\ this structure simply points to the head and tail nodes of a list

struct: list
  1 dd l.head               \ pointer to head node of list
  1 dd l.tail               \ pointer to tail node of list
;struct

\ ------------------------------------------------------------------------
\ linked list node structure.

struct: node
  1 dd n.next               \ pointer to next node in list
  1 dd n.prev               \ pointer to previous node in list
  1 dd n.root               \ pointer to nodes root list structure
;struct

\ ------------------------------------------------------------------------
\ erase a llist structure, erase node linkage

: 0list         ( list --- ) list erase ;
: 0links        ( node -- )  node erase ;

\ ------------------------------------------------------------------------
\ create a new named linked list

: list:         ( --- )
  create here               \ create named list structure
  list allot
  0list ;

\ ------------------------------------------------------------------------

\ these words are used to add an anonymous linked list or
\ an anonymous linked list node to a structure.
\ used between struct: and ;struct

: /list:        ( --- )  list db ;
: /node:        ( --- )  node db ;

\ ------------------------------------------------------------------------
\ getters and setters for linked list structure

: head!         ( node list --- )  l.head ! ;
: tail!         ( node list --- )  l.tail ! ;

: head@         ( list --- node )  l.head @ ;
: tail@         ( list --- node )  l.tail @ ;

\ ------------------------------------------------------------------------
\ getters and setters for linked list node structure

: (root!) n.root ! ;
: (next!) n.next ! ;
: (prev!) n.prev ! ;

: root@         ( node --- list )   n.root @ ;
: next@         ( node1 --- node2 ) n.next @ ;
: prev@         ( node1 --- node2 ) n.prev @ ;

: root!         ( list node --- )   ?dup ?: (root!) drop ;
: next!         ( node1 node2 --- ) ?dup ?: (next!) drop ;
: prev!         ( node1 node2 --- ) ?dup ?: (prev!) drop ;

\ ------------------------------------------------------------------------
\ return true if list is empty

: isempty?      ( list --- f1 )
  dup head@
  swap tail@
  d0= ;

\ ------------------------------------------------------------------------
\ test if node is head or tail node of the list

: ishead?   ( node --- f1 )  dup root@ head@ = ;
: istail?   ( node --- f1 )  dup root@ tail@ = ;

\ ------------------------------------------------------------------------
\ chain node1 and node2 togehter (one or other might be null)

: chain         ( node1 node2 --- )
  2dup prev!
  swap next! ;

\ ------------------------------------------------------------------------
\ list is empty. add first node to it

: first!        ( node list --- )
  2dup swap root!
  2dup head! tail! ;

\ ------------------------------------------------------------------------

: ?first        ( node1 list --- [ node1 list f ] | t )
  dup isempty?              \ see if list is empty
  if
    first! true             \ if it is then add node1 to the list
    exit                    \ we do not need to chain it in
  then
  false ;

\ ------------------------------------------------------------------------

  headers>

: >head         ( node1 list --- )
  ?first ?exit
  2dup swap root!
  2dup head@ chain
  over n.prev off head! ;

\ ------------------------------------------------------------------------

: >tail         ( node1 list node1 --- )
  ?first ?exit
  2dup swap root!
  2dup tail@ swap chain
  over n.next off tail! ;

\ ------------------------------------------------------------------------
\ remove last node from list

  <headers

: lastnode   ( list --- node )
  dup head@                 \ collect the node
  swap 0list ;              \ list is now empty

\ ------------------------------------------------------------------------
\ remove head of list from chain where head is not the only item in list

: (<head)       ( list --- node )
  dup head@ tuck            \ get head node of list, keep copy of it
  next@ dup                 \ get second item of list
  n.prev off                \ nullify its 'prev'
  swap head! ;              \ make second node the new head node

\ ------------------------------------------------------------------------
\ remove tail of list from chain where tail is not the only item in list

: (<tail)       ( list --- node )
  dup tail@ tuck            \ get tail of list. keep copy of it
  prev@ dup                 \ get next to last item from list
  n.next off                \ nullify its 'next'
  swap tail! ;              \ make next to last new tail node

\ ------------------------------------------------------------------------
\ are head and tail same node

: ht=           ( list --- list f1 )
  dup head@ over tail@ = ;

\ ------------------------------------------------------------------------
\ remove head node from chain

  headers>

: <head         ( list --- node )
  ht=                       \ are head and tail the same node?
  ?:                        \ if they are...
    lastnode                \ remove only node from list
    (<head)                 \ remove first, make second new first
  dup 0links ;              \ nullify links of removed node

\ ------------------------------------------------------------------------
\ remove tail node from chain

: <tail     ( list --- node )
  ht=                       \ are head and tail the same node?
  ?:                        \ if they are...
    lastnode                \ remove only node from list
    (<tail)                 \ remove last. make next to last new last
  dup 0links ;              \ nullify links of removed node

\ ------------------------------------------------------------------------
\ if node is head remove it. does not return to caller

  <headers

: ?<head    ( node --- node f1 )
  dup root@
  head@ over <> ?exit
  root@ <head r>drop ;

\ ------------------------------------------------------------------------
\ if node is tail remove it. does not return to caller

: ?<tail    ( node --- node )
  dup root@
  tail@ over <> ?exit
  root@ <tail r>drop ;

\ ------------------------------------------------------------------------
\ remove any node from list

  headers>

: <list     ( node --- node )
  ?<head ?<tail             \ possibly removing head or tail of list

  \ this node is somewhere in the midle of a list!

  dup prev@                 \ fetch node thats previous to our node
  over next@                \ fetch node thats next to our node
  chain                     \ chain these two nodes together
  dup 0links ;              \ zero out all links inside our node

\ ------------------------------------------------------------------------

  behead forth definitions

\ ========================================================================
