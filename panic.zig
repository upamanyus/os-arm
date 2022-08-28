const uart = @import("uart.zig");

pub fn panic(msg: []const u8) noreturn {
    uart.puts(msg);
    while (true) {}
    unreachable;
}
