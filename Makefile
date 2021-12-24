AAPRE = aarch64-linux-gnu-
CFLAGS = -g -Wall -ffreestanding -nostdlib -nostartfiles

.PHONY: all
all: kernel8.img

start.o: start.S
	$(AAPRE)as -c start.S -o start.o

kmain.o: kmain.c
	$(AAPRE)gcc $(CFLAGS) -c kmain.c -o kmain.o

kernel8.img: start.o kmain.o
	$(AAPRE)gcc -ffreestanding -nostdlib start.o kmain.o -T kernel.ld -o kernel8.elf
	$(AAPRE)objcopy -O binary kernel8.elf kernel8.img

.PHONY: clean
clean:
	rm -f kernel8.elf *.o

qemu: all
	qemu-system-aarch64 -M raspi3b -kernel kernel8.img -nographic

qemu-gdb: all
	qemu-system-aarch64 -M raspi3b -kernel kernel8.img -S -gdb tcp::12345 -nographic
