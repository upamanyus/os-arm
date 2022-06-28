AAPRE64 = aarch64-linux-gnu-
A32PRE = arm-none-eabi-
PFX = $(A32PRE)
CFLAGS = -g -Wall -ffreestanding -nostdlib -nostartfiles
CC = $(PFX)gcc
AS = $(PFX)as
ASFLAGS = -mcpu=cortex-a7

ASM_OBJS = start32.o kproc_switch32.o kproc_start32.o exception_table32.o entry32.o vm32.o
OBJS = kmain.o uart.o mmio.o util.o kmem.o kproc.o exception.o vm.o uproc.o $(ASM_OBJS)

.PHONY: all
all: kernel7.img

kernel7.img: kernel.ld $(OBJS)
	$(PFX)gcc -ffreestanding -nostdlib $(OBJS) -T kernel.ld -o kernel7.elf
	$(PFX)objcopy -O binary kernel7.elf kernel7.img

.PHONY: clean
clean:
	rm -f kernel7.elf kernel7.img *.o

qemu: all
	qemu-system-arm -nographic -M raspi0 -kernel kernel7.img

qemu-graphic: all
	qemu-system-arm -M raspi0 -kernel kernel7.img -serial stdio

qemu-gdb: all
	qemu-system-arm -M raspi0 -kernel kernel7.img -S -gdb tcp::12345 -nographic
