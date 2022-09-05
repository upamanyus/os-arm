const uart = @import("../../uart.zig");
const mmio = @import("../../mmio.zig");
const panic = @import("../../panic.zig");
const delay = @import("../../arch/aarch64/delay.zig");

const base = 0xff4e0000; // takes up 64K bytes

const MiiAddrVal = packed struct {
    is_busy: u1,
    is_write: u1,
    cr: enum(u4) { // APB Clock Range
        s60_100 = 0b0000,
        s100_150 = 0b0001,
        s20_35 = 0b0010,
        s35_60 = 0b0011,
        s150_200 = 0b0100,
        s250_300 = 0b0101,
    } = .s60_100,
    reg_addr: u5 = 0, // (G)MII register address (which MII register do we want to read)
    phy_addr: u5 = 0, // physical layer address (which PHY do we want to access)
    _reserved: u16 = 0,
};
const MAC_GMII_ADDR = mmio.Register(MiiAddrVal).init(base + 0x10);

const MiiDataVal = packed struct {
    data: u16,
    _reserved: u16 = 0,
};
const MAC_GMII_DATA = mmio.Register(MiiDataVal).init(base + 0x14);

// mmio.Register();

var mii_reg_vals: [32][32]u16 = .{.{0} ** 32} ** 32;

// return the current value of a single specific MII register from a specific PHY
pub fn read_mii(comptime clk_range: @Type(.EnumLiteral), phy: u5, reg: u5) u16 {
    MAC_GMII_DATA.write(MiiDataVal{ .data = 0 });
    // Refer to notes from 2022-08-13 for clock analysis
    MAC_GMII_ADDR.write(MiiAddrVal{
        .phy_addr = phy,
        .reg_addr = reg,
        .cr = clk_range,
        .is_write = 0,
        .is_busy = 1,
    });
    while (MAC_GMII_ADDR.read().is_busy == 1) {}
    return MAC_GMII_DATA.read().data;
}

const grf_base = 0xFF000000;
var GRF_GPIO1B_IOMUX_L = mmio.RawRegister.init(grf_base + 0x0028);
var GRF_GPIO1B_P = mmio.RawRegister.init(grf_base + 0x00b4);
var GRF_MAC_CON0 = mmio.RawRegister.init(grf_base + 0x04a0);
var GRF_GPIO1B_E = mmio.RawRegister.init(grf_base + 0x0114);

var SYNOPSYS_ID = mmio.RawRegister.init(base + 0x20);

var MAC_MAC_CONF = mmio.RawRegister.init(base + 0x0);

fn mac_reset() void {
    var gpio0_base: usize = 0xff220000;
    var GPIO0_SWPORTA_DR = mmio.RawRegister.init(gpio0_base + 0x0);
    var GPIO0_SWPORTA_DDR = mmio.RawRegister.init(gpio0_base + 0x4);

    // for rk3308 rock pi S:
    // active_low = true
    // delays = 0, 50ms, 50ms
    // reset-gpio = GPIO0_A7

    // set 1, sleep(delays[0])
    GPIO0_SWPORTA_DDR.write(1 << 7);
    GPIO0_SWPORTA_DR.write(1 << 7);
    delay.delay(0 * 1e6);

    // set 0, sleep(delays[1])
    GPIO0_SWPORTA_DDR.write(1 << 7);
    GPIO0_SWPORTA_DR.write(0 << 7);
    delay.delay(50 * 1e6);

    // set 1, sleep(delays[2])
    GPIO0_SWPORTA_DDR.write(1 << 7);
    GPIO0_SWPORTA_DR.write(1 << 7);
    delay.delay(50 * 1e6);
}

fn pin_init() void {
    mac_reset();

    uart.printf("Synopsys ID: 0x{0x}\n", .{SYNOPSYS_ID.read()});

    // set up GRF_MAC_CON0 grf_con_mac2io_phy_intf_sel
    uart.printf("Old GRF_MAC_CON0 = 0x{0x}\n", .{GRF_MAC_CON0.read()});
    GRF_MAC_CON0.write((0b100 << 2) | (0b111 << (2 + 16)));
    uart.printf("new GRF_MAC_CON0 = 0x{0x}\n", .{GRF_MAC_CON0.read()});

    MAC_MAC_CONF.write(1 << 15 | 1 << 8); // 15 = port-select, MII; 8 = "link up"

    // FIXME: try configuring even more GPIO pins based on 23.5 of TRM.

    // set GPIO pin functionality to be MDIO

    // GRF_GPIO1B_IOMUX_L[15:12]=0b0011 for MAC_MDIO
    // GRF_GPIO1B_IOMUX_L[11:10]=0b11 MAC_MDC
    // GRF_GPIO1B_IOMUX_L[9:8]=0b11 for MAC_CLK
    const old_val = GRF_GPIO1B_IOMUX_L.read();
    if (old_val == 0) {
        const new_val = (old_val) | (0b11 << 8) | (0b0011 << 12) | (0b11 << 10);
        GRF_GPIO1B_IOMUX_L.write(new_val << 16 | new_val); // XXX: upper 16 are write enable bits
        uart.printf("Set up GPIO pins {0x}\n", .{
            GRF_GPIO1B_IOMUX_L.read(),
        });
    } else {
        panic.panic("unexpected GPIO config\n");
    }

    // XXX;: set GPIO pull-up/down state to "Z"; I think that means "bias-disable"
    // in dts terminology?
    // MAC_MDC and MAC_MDIO are pin5 and pin6 on GPIO1B.
    // bits 10-11 are pin5, 12-13 are pin6
    uart.printf("Previos GPIO1B_P: 0x{0x}\n", .{GRF_GPIO1B_P.read()});
    GRF_GPIO1B_P.write((0b00 << 10 | 0b00 << 12 | 0b00 << 8) | ((0b11 << 10 | 0b11 << 12 | 0b11 << 8) << 16));
    uart.printf("New GPIO1B_P: 0x{0x}\n", .{GRF_GPIO1B_P.read()});

    uart.printf("Previos GPIO1B_E: 0x{0x}\n", .{GRF_GPIO1B_E.read()});
    GRF_GPIO1B_E.write((0b11 << 8) | ((0b11 << 8) << 16));
    uart.printf("New GPIO1B_E: 0x{0x}\n", .{GRF_GPIO1B_E.read()});

    delay.delay(2e8);
}

pub fn init() void {
    pin_init();

    MAC_GMII_ADDR.write(MiiAddrVal{
        .phy_addr = 1,
        .reg_addr = 1,
        .cr = .s60_100,
        .is_write = 0,
        .is_busy = 0,
    });

    if (false) {
        // dump all regs starting at base
        var i: usize = 0;
        while (i < 0x100) : (i += 0x4) {
            const p = @intToPtr(*volatile u32, (base + i));
            uart.printf("0x{0x} = 0x{1x}", .{ base + i, p.* });
            p.* = 0xdeadbeef;
            if (i == 0x10) {
                uart.printf("(→ 0x{0x})", .{MAC_GMII_ADDR.raw_read()});
            }
            uart.printf("→ 0x{0x}|\n", .{p.*});
        }
    }

    const clks = [_]@Type(.EnumLiteral){ .s60_100, .s100_150, .s20_35, .s35_60, .s150_200, .s250_300 };

    // TODO: set the pclk_MAC rate correctly
    inline for (clks) |clk_range| {
        uart.puts("\n");
        for (mii_reg_vals) |*phy_vals, phy| {
            for (phy_vals.*) |*reg_val, reg| {
                reg_val.* = read_mii(clk_range, @intCast(u5, phy), @intCast(u5, reg));
                uart.printf("{0x:4}|", .{reg_val.*});
            }
            uart.puts("\n");
        }
    }
}
