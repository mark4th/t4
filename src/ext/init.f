\ init.f   - custom initialization
\ ------------------------------------------------------------------------

  .( loading init.f ) cr

\ ------------------------------------------------------------------------
\ this file should be in your home directory

  create rc-path ," /home/"
  create rc-file ," /.t4.rcf"

\ ------------------------------------------------------------------------
\ we need to get the user name out of the environment...

  create env_user ," USER"

\ ------------------------------------------------------------------------

: custom-init
  defers ldefault           \ make sure everything else has initialized

  env_user getenv           \ get username from environment
  0= ?exit                  \ eh?
  rc-path count hhere $!    \ store path at hhere
  hhere $+                  \ concat username into string
  rc-file count hhere $+    \ concat rc filename

  0 dup hhere count         \ verify file exists
  s>z <open3>
  dup                       \ bug fix suggested by humptydumptyII on irc

  0> not ?exit <close>      \ close file or exit if file missing

  0 dup hhere 1+ (fload) ;  \ if it exists interpret it

\ ========================================================================
