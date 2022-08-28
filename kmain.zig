const uart = @import("uart.zig");
const kmem = @import("kmem.zig");
const panic = @import("panic.zig");
const mem_layout = @import("mem_layout.zig");

export fn kmain() void {
    uart.init();
    uart.puts("Serial initialized\n");
    // uart.printf("kmem_end = {0x}\n", mem_layout.kern_end);
    uart.printf("kmem_end = {0x}\n", .{@ptrToInt(&mem_layout.__kern_end)});
    // uart.puts("Initializing kmem\n");
    kmem.init();
    uart.puts("Done initializing kmem\n");
    uart.puts("Hello world!\n");
    panic.panic("end of kmain\n");
}
