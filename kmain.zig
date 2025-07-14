const uart = @import("uart.zig");
const kmem = @import("kmem.zig");
const panic = @import("panic.zig");
const mem_layout = @import("mem_layout.zig");
const delay = @import("arch/aarch64/delay.zig");
const execution_context = @import("execution_context.zig");

export fn init(arg: u64) void {
    uart.printf("Reached init with arg: 0x{0x}\n", .{arg});
    execution_context.syscall();
    uart.puts("Back to init!");
    _ = uart.getc();
}

export fn kmain() void {
    uart.init();
    uart.puts("Serial initialized\n");
    uart.puts("Calling delay.delay...");
    delay.delay(100);
    uart.puts("done.\n");

    // mem_layout.init();
    uart.printf("kmem_end = 0x{0x}\n", .{@intFromPtr(&mem_layout.__kern_end)});
    uart.puts("Initializing kmem...");
    kmem.init();
    uart.puts("done.\n");

    uart.puts("Initializing router...");
    execution_context.init(@intFromPtr(&init));
    uart.puts("done.\n");

    execution_context.dispatch();

    panic.panic("end of kmain\n");
}
