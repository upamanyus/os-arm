// https://www.scattered-thoughts.net/writing/mmio-in-zig/
pub const RawRegister = struct {
    raw_ptr: *volatile u32,

    const Self = @This();

    pub fn init(address: usize) Self {
        return .{ .raw_ptr = @intToPtr(*u32, address) };
    }

    pub fn read(self: Self) u32 {
        return self.raw_ptr.*;
    }

    pub fn write(self: Self, value: u32) void {
        self.raw_ptr.* = value;
    }
};

// UART registers

const MMIO_BASE: usize = 0x3F000000; // for raspi2 & 3
const MMIO_END: usize = 0x3FFFFFFF; // for raspi2 & 3

const GPIO_BASE: usize = MMIO_BASE + 0x200000;

pub const GPPUD = RawRegister.init(GPIO_BASE + 0x94);
pub const GPPUDCLK0 = RawRegister.init(GPIO_BASE + 0x98);

// The base address for UART.
const UART0_BASE: usize = (GPIO_BASE + 0x1000);

pub const UART0_DR = RawRegister.init(UART0_BASE + 0x00);
pub const UART0_RSRECR = RawRegister.init(UART0_BASE + 0x04);
pub const UART0_FR = RawRegister.init(UART0_BASE + 0x18);
pub const UART0_ILPR = RawRegister.init(UART0_BASE + 0x20);
pub const UART0_IBRD = RawRegister.init(UART0_BASE + 0x24);
pub const UART0_FBRD = RawRegister.init(UART0_BASE + 0x28);
pub const UART0_LCRH = RawRegister.init(UART0_BASE + 0x2C);
pub const UART0_CR = RawRegister.init(UART0_BASE + 0x30);
pub const UART0_IFLS = RawRegister.init(UART0_BASE + 0x34);
pub const UART0_IMSC = RawRegister.init(UART0_BASE + 0x38);
pub const UART0_RIS = RawRegister.init(UART0_BASE + 0x3C);
pub const UART0_MIS = RawRegister.init(UART0_BASE + 0x40);
pub const UART0_ICR = RawRegister.init(UART0_BASE + 0x44);
pub const UART0_DMACR = RawRegister.init(UART0_BASE + 0x48);
pub const UART0_ITCR = RawRegister.init(UART0_BASE + 0x80);
pub const UART0_ITIP = RawRegister.init(UART0_BASE + 0x84);
pub const UART0_ITOP = RawRegister.init(UART0_BASE + 0x88);
pub const UART0_TDR = RawRegister.init(UART0_BASE + 0x8C);

const MBOX_BASE = MMIO_BASE + 0xB880;
pub const MBOX_READ = RawRegister.init(MBOX_BASE + 0x00);
pub const MBOX_STATUS = RawRegister.init(MBOX_BASE + 0x18);
pub const MBOX_WRITE = RawRegister.init(MBOX_BASE + 0x20);
