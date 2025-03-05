const mmio = @import("../../mmio.zig");
const delay = @import("../../arch/aarch64/delay.zig");

// The base address for UART.
const UART0_BASE: u64 = 0xff0a0000;

const UART0_RBR = mmio.RawRegister.init(UART0_BASE + 0x00);
const UART0_THR = mmio.RawRegister.init(UART0_BASE + 0x00);

const UART0_DLL = mmio.RawRegister.init(UART0_BASE + 0x00);
const UART0_DLH = mmio.RawRegister.init(UART0_BASE + 0x04);
const UART0_FCR = mmio.RawRegister.init(UART0_BASE + 0x08);
const UART0_LCR = mmio.RawRegister.init(UART0_BASE + 0x0c);
const UART0_LSR = mmio.RawRegister.init(UART0_BASE + 0x14);

fn slow_delay(iters: u64) void {
    var count_left = iters;
    const count_left_ptr: *volatile u64 = @ptrCast(&count_left);

    while (count_left_ptr.* != 0) {
        count_left_ptr.* -= 1;
    }
}

pub fn init() void {
    // set the baud rate to 19200
    // XXX: also need USR[0] to be zero
    UART0_LCR.write(0b10000000); // enable access to DLL+DLH

    // default/reset DPLL clock is 1200MHz
    // baud rate = sclk / (16 * divisor)
    // want divisor = 3906
    const divisor: u16 = 3906;
    UART0_DLL.write(divisor & 0xFF);
    UART0_DLH.write((divisor & 0xFF00) >> 8);

    UART0_LCR.write(0b0); // disable access to DLL+DLH, enable access to other regs

    slow_delay(2e6);

    UART0_FCR.write(0x01); // enable FIFO
}

pub fn putc(c: u8) void {
    if (c == '\n') { // XXX: handle newlines properly
        putc('\r');
    }
    while (UART0_LSR.read() >> 5 & 0x1 == 0) {} // loop while THR non-empty
    UART0_THR.write(c);
}

pub fn getc() u8 {
    while (UART0_LSR.read() & 0x1 == 0) {} // if THR empty
    return @intCast(UART0_RBR.read());
}
