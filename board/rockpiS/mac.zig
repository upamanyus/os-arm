const uart = @import("../../uart.zig");
const mmio = @import("../../mmio.zig");
const panic = @import("../../panic.zig");
const delay = @import("../../arch/aarch64/delay.zig");
const kmem = @import("../../kmem.zig");

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
var GRF_GPIO1B_IOMUX_H = mmio.RawRegister.init(grf_base + 0x002c);
var GRF_GPIO1C_IOMUX_L = mmio.RawRegister.init(grf_base + 0x0030);
var GRF_GPIO1C_IOMUX_H = mmio.RawRegister.init(grf_base + 0x0034);

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
    // delay.delay(0 * 1e6);

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

    // Set pin muxes for MAC

    // GRF_GPIO1B_IOMUX_L[9:8]=0b11 for MAC_CLK
    // GRF_GPIO1B_IOMUX_L[11:10]=0b11 MAC_MDC
    // GRF_GPIO1B_IOMUX_L[15:12]=0b0011 for MAC_MDIO
    var old_val = GRF_GPIO1B_IOMUX_L.read();
    if (old_val != 0) {
        panic.panic("unexpected GPIO config\n");
    }
    var new_val = (old_val) | (0b11 << 8) | (0b0011 << 12) | (0b11 << 10);
    GRF_GPIO1B_IOMUX_L.write(new_val << 16 | new_val); // XXX: upper 16 are write enable bits
    uart.printf("Set up MUX_GPIO1B_L {0x}\n", .{GRF_GPIO1B_IOMUX_L.read()});

    // 1C_L[3:2] = 0b11 (MAC_TXEN)
    // 1C_L[6:4] = 0b011 (MAC_TXD1)
    // 1C_L[10:8] = 0b011 (MAC_TXD0)
    // 1C_L[1:0] = 0b11 (MAC_RXDV)
    // 1C_L[14:12] = 0b011 (MAC_RXD0)
    old_val = GRF_GPIO1C_IOMUX_L.read();
    if (old_val != 0) {
        panic.panic("unexpected GPIO config\n");
    }
    new_val = (0b11 << 2) | (0b011 << 4) | (0b011 << 8) | (0b11 << 0) | (0b011 << 12);
    GRF_GPIO1C_IOMUX_L.write(new_val << 16 | new_val); // XXX: upper 16 are write enable bits
    uart.printf("Set up MUX_GPIO1C_L {0x}\n", .{GRF_GPIO1C_IOMUX_L.read()});

    // 1B_H[2:0] = 0b011 (MAC_RXER)
    old_val = GRF_GPIO1B_IOMUX_H.read();
    if (old_val != 0) {
        panic.panic("unexpected GPIO config\n");
    }
    new_val = (0b11 << 0);
    GRF_GPIO1B_IOMUX_H.write(new_val << 16 | new_val); // XXX: upper 16 are write enable bits
    uart.printf("Set up MUX_GPIO1B_H {0x}\n", .{GRF_GPIO1B_IOMUX_H.read()});

    // 1C_H[2:0] = 0b011 (MAC_RXD1)
    // default = 0x00000440
    old_val = GRF_GPIO1C_IOMUX_H.read();
    if (old_val != 0x00000440) {
        // XXX: after uboot, we actually end up getting 220
        uart.printf("Got GPIO1C_IOMUX_H = {0x:8}, but still continuing \n", .{old_val});
        // panic.panic("unexpected GPIO config\n");
    }
    new_val = (0b11 << 0);
    GRF_GPIO1C_IOMUX_H.write(new_val << 16 | new_val); // XXX: upper 16 are write enable bits
    uart.printf("Set up MUX_GPIO1C_H {0x}\n", .{GRF_GPIO1C_IOMUX_H.read()});

    // Finish setting MUX states

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

    // const clks = [_]@Type(.EnumLiteral){ .s60_100, .s100_150, .s20_35, .s35_60, .s150_200, .s250_300 };
    const clks = [_]@Type(.EnumLiteral){.s60_100};

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

    uart.puts("Starting send message\n");
    setup_and_send_one();
}

const TxDescriptor0 = packed struct {
    deferred_bit: u1 = 0,
    err_underflow: u1 = 0,
    err_excessive_deferral: u1 = 0,
    collision_count: u4 = 0,
    vlan_frame: u1 = 0,

    err_excessive_collision: u1 = 0,
    err_late_collision: u1 = 0,
    err_no_carrier: u1 = 0,
    err_loss_of_carrier: u1 = 0,
    err_payload_checksum: u1 = 0,
    err_frame_flushed: u1 = 0,
    err_jabber_timeout: u1 = 0,
    err_summary: u1 = 0,
    ip_header_err: u1 = 0,

    _reserved: u14 = 0,
    dma_own: u1 = 0, // true iff DMA owns this descriptor
};

const TxDescriptor1 = packed struct {
    transmit_buffer1_size: u11 = 0,
    transmit_buffer2_size: u11 = 0,
    _reserved: u1 = 0,
    disable_padding: u1 = 0,
    second_addr_chained: u1 = 0,
    end_of_ring: u1 = 0,
    disable_crc: u1 = 0,
    checksum_insertion_control: u2 = 0,
    first_segment: u1 = 0,
    last_segment: u1 = 0,
    interrupt_on_completion: u1 = 0,
};

const TxDescriptor = packed struct {
    d0: TxDescriptor0 = TxDescriptor0{},
    d1: TxDescriptor1 = TxDescriptor1{},
    buffer1_addr: u32 = 0,
    buffer2_addr: u32 = 0,
};

const MAC_TX_DESC_LIST_ADDR = mmio.RawRegister.init(base + 0x1010);

const MacOpModeVal = packed struct {
    _unused: u13 = 0,
    start_transmit: u1 = 0,
    _unused2: u18 = 0,
};

const MAC_OP_MODE = mmio.Register(MacOpModeVal).init(base + 0x1018);

const Bad = packed struct {
    a: u8 = 0,
    b: u9 = 0,
    c: u15 = 0,
};

// FIXME: if we put the real bit layout here, then zig complains that the packed
// struct is 5 bytes (while only taking up 32 bits).This is fixed in zig 0.10,
// but inline assembly is a bit broken in 0.10 as well.
const MacBusModeVal = packed struct {
    software_reset: u1 = 0,
    _unused4: u31 = 0,
};

const MAC_BUS_MODE = mmio.Register(MacBusModeVal).init(base + 0x1000);

fn soft_reset_mac() void {
    uart.printf("Initial BUS_MODE: {0x:8}\n", .{MAC_BUS_MODE.raw_read()});
    MAC_BUS_MODE.write(MacBusModeVal{ .software_reset = 1 });
    var num_cycles_to_reset: usize = 0;
    while (MAC_BUS_MODE.read().software_reset == 1) {
        num_cycles_to_reset += 1;
    }
    uart.printf("Reset took {0} cycles\n", .{num_cycles_to_reset});
    uart.printf("New BUS_MODE: {0x:8}\n", .{MAC_BUS_MODE.raw_read()});
    // MAC_BUS_MODE.modify(.{ .pbl = 0x8 });
    uart.puts("MAC reset done\n");
}

comptime {
    if (@bitSizeOf(TxDescriptor0) != @bitSizeOf(u32)) {
        @compileError("TxDesc0 not sized correctly");
    }

    if (@bitSizeOf(TxDescriptor1) != @bitSizeOf(u32)) {
        @compileError("TxDesc1 not sized correctly");
    }
}

const MAC_STATUS = mmio.RawRegister.init(base + 0x1014);

pub fn setup_and_send_one() void {
    soft_reset_mac();

    var tx_msg: usize = kmem.alloc_or_panic();

    // Set up message being sent. Make it sequentially increasing bytes. Will
    // make this a valid ethernet frame later.
    var i: usize = 0;
    while (i < 1024) : (i += 1) {
        @intToPtr(*u8, (tx_msg + i)).* = @intCast(u8, i & 0xFF);
    }

    const tx_descs_addr = kmem.alloc_or_panic();
    var tx_descs = @intToPtr([*]volatile TxDescriptor, tx_descs_addr);

    tx_descs[0] = TxDescriptor{}; // zero out
    uart.printf("TX desc before initing: {0}\n", .{tx_descs[0]});
    // Set up TX descriptor ring. Need to set "end of ring" on last one.
    tx_descs[0].d1.end_of_ring = 1;
    tx_descs[0].buffer1_addr = @intCast(u32, tx_msg);
    tx_descs[0].d1.transmit_buffer1_size = 1024;
    tx_descs[0].d0.dma_own = 1;
    uart.printf("TX desc before sending: {0}\n", .{tx_descs[0]});

    uart.printf("{0x} vs {1x}\n", .{ @ptrToInt(&tx_descs), @ptrToInt(&tx_descs[0]) });
    // Tell MAC where to find TX descriptors
    MAC_TX_DESC_LIST_ADDR.write(@intCast(u32, @ptrToInt(tx_descs)));
    uart.printf("TX desc reg addr: {0x}; tx addr: {1x}\n", .{ MAC_TX_DESC_LIST_ADDR.read(), @ptrToInt(&tx_descs[0]) });

    uart.printf("STATUS before transfer desc: {0x:8}\n", .{MAC_STATUS.read()});
    // Enable MAC TX DMA.
    MAC_OP_MODE.write(.{ .start_transmit = 1 });
    uart.puts("Finished sending message\n");
    var done: bool = false;
    while (!done) {
        uart.printf("Current TX desc: {0}\n", .{tx_descs[0]});
        uart.printf("Current STATUS desc: {0x:8}\n", .{MAC_STATUS.read()});
        done = (tx_descs[0].d0.dma_own == 0);
    }
}
