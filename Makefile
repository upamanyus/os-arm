PFX = aarch64-linux-gnu-
CC = $(PFX)gcc
AS = $(PFX)as
LD = $(PFX)ld
OBJCOPY = $(PFX)objcopy

CFLAGS = -Wall -Wextra -g -O2 -ffreestanding -nostdlib -I. -DBOARD_$(BOARD)

BOARD ?= raspi3

K=kernel
OBJS = \
  $K/kmain.o \
  $K/kmem.o \
  $K/mem_layout.o \
  $K/panic.o \
  $K/execution_context.o \
  $K/start.o \
  $K/entry.o \
  $K/delay.o \
  $K/uart.o

ifeq ($(BOARD),raspi3)
OBJS += \
  board/raspi3/uart.o
else ifeq ($(BOARD),rockpiS)
OBJS += \
  board/rockpiS/uart.o \
  board/rockpiS/ethernet.o
endif

LDSCRIPT = kernel/linker.ld

.PHONY: all
all: kernel.img

kernel.img: kernel.elf
	$(OBJCOPY) -O binary $< $@

kernel.elf: $(LDSCRIPT) $(OBJS)
	$(LD) -T $(LDSCRIPT) -o $@ $(OBJS)

.PHONY: clean
clean:
	rm -f $(OBJS) kernel.img kernel.elf

.PHONY: qemu
qemu: all
ifeq ($(BOARD),raspi3)
	qemu-system-aarch64 -nographic -M raspi3b -kernel kernel.img
else
	@echo "ERROR: No qemu support for $(BOARD)"
endif

.PHONY: qemu-graphic
qemu-graphic: all
ifeq ($(BOARD),raspi3)
	qemu-system-aarch64 -M raspi3b -kernel kernel.img -serial stdio
else
	@echo "ERROR: No qemu support for $(BOARD)"
endif

.PHONY: qemu-gdb
qemu-gdb: all
ifeq ($(BOARD),raspi3)
	qemu-system-aarch64 -M raspi3b -kernel kernel.img -S -gdb tcp::12345 -nographic
else
	@echo "ERROR: No qemu support for $(BOARD)"
endif
