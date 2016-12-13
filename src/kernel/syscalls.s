@ syscalls.s
@ ------------------------------------------------------------------------

  _constant_ "errno", errno, 0

@ ------------------------------------------------------------------------
@ handle syscall with no parameters or one with all registers populated

sys1:
sys0:                       @ syscall number is in r7
  swi 0                     @ execute system call
  cmp r0, #0xfffff000
  blo 1f

  mvns r0, r0               @ error: convert error return to positive val
  adr r1, errno             @ stuff it in errno
  str r0, [r1, #BODY]
  mvn r0, #0                @ return bad result

1:
  exit

@ ------------------------------------------------------------------------
@ handle syscall with 2 parameters

sys2:
  pop { r1 }
  b sys0

@ ------------------------------------------------------------------------
@ handle syscall with 3 parameters

sys3:
  pop { r1, r2 }
  b sys0

@ ------------------------------------------------------------------------

sys4:
  pop { r1, r2, r3 }
  b sys0

@ ------------------------------------------------------------------------

sys5:
  pop { r1, r2, r3, r4 }
  b sys0

@ ------------------------------------------------------------------------

sys6:
  pop { r1, r2, r3, r4, r5 }
  b sys0

@ ------------------------------------------------------------------------

code "dosyscall", do_syscall
  bic lr, #1
  mov r3, lr
  ldrh r7, [r3]             @ get syscall number
  ldrh r1, [r3, #2]         @ parameter count
  tbb [pc, r1]

  .byte 4, 5, 6, 7, 8, 9, 10
  .balign 2

  b sys0
  b sys1
  b sys2
  b sys3
  b sys4
  b sys5
  b sys6

@ ------------------------------------------------------------------------
@ only defining syscalls that are used within the kernel. new syscalls
@ can be added at any time using '#params sys# syscall <sys_name>'

 _syscall_ "<exit>",   sys_exit,   1,    1
 _syscall_ "<read>",   sys_read,   3,    3
 _syscall_ "<write>",  sys_write,  4,    3
 _syscall_ "<open>",   sys_open,   5,    2
 _syscall_ "<open3>",  sys_open3,  5,    3
 _syscall_ "<close>",  sys_close,  6,    1
@ _syscall_ "<creat>",  sys_creat,  8,    2
 _syscall_ "<lseek>",  sys_lseek,  0x13, 3
@ _syscall_ "<signal>", sys_signal, 0x30, 2
@ _syscall_ "<ioctl>",  sys_ioctl,  0x36, 3
 _syscall_ "<mmap2>",  sys_mmap2,  0xc0, 6
 _syscall_ "<munmap>", sys_munmap, 0x5b, 2
 _syscall_ "<poll>",   sys_poll,   0xa8, 3

@ ========================================================================
