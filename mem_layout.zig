const std = @import("std");

const rockpiS = @import("board/rockpiS/mem_layout.zig");
const raspi3 = @import("board/raspi3/mem_layout.zig");

const impl = raspi3;
// const impl = rockpiS;

pub extern const __kern_end: [*]u8;
// FIXME: this doesn't work, even though it seems like it should.
// https://github.com/ziglang/zig/pull/5349
// pub export var kern_end = __kern_end;

// TODO: for now, just one continuous range of memory
pub var start: usize = undefined;
pub var end: usize = undefined;

pub fn init() void {
    // impl.init();
    start = @intFromPtr(&__kern_end);
    end = impl.end;
}
