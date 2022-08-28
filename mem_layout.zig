const std = @import("std");
pub const end = 0x3C100000; // This is *just past* the max allowed address.
// This number comes from looking at qemu-aarch64 raspi3 emulation, and noting
// that the last 64MiB (0x4000000 bytes) is reserved for VC ram. That includes a
// framebuffer, so writing to it causes the display to do things.

pub const trampoline = 0xFFFFF000;

pub extern var __kern_end: [*]u8;

// FIXME: this doesn't work, even though it seems like it should.
// https://github.com/ziglang/zig/pull/5349
// pub var kern_end: usize = @ptrToInt(&__kern_end);
