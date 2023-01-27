const std = @import("std");
const panic = @import("panic.zig");

const raspi3 = @import("board/raspi3/uart.zig");
const rockpiS = @import("board/rockpiS/uart.zig");

const impl = raspi3;
// const impl = rockpiS;

pub const init = impl.init;

pub const putc = impl.putc;
pub const getc = impl.getc;

pub fn puts(s: []const u8) void {
    for (s) |c| {
        putc(c);
    }
}

const NoError = error{};
const Unit = struct {};

fn writeFn(_: Unit, b: []const u8) NoError!usize {
    puts(b);
    return b.len;
}

pub fn printf(comptime fmt: []const u8, args: anytype) void {
    var writer: std.io.Writer(Unit, NoError, writeFn) = .{ .context = .{} };
    // XXX: maybe use std.io.Writer()
    std.fmt.format(writer, fmt, args) catch panic.panic("printf failed");
}
