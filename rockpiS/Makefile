AAPRE64 = aarch64-linux-gnu-
PFX = $(AAPRE64)
CFLAGS = -g -Wall -ffreestanding -nostdlib -nostartfiles
CC = $(PFX)gcc
AS = $(PFX)as
ASFLAGS = -mcpu=cortex-a35

ASM_OBJS = start.o
OBJS = kmain.o $(ASM_OBJS)

.PHONY: all
all: kernel64.img

kernel64.img: kernel.ld $(OBJS)
	$(PFX)gcc -ffreestanding -nostdlib $(OBJS) -T kernel.ld -o kernel64.elf
	$(PFX)objcopy -O binary kernel64.elf kernel64.img

.PHONY: clean
clean:
	rm -f kernel64.elf kernel64.img *.o

qemu: all
	qemu-system-arm -nographic -M raspi0 -kernel kernel64.img

qemu-graphic: all
	qemu-system-arm -M raspi0 -kernel kernel64.img -serial stdio

qemu-gdb: all
	qemu-system-arm -M raspi0 -kernel kernel64.img -S -gdb tcp::12345 -nographic
