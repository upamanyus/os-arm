PFX = aarch64-linux-gnu-
CC = $(PFX)gcc
AS = $(PFX)as
LD = $(PFX)ld
OBJCOPY = $(PFX)objcopy

CFLAGS = -Wall -Wextra -g -O2 -ffreestanding -nostdlib -I.

OBJS = kmain.o uart.o board/raspi3/uart.o kmem.o mem_layout.o panic.o execution_context.o \
         arch/aarch64/start.o arch/aarch64/entry.o arch/aarch64/delay.o

LDSCRIPT = arch/aarch64/linker.ld
OUT_ELF = build/bin/kernel8.elf
OUT_IMG = kernel8.img

.PHONY: all
all: $(OUT_IMG)

kernel8.img: build/bin/kernel8.elf
	$(OBJCOPY) -O binary $< $@

build/bin/kernel8.elf: $(OBJS)
	mkdir -p $(dir $@)
	$(LD) -T $(LDSCRIPT) -o $@ $(OBJS)

.PHONY: clean
clean:
	rm -f $(OBJS) $(OUT_ELF) $(OUT_IMG)

.PHONY: qemu
qemu: all
	qemu-system-aarch64 -nographic -M raspi3b -kernel $(OUT_IMG)

.PHONY: qemu-graphic
qemu-graphic: all
	qemu-system-aarch64 -M raspi3b -kernel $(OUT_IMG) -serial stdio

.PHONY: qemu-gdb
qemu-gdb: all
	qemu-system-aarch64 -M raspi3b -kernel $(OUT_IMG) -S -gdb tcp::12345 -nographic
