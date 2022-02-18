AAPRE64 = aarch64-linux-gnu-
A32PRE = arm-none-eabi-
PFX = $(A32PRE)
CFLAGS = -g -Wall -ffreestanding -nostdlib -nostartfiles
OBJS = start32.o kmain.o uart.o mmio.o util.o kmem.o kproc_swtch32.o kproc.o kproc_start32.o

.PHONY: all
all: kernel7.img

start32.o: start32.S
	$(PFX)as -c start32.S -o start32.o

kproc_swtch32.o: kproc_swtch32.S
	$(PFX)as -c kproc_swtch32.S -o kproc_swtch32.o

kproc_start32.o: kproc_start32.S
	$(PFX)as -c kproc_start32.S -o kproc_start32.o

%.o: %.c
	$(PFX)gcc $(CFLAGS) -c $< -o $@

kernel7.img: kernel.ld $(OBJS)
	$(PFX)gcc -ffreestanding -nostdlib $(OBJS) -T kernel.ld -o kernel7.elf
	$(PFX)objcopy -O binary kernel7.elf kernel7.img

.PHONY: clean
clean:
	rm -f kernel7.elf *.o

qemu: all
	qemu-system-arm -M raspi0 -kernel kernel7.img -serial stdio

qemu-gdb: all
	qemu-system-arm -M raspi0 -kernel kernel7.img -S -gdb tcp::12345 -nographic
