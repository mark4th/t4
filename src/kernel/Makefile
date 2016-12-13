
# for the beagleboard
#CPU    = cortex-a8
#ARCH   = armv7-a

# for pi2
CPU  = cortex-a7
ARCH = armv7-a
FPU  = -mfpu=neon-vfpv4 -mfloat-abi=hard

# for pi1
# -mfpu=vfp -mfloat-abi=hard -march=armv6zk -mtune=arm1176jzf-s

ROOT   = ../..
BUILD  = $(ROOT)/build
LINK   = ../ld/t4.ld
NOLIBS = -nostdlib -nostartfile
TUNE   =
TOOL   = armv7a-hardfloat-linux-gnueabi-

# set tool to the following to enable cross compilation of
# this forth by your desktop machine
#armv7a-hardfloat-linux-gnueabi-

includes = \
  syscalls.s stacks.s memory.s math.s logic.s  \
  loops.s exec.s io.s scan.s expect.s number.s \
  find.s interpret.s fload.s compile.s reloc.s \
  vocabs.s rehash.s

t4k: t4k.o
	@$(TOOL)ld -T $(LINK) $(NOLIBS) $(BUILD)/t4k.o -o $(ROOT)/t4k
	@$(TOOL)strip -R .comment $(ROOT)/t4k

t4k.o: t4.s $(includes)
	@$(TOOL)as -mthumb -march=$(ARCH) -mcpu=$(CPU) $(TUNE) $(FPU) \
	-g t4.s -o $(BUILD)/t4k.o -almns >$(BUILD)/t4k.lst

clean:
	@rm -f $(BUILD)/*
	@rm -f $(ROOT)/t4k
