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
var MAC_GMII_ADDR = mmio.Register(MiiAddrVal).init(base + 0x10);

const MiiDataVal = packed struct {
    data: u16,
    _reserved: u16 = 0,
};
var MAC_GMII_DATA = mmio.Register(MiiDataVal).init(base + 0x14);

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

fn phy_reset() void {
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
    phy_reset();

    uart.printf("Synopsys ID: 0x{0x}\n", .{SYNOPSYS_ID.read()});

    // set up GRF_MAC_CON0 grf_con_mac2io_phy_intf_sel
    uart.printf("Old GRF_MAC_CON0 = 0x{0x}\n", .{GRF_MAC_CON0.read()});
    GRF_MAC_CON0.write((0b100 << 2) | (0b111 << (2 + 16)) | (1) | (1 << 16));
    uart.printf("new GRF_MAC_CON0 = 0x{0x}\n", .{GRF_MAC_CON0.read()});

    MAC_MAC_CONF.write(1 << 15 | 1 << 14 | 1 << 8); // 15 = port-select, MII; 8 = "link up"; 14 = 100Mpbs

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

const TxDescriptor0and1 = packed struct {
    // TDES0
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

    // TDES1
    transmit_buffer1_size: u11 = 0,
    transmit_buffer2_size: u11 = 0,
    _reserved2: u1 = 0,
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
    tx: TxDescriptor0and1 = TxDescriptor0and1{},

    // these together should make a u64
    buffer1_addr: u32 = 0,
    buffer2_addr: u32 = 0,
};

const RxDescriptor0and1 = packed struct {
    // RDES0
    _unspecified1: u16 = 0,
    frame_length: u14 = 0,
    dst_filter_fail: u1 = 0,
    dma_own: u1 = 0, // true iff DMA owns this descriptor

    // TDES1
    buffer1_size: u11 = 0,
    buffer2_size: u11 = 0,
    _reserved: u2 = 0,
    second_addr_chained: u1 = 0,
    end_of_ring: u1 = 0,
    _reserved2: u5 = 0,
    disable_interrupt: u1 = 0,
};

const RxDescriptor = packed struct {
    rx: RxDescriptor0and1 = RxDescriptor0and1{},

    // these together should make a u64
    buffer1_addr: u32 = 0,
    buffer2_addr: u32 = 0,
};

var MAC_RX_DESC_LIST_ADDR = mmio.RawRegister.init(base + 0x100c);
var MAC_TX_DESC_LIST_ADDR = mmio.RawRegister.init(base + 0x1010);

const MacOpModeVal = packed struct {
    _reserved: u1 = 0,
    start_receive: u1 = 0,
    _unused: u11 = 0,
    start_transmit: u1 = 0,
    _unused2: u18 = 0,
};

var MAC_OP_MODE = mmio.Register(MacOpModeVal).init(base + 0x1018);

// FIXME: if we put the real bit layout here, then zig complains that the packed
// struct is 5 bytes (while only taking up 32 bits).This is fixed in zig 0.10,
// but inline assembly is a bit broken in 0.10 as well.
const MacBusModeVal = packed struct {
    software_reset: u1 = 0,
    _unused4: u31 = 0,
};

var MAC_BUS_MODE = mmio.Register(MacBusModeVal).init(base + 0x1000);

fn soft_reset_mac() void {
    uart.printf("Initial BUS_MODE: {0x:8}\n", .{MAC_BUS_MODE.raw_read()});
    MAC_BUS_MODE.write(MacBusModeVal{ .software_reset = 1 });
    var num_cycles_to_reset: usize = 0;
    while (MAC_BUS_MODE.read().software_reset == 1) {
        num_cycles_to_reset += 1;
    }

    // set 8xPBL_MODE (bit 24); set "fixed burst" mode (bit 16);
    // sets pbl = 8 (bits [13:8])
    // MAC_BUS_MODE.raw_write(MAC_BUS_MODE.raw_read() | (1 << 16) | (1 << 24) | (8 << 8));
    // MAC_BUS_MODE.raw_write(MAC_BUS_MODE.raw_read() | (1 << 16) | (1 << 24) | (8 << 8));

    uart.printf("Reset took {0} cycles\n", .{num_cycles_to_reset});
    uart.printf("New BUS_MODE: {0x:8}\n", .{MAC_BUS_MODE.raw_read()});
    // MAC_BUS_MODE.modify(.{ .pbl = 0x8 });
    uart.puts("MAC reset done\n");

    uart.printf("Post soft-reset GRF_MAC_CON0 = 0x{0x}\n", .{GRF_MAC_CON0.read()});
}

comptime {
    if (@bitSizeOf(TxDescriptor0and1) != @bitSizeOf(u64)) {
        @compileError("TxDesc0and1 not sized correctly");
    }
}

comptime {
    if (@bitSizeOf(RxDescriptor0and1) != @bitSizeOf(u64)) {
        @compileError("RxDesc0and1 not sized correctly");
    }
}

var MAC_STATUS = mmio.RawRegister.init(base + 0x1014);

pub fn setup_packet(p: [*]u8) void {
    var i: usize = 0;
    while (i < 6) : (i += 1) {
        p[i] = 0xff;
    }

    p[i] = 0xde;
    i += 1;
    p[i] = 0xad;
    i += 1;
    p[i] = 0xbe;
    i += 1;
    p[i] = 0xef;
    i += 1;
    p[i] = 0xcc;
    i += 1;
    p[i] = 0xcc;
    i += 1;

    p[i] = 0x08;
    i += 1;
    p[i] = 0x06;
    i += 1;

    // now the data
    p[i] = 'h';
    i += 1;
    p[i] = 'e';
    i += 1;
    p[i] = 'l';
    i += 1;
    p[i] = 'l';
    i += 1;
    p[i] = 'o';
    i += 1;
}

pub fn get_sctrl() u64 {
    return asm volatile ("mrs %[ret], sctlr_el1"
        : [ret] "={x1}" (-> usize),
        :
        : "x1"
    );
}

var MAC_TX_POLL_DEMAND = mmio.RawRegister.init(base + 0x1004);
var MAC_RX_POLL_DEMAND = mmio.RawRegister.init(base + 0x1008);

const cru_base: usize = 0xff500000;

var CRU_CLKSEL_CON43 = mmio.RawRegister.init(cru_base + 0x01ac);
pub fn set_clk_rate() void {
    CRU_CLKSEL_CON43.write((0b11111 << 16) | 0x1d | (1 << 14) | ((1 << 14) << 16));
    uart.puts("Set mac clock to 25MHz, and rmii_extclk_sel = from CRU\n");
}

var MAC_CUR_HOST_TX_DESC = mmio.RawRegister.init(base + 0x1048);
var MAC_CUR_HOST_RX_DESC = mmio.RawRegister.init(base + 0x104c);
var MAC_CUR_HOST_TX_BUF_ADDR = mmio.RawRegister.init(base + 0x1050);
var MAC_CUR_HOST_RX_BUF_ADDR = mmio.RawRegister.init(base + 0x1054);

// returns a pointer to the beginning of RX_DESC_LIST
pub fn setup_rx_desc() usize {
    const rx_descs_addr = kmem.alloc_or_panic();
    var rx_descs = @intToPtr([*]volatile RxDescriptor, rx_descs_addr);
    // set up 4 descriptors
    var i: usize = 0;
    while (i < 4) : (i += 1) {
        rx_descs[i] = RxDescriptor{};
        rx_descs[i].rx.dma_own = 1;
        rx_descs[i].rx.disable_interrupt = 1;
        rx_descs[i].buffer1_addr = @intCast(u32, kmem.alloc_or_panic());
        uart.printf("RX buffer = {0x}\n", .{rx_descs[i].buffer1_addr});
        rx_descs[i].rx.buffer1_size = 1024;
    }
    rx_descs[3].rx.end_of_ring = 1;
    return rx_descs_addr;
}

var MAC_AN_CTRL = mmio.RawRegister.init(base + 0x00c0);
var MAC_AN_STATUS = mmio.RawRegister.init(base + 0x00c4);
var MAC_AN_ADV = mmio.RawRegister.init(base + 0x00c8);
var MAC_INTF_MODE_STA = mmio.RawRegister.init(base + 0x00d8);

pub fn auto_negotiate() void {
    // start negotiation
    uart.puts("About to start auto-negotiation\n");
    uart.printf("Got {0x} from autonegotiation initially\n", .{MAC_AN_STATUS.read()});
    uart.printf("Got {0x} from advertise register initially\n", .{MAC_AN_ADV.read()});
    MAC_AN_CTRL.write(1 << 12);

    if (false) {
        var num_iters: usize = 0;
        while (true) : (num_iters += 1) {
            const status = MAC_AN_STATUS.read();
            uart.printf("Got {0x} from autonegotiation after {1} iters\n", .{ status, num_iters });
            if (status & (1 << 5) == 1) {
                break;
            }
        }
    }
}

pub fn try_flush_cache() void {
    const random_page = kmem.alloc_or_panic();
    var i: usize = 0;
    while (i < 4096) : (i += 8) {
        @intToPtr(*volatile u64, random_page + i).* = i;
    }
}

pub fn setup_and_send_one() void {
    soft_reset_mac();
    set_clk_rate();
    // auto_negotiate();

    var tx_msg: usize = kmem.alloc_or_panic();

    // Set up message being sent. Make it sequentially increasing bytes. Will
    // make this a valid ethernet frame later.
    // var tx_msg_ptr = @intToPtr([*]u8, tx_msg);
    // set the mac address
    // setup_packet(tx_msg_ptr);

    const tx_descs_addr = kmem.alloc_or_panic();

    uart.printf("Allocated {0x} then {1x}\n", .{ tx_msg, tx_descs_addr });
    var tx_descs = @intToPtr([*]volatile TxDescriptor, tx_descs_addr);

    uart.printf("sctrl = {0x}\n", .{get_sctrl()});

    tx_descs[0] = TxDescriptor{}; // zero out
    // Set up TX descriptor ring. Need to set "end of ring" on last one.
    tx_descs[0].tx.end_of_ring = 0;
    tx_descs[0].buffer1_addr = @intCast(u32, tx_msg);
    tx_descs[0].buffer2_addr = @intCast(u32, tx_msg);
    tx_descs[0].tx.transmit_buffer1_size = 1024;
    tx_descs[0].tx.transmit_buffer2_size = 0;
    tx_descs[0].tx.first_segment = 1;
    tx_descs[0].tx.last_segment = 1;
    tx_descs[0].tx.dma_own = 1;

    tx_descs[3].tx.end_of_ring = 1;
    uart.printf("TX desc value before sending: {0}\n", .{tx_descs[0]});

    // Tell MAC where to find TX descriptors
    MAC_TX_DESC_LIST_ADDR.write(@intCast(u32, @ptrToInt(tx_descs)));
    uart.printf("TX desc reg addr: {0x}; tx addr: {1x}\n", .{ MAC_TX_DESC_LIST_ADDR.read(), @ptrToInt(&tx_descs[0]) });
    uart.printf("Tx desc0and1 = {0x}\n", .{@intToPtr(*u64, MAC_TX_DESC_LIST_ADDR.read()).*});
    uart.printf("Tx desc2and3 = {0x}\n", .{@intToPtr(*u64, MAC_TX_DESC_LIST_ADDR.read() + 8).*});

    uart.printf("STATUS before transfer desc: {0x:8}\n", .{MAC_STATUS.read()});

    // Tell MAC where to find RX descriptors
    const rx_descs_addr = setup_rx_desc();
    MAC_RX_DESC_LIST_ADDR.write(@intCast(u32, rx_descs_addr));

    uart.printf("Before enabling DMA, cur tx desc = {0x}; cur tx buffer = {1x}\n", .{ MAC_CUR_HOST_TX_DESC.read(), MAC_CUR_HOST_TX_BUF_ADDR.read() });
    uart.printf("Before enabling DMA, cur rx desc = {0x}; cur rx buffer = {1x}\n", .{ MAC_CUR_HOST_RX_DESC.read(), MAC_CUR_HOST_RX_BUF_ADDR.read() });

    // try_flush_cache();
    // try_flush_cache();
    // try_flush_cache();
    // try_flush_cache();
    // try_flush_cache();
    // try_flush_cache();

    // Enable MAC TX+RX DMA.
    MAC_OP_MODE.write(.{ .start_transmit = 1, .start_receive = 1 });
    uart.puts("Enabled DMAs\n");
    while (true) {
        // const cur_buffer = MAC_CUR_HOST_TX_BUF_ADDR.read();
        const cur_buffer = MAC_CUR_HOST_RX_BUF_ADDR.read();
        // const cur_buffer = MAC_TX_DESC_LIST_ADDR.read();
        if (cur_buffer != 0) {
            uart.printf("After enabling TX DMA, first non-zero cur tx buffer = {0x}\n", .{cur_buffer});
            uart.printf("After enabling DMA, cur rx desc = {0x}\n", .{MAC_CUR_HOST_RX_DESC.read()});
            uart.printf("After enabling DMA, cur rx buffer = {0x}\n", .{MAC_CUR_HOST_RX_BUF_ADDR.read()});
            break;
        }
    }
    uart.puts("Enabled transmit DMA\n");
    uart.printf("RxDesc0 {0x}, ", .{@intToPtr(*volatile u64, rx_descs_addr).*});
    uart.printf("RxDesc1 {0x}\n", .{@intToPtr(*volatile u64, rx_descs_addr + 8).*});

    // Enable MAC transmit; TRM says to do this after enabling MAC TX DMA (pg
    // 522).
    var old_val = MAC_MAC_CONF.read();
    MAC_MAC_CONF.write(old_val | (1 << 3) | (1 << 2));
    uart.puts("Enabled transmit in MAC_MAC_CONF; about to demand TX poll\n");

    MAC_RX_POLL_DEMAND.write(0x0);

    var cur_status: u32 = 0;
    var num_cycles1: usize = 0;
    while (true) {
        cur_status = MAC_STATUS.read();
        if ((cur_status >> 17 & 0b111) != 0b001) {
            break;
        }
        num_cycles1 += 1;
    }
    uart.printf("STATUS after first 1st phase: {0x}\n", .{cur_status});

    uart.printf("After enabling DMA, cur tx desc = {0x}; cur tx buffer = {1x}\n", .{ MAC_CUR_HOST_TX_DESC.read(), MAC_CUR_HOST_TX_BUF_ADDR.read() });

    var num_cycles2: usize = 0;
    // while ((MAC_STATUS.read() >> 20 & 0b111) == 0b011) : (num_cycles2 += 1) {}
    uart.printf("{0} iters for fetching descriptor; {1} iters for reading buffer\n", .{
        num_cycles1, num_cycles2,
    });
    // uart.printf("STATUS after first 2 phases: {0x}\n", .{MAC_STATUS.read()});
    //
    // uart.printf("MAC STATUS right after sending: {0x:8}\n", .{MAC_STATUS.read()});

    uart.puts("Finished starting send message\n");
    var done: bool = false;
    while (!done) {
        uart.printf("Current TX desc: {0}\n", .{tx_descs[0]});
        uart.printf("Current STATUS desc: {0x:8}\n", .{MAC_STATUS.read()});
        done = (tx_descs[0].tx.dma_own == 0);
    }
}
