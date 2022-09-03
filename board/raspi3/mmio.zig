const mmio = @import("../../mmio.zig");

pub const MMIO_BASE: usize = 0x3F000000; // for raspi2 & 3
pub const MMIO_END: usize = 0x40000000; // for raspi2 & 3

const GPIO_BASE: usize = MMIO_BASE + 0x200000;

pub const GPPUD = mmio.RawRegister.init(GPIO_BASE + 0x94);
pub const GPPUDCLK0 = mmio.RawRegister.init(GPIO_BASE + 0x98);

// The base address for UART.
const UART0_BASE: usize = (GPIO_BASE + 0x1000);

pub const UART0_DR = mmio.RawRegister.init(UART0_BASE + 0x00);
pub const UART0_RSRECR = mmio.RawRegister.init(UART0_BASE + 0x04);
pub const UART0_FR = mmio.RawRegister.init(UART0_BASE + 0x18);
pub const UART0_ILPR = mmio.RawRegister.init(UART0_BASE + 0x20);
pub const UART0_IBRD = mmio.RawRegister.init(UART0_BASE + 0x24);
pub const UART0_FBRD = mmio.RawRegister.init(UART0_BASE + 0x28);
pub const UART0_LCRH = mmio.RawRegister.init(UART0_BASE + 0x2C);
pub const UART0_CR = mmio.RawRegister.init(UART0_BASE + 0x30);
pub const UART0_IFLS = mmio.RawRegister.init(UART0_BASE + 0x34);
pub const UART0_IMSC = mmio.RawRegister.init(UART0_BASE + 0x38);
pub const UART0_RIS = mmio.RawRegister.init(UART0_BASE + 0x3C);
pub const UART0_MIS = mmio.RawRegister.init(UART0_BASE + 0x40);
pub const UART0_ICR = mmio.RawRegister.init(UART0_BASE + 0x44);
pub const UART0_DMACR = mmio.RawRegister.init(UART0_BASE + 0x48);
pub const UART0_ITCR = mmio.RawRegister.init(UART0_BASE + 0x80);
pub const UART0_ITIP = mmio.RawRegister.init(UART0_BASE + 0x84);
pub const UART0_ITOP = mmio.RawRegister.init(UART0_BASE + 0x88);
pub const UART0_TDR = mmio.RawRegister.init(UART0_BASE + 0x8C);

const MBOX_BASE = MMIO_BASE + 0xB880;
pub const MBOX_READ = mmio.RawRegister.init(MBOX_BASE + 0x00);
pub const MBOX_STATUS = mmio.RawRegister.init(MBOX_BASE + 0x18);
pub const MBOX_WRITE = mmio.RawRegister.init(MBOX_BASE + 0x20);
