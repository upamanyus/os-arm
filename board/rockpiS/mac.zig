const uart = @import("../../uart.zig");
const mmio = @import("../../mmio.zig");
const panic = @import("../../panic.zig");
const delay = @import("../../arch/aarch64/delay.zig");

const base = 0xff4e0000; // takes up 64K bytes

const MiiAddrVal = packed struct {
    _reserved: u16 = 0,
    phy_addr: u5 = 0, // physical layer address (which PHY do we want to access)
    reg_addr: u5 = 0, // (G)MII register address (which MII register do we want to read)
    cr: enum(u4) { // APB Clock Range
        s60_100 = 0b0000,
        s100_150 = 0b0001,
        s20_35 = 0b0010,
        s35_60 = 0b0011,
        s150_200 = 0b0100,
        s250_300 = 0b0101,
    } = .s60_100,
    is_write: u1,
    is_busy: u1,
};
const MAC_GMII_ADDR = mmio.Register(MiiAddrVal).init(base + 0x10);

const MiiDataVal = packed struct {
    _reserved: u16 = 0,
    data: u16,
};
const MAC_GMII_DATA = mmio.Register(MiiDataVal).init(base + 0x14);

// mmio.Register();

var mii_reg_vals: [32][32]u16 = .{.{0} ** 32} ** 32;

// return the current value of a single specific MII register from a specific PHY
pub fn read_mii(phy: u5, reg: u5) u16 {
    // Refer to notes from 2022-08-13 for clock analysis
    MAC_GMII_ADDR.write(MiiAddrVal{
        .phy_addr = phy,
        .reg_addr = reg,
        .cr = .s60_100, // FIXME:
        .is_write = 0,
        .is_busy = 1,
    });
    while (MAC_GMII_ADDR.read().is_busy == 1) {
        uart.puts("Busy\n");
    }
    uart.printf("0x{0x}|", .{MAC_GMII_ADDR.raw_read()});
    return MAC_GMII_DATA.read().data;
}

const grf_base = 0xFF000000;
var GRF_GPIO1B_IOMUX_L = mmio.RawRegister.init(grf_base + 0x0028);

pub fn init() void {
    // FIXME: try configuring even more GPIO pins based on 23.5 of TRM.

    // GRF_GPIO1B_IOMUX_L[15:12]=0b0011
    // GRF_GPIO1B_IOMUX_L[11:10]=0b11
    const old_val = GRF_GPIO1B_IOMUX_L.read();
    if (old_val == 0) {
        const new_val = (old_val) | (0b0011 << 12) | (0b11 << 10);
        GRF_GPIO1B_IOMUX_L.write(new_val << 16 | new_val); // XXX: upper 16 are write enable bits
        uart.printf("Set up GPIO pins {0x}\n", .{
            GRF_GPIO1B_IOMUX_L.read(),
        });
    } else {
        panic.panic("unexpected GPIO config\n");
    }
    delay.delay(1e9);

    // TODO: set the pclk_MAC rate correctly
    for (mii_reg_vals) |*phy_vals, phy| {
        for (phy_vals.*) |*reg_val, reg| {
            reg_val.* = read_mii(@intCast(u5, phy), @intCast(u5, reg));
            uart.printf("0x{0x}|", .{reg_val.*});
        }
        uart.puts("\n");
    }
}
