AAPRE = aarch64-linux-gnu-
CFLAGS = -g -Wall -ffreestanding -nostdlib -nostartfiles
OBJS = start.o kmain.o uart.o mmio.o util.o kmem.o kproc_swtch.o kproc.o kproc_start.o

.PHONY: all
all: kernel8.img

start.o: start.S
	$(AAPRE)as -c start.S -o start.o

kproc_swtch.o: kproc_swtch.S
	$(AAPRE)as -c kproc_swtch.S -o kproc_swtch.o

kproc_start.o: kproc_start.S
	$(AAPRE)as -c kproc_start.S -o kproc_start.o

%.o: %.c
	$(AAPRE)gcc $(CFLAGS) -c $< -o $@

kernel8.img: kernel.ld $(OBJS)
	$(AAPRE)gcc -ffreestanding -nostdlib $(OBJS) -T kernel.ld -o kernel8.elf
	$(AAPRE)objcopy -O binary kernel8.elf kernel8.img

.PHONY: clean
clean:
	rm -f kernel8.elf *.o

qemu: all
	qemu-system-aarch64 -M raspi3b -kernel kernel8.img -serial stdio

qemu-gdb: all
	qemu-system-aarch64 -M raspi3b -kernel kernel8.img -S -gdb tcp::12345 -nographic
