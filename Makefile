PFX = aarch64-linux-gnu-
CC = $(PFX)gcc
AS = $(PFX)as
LD = $(PFX)ld
OBJCOPY = $(PFX)objcopy

CFLAGS = -Wall -Wextra -g -O2 -ffreestanding -nostdlib -I.

OBJS = kmain.o uart.o board/raspi3/uart.o kmem.o mem_layout.o panic.o execution_context.o \
         arch/aarch64/start.o arch/aarch64/entry.o arch/aarch64/delay.o

LDSCRIPT = arch/aarch64/linker.ld

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
	qemu-system-aarch64 -nographic -M raspi3b -kernel kernel.img

.PHONY: qemu-graphic
qemu-graphic: all
	qemu-system-aarch64 -M raspi3b -kernel kernel.img -serial stdio

.PHONY: qemu-gdb
qemu-gdb: all
	qemu-system-aarch64 -M raspi3b -kernel kernel.img -S -gdb tcp::12345 -nographic
