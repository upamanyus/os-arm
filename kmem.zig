const mem_layout = @import("mem_layout.zig");
const panic = @import("panic.zig");

const pgbits = 12;
pub const pgsize = (1 << pgbits);

const Node = struct {
    next: ?*Node,
};

var freelist: ?*Node = null;

pub fn init() void {
    // allocate single pages until curr_page is aligned with 16KB boundary
    mem_layout.init();

    var addr: usize = mem_layout.start;

    while (addr + pgsize < mem_layout.end) {
        free(addr);
        addr += pgsize;
    }
}

fn pgdown(addr: usize) usize {
    return (addr >> pgbits) << pgbits;
}

fn pgup(addr: usize) usize {
    return pgdown(addr + (pgsize - 1));
}

// Takes in ownership of the page starting at `addr`.
pub fn free(addr: usize) void {
    // requires addr to be page aligned
    @intToPtr(*Node, addr).next = freelist;
    freelist = @intToPtr(*Node, addr);
}

// Returns ownership of the page starting at the returned address.
pub fn alloc() !usize {
    if (freelist) |addr| {
        return @ptrToInt(addr);
    } else {
        return error.OutOfMemoryy;
    }
}

pub fn alloc_or_panic() usize {
    return alloc() catch panic.panic("out of memory");
}
