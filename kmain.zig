const uart = @import("uart.zig");
const kmem = @import("kmem.zig");
const panic = @import("panic.zig");
const mem_layout = @import("mem_layout.zig");
const kproc = @import("kproc.zig");

const mac = @import("board/rockpiS/mac.zig");

fn main(_: u64) void {
    uart.puts("Searching for MAC\n");
    mac.init();
    uart.puts("Finished searching for MAC\n");
}

export fn kmain() void {
    uart.init();
    uart.puts("Serial initialized\n");
    // uart.printf("kmem_end = {0x}\n", mem_layout.kern_end);
    uart.printf("kmem_end = {0x}\n", .{@ptrToInt(&mem_layout.__kern_end)});
    uart.puts("Initializing kmem\n");
    kmem.init();
    uart.puts("Done initializing kmem\n");
    uart.puts("Initializing kproc\n");

    // kproc.init();
    // kproc.spawn(main, 0);
    // kproc.schedulerLoop();

    main(0);

    uart.puts("Done initializing kproc\n");
    panic.panic("end of kmain\n");
}
