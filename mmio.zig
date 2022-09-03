// https://www.scattered-thoughts.net/writing/mmio-in-zig/
pub const RawRegister = struct {
    raw_ptr: *volatile u32,

    const Self = @This();

    pub fn init(address: usize) Self {
        return .{ .raw_ptr = @intToPtr(*u32, address) };
    }

    pub fn read(self: Self) u32 {
        return self.raw_ptr.*;
    }

    pub fn write(self: Self, value: u32) void {
        self.raw_ptr.* = value;
    }
};
