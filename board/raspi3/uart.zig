const delay = @import("../../arch/aarch64/delay.zig");
const mmio = @import("mmio.zig");
// const mmio = @import("mmio.zig");

const mbox_clockrate: [9]u32 align(16) = .{ 9 * 4, 0, 0x38002, 12, 8, 2, 3000000, 0, 0 };

// uart implementation for raspberry pi 3b
pub fn init() void {
    // Disable UART0.
    mmio.UART0_CR.write(0x00000000);
    // Setup the GPIO pin 14 && 15.

    // Disable pull up/down for all GPIO pins & delay for 150 cycles.
    mmio.GPPUD.write(0x00000000);
    delay.delay(150);

    // Disable pull up/down for pin 14,15 & delay for 150 cycles.
    mmio.GPPUDCLK0.write((1 << 14) | (1 << 15));
    delay.delay(150);

    // Write 0 to GPPUDCLK0 to make it take effect.
    mmio.GPPUDCLK0.write(0x00000000);

    // Clear pending interrupts.
    mmio.UART0_ICR.write(0x7FF);

    // Set integer & fractional part of baud rate.
    // Divider = UART_CLOCK/(16 * Baud)
    // Fraction part register = (Fractional part * 64) + 0.5
    // Baud = 115200.

    // For Raspi3 and 4 the UART_CLOCK is system-clock dependent by default.
    // Set it to 3Mhz so that we can consistently set the baud rate
    // if (raspi >= 3) {
    // UART_CLOCK = 30000000;
    const r: u32 = (@intCast(u32, @ptrToInt(&mbox_clockrate)) & ~@as(u32, 0xF)) | 8;
    // wait until we can talk to the VC
    while (mmio.MBOX_STATUS.read() & 0x80000000 != 0) {}
    // send our message to property channel and wait for the response
    mmio.MBOX_WRITE.write(r);
    while ((mmio.MBOX_STATUS.read() & 0x40000000 != 0) or mmio.MBOX_READ.read() != r) {}
    // }

    // Divider = 3000000 / (16 * 115200) = 1.627 = ~1.
    mmio.UART0_IBRD.write(1);
    // Fractional part register = (.627 * 64) + 0.5 = 40.6 = ~40.
    mmio.UART0_FBRD.write(40);

    // Enable FIFO & 8 bit data transmission (1 stop bit, no parity).
    mmio.UART0_LCRH.write((1 << 4) | (1 << 5) | (1 << 6));

    // Mask all interrupts.
    mmio.UART0_IMSC.write((1 << 1) | (1 << 4) | (1 << 5) | (1 << 6) | (1 << 7) | (1 << 8) | (1 << 9) | (1 << 10));

    // Enable UART0, receive & transfer part of UART.
    mmio.UART0_CR.write((1 << 0) | (1 << 8) | (1 << 9));
}

pub fn putc(c: u8) void {
    while (mmio.UART0_FR.read() & (1 << 5) != 0) {}
    mmio.UART0_DR.write(c);
}

pub fn getc() u8 {
    while (mmio.UART0_FR.read() & (1 << 4) != 0) {}
    return mmio.UART0_DR.read();
}
