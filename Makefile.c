PFX = aarch64-linux-gnu-
CC = $(PFX)gcc
AS = $(PFX)as
LD = $(PFX)ld
OBJCOPY = $(PFX)objcopy

CFLAGS = -Wall -Wextra -g -O2 -ffreestanding -nostdlib -I.
ASFLAGS = -g

SRCS_C = \
    kmain.c \
    uart.c \
    board/raspi3/uart.c \
    kmem.c \
    mem_layout.c \
    panic.c \
    execution_context.c

SRCS_S = \
    arch/aarch64/start.S \
    arch/aarch64/entry.S \
    arch/aarch64/delay.S

OBJS = $(SRCS_C:.c=.o) $(SRCS_S:.S=.o)

LDSCRIPT = arch/aarch64/linker.ld
OUT_ELF = build/bin/kernel8.elf
OUT_IMG = kernel8.img

.PHONY: all
all: $(OUT_IMG)

$(OUT_IMG): $(OUT_ELF)
	$(OBJCOPY) -O binary $< $@

$(OUT_ELF): $(OBJS)
	mkdir -p $(dir $@)
	$(LD) -T $(LDSCRIPT) -o $@ $(OBJS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(CC) $(ASFLAGS) -c $< -o $@

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
