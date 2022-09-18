// From: https://www.scattered-thoughts.net/writing/mmio-in-zig/
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

pub fn Register(comptime T: type) type {
    return RWRegister(T, T);
}

pub fn RWRegister(comptime Read: type, comptime Write: type) type {
    comptime {
        if (@bitSizeOf(Read) != @bitSizeOf(u32)) {
            @compileError("mmio register: Read type must be 32 bits");
        }
        if (@bitSizeOf(Write) != @bitSizeOf(u32)) {
            @compileError("mmio register: Write type must be 32 bits");
        }
    }

    return struct {
        raw_reg: RawRegister,

        const Self = @This();

        pub fn init(address: usize) Self {
            return .{ .raw_reg = RawRegister.init(address) };
        }

        pub fn raw_read(self: Self) u32 {
            return self.raw_reg.read();
        }

        pub fn raw_write(self: Self, raw_w: u32) void {
            self.raw_reg.write(raw_w);
        }

        pub fn write(self: Self, w: Write) void {
            self.raw_reg.write(@bitCast(u32, w));
            // uart.printf("0x{0x}\n", .{self.raw_reg.read()});
        }

        pub fn read(self: Self) Read {
            return @bitCast(Read, self.raw_reg.read());
        }

        pub fn modify(self: Self, new_value: anytype) void {
            if (Read != Write) {
                @compileError("Can't modify because read and write types for this register aren't the same.");
            }

            var old_value = self.read();
            const info = @typeInfo(@TypeOf(new_value));
            // iterate over all fields in the "new_value" struct, and update those fields on the old_value
            inline for (info.Struct.fields) |field| {
                @field(old_value, field.name) = @field(new_value, field.name);
            }
            // then write the updated old_value back
            self.write(old_value);
        }
    };
}
