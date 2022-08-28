const uart = @import("uart.zig");

// pub fn comptime_init() void {
// comptime {
// // call init for all the different subsystems
// uart.comptime_init()
// }
// }

export fn kmain() void {
    uart.uart_init();
    uart.putc('H');
    uart.putc('e');
    uart.putc('l');
    uart.putc('l');
    uart.putc('o');
    uart.putc('\n');
}
