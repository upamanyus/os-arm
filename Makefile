PFX = aarch64-linux-gnu-

.PHONY: all
all:
	zig build
	$(PFX)objcopy -O binary build/kernel8.elf kernel8.img

.PHONY: clean
clean:
	rm -f build/* kernel8.img

qemu: all
	qemu-system-aarch64 -nographic -M raspi3b -kernel kernel8.img

qemu-graphic: all
	qemu-system-aarch64 -M raspi3b -kernel kernel8.img -serial stdio

qemu-gdb: all
	qemu-system-aarch64 -M raspi3b -kernel kernel8.img -S -gdb tcp::12345 -nographic
