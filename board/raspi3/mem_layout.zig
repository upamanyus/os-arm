const std = @import("std");

pub const end = 0x3C100000; // This is *just past* the max allowed address.
// This number comes from looking at qemu-aarch64 raspi3 emulation, and noting
// that the last 64MiB (0x4000000 bytes) is reserved for VC ram. That includes a
// framebuffer, so writing to it causes the display to do things.
