const uart = @import("uart.zig");
const kmem = @import("kmem.zig");
const panic = @import("panic.zig");
const mem_layout = @import("mem_layout.zig");
const kproc = @import("kproc.zig");

const mac = @import("board/rockpiS/mac.zig");

fn kproc1(_: u64) void {
    uart.puts("kproc1: A\n");
    kproc.yield();
    uart.puts("kproc1: B\n");
    kproc.yield();
    uart.puts("kproc1: C\n");
}

fn kproc2(_: u64) void {
    uart.puts("kproc2: A\n");
    kproc.yield();
    uart.puts("kproc2: B\n");
    kproc.yield();
    uart.puts("kproc2: C\n");

    uart.puts("Triggering udf\n");
    kproc.trigger_undef();
    uart.puts("Done triggering udf\n");
}

fn main(_: u64) void {
    // uart.puts("Searching for MAC\n");
    // mac.init();
    // uart.puts("Finished searching for MAC\n");

    kproc.spawn(kproc1, 0);
    kproc.spawn(kproc2, 0);

    // FIXME: "wait" for background kprocs threads
    kproc.yield();
    kproc.yield();
    kproc.yield();
    kproc.yield();
    kproc.yield();

    uart.puts("waiting for input: \n");
    while (true) {
        var c = uart.getc();
        if (c == '\r') {
            uart.puts("\nExiting\n");
            return;
        }
        uart.putc(c);
    }
}

export fn undef_handler() void {
    uart.puts("undef caught\n");
}

export fn undef_handler2() void {
    uart.puts("undef2 caught\n");
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
    uart.printf("Current EL: {0}\n", .{get_el()});
    uart.printf("Current EL: {0}\n", .{get_el()});

    // FIXME: there seems to a some bug here
    kproc.init();
    uart.puts("Done initializing kproc\n");
    set_vbar();
    set_el();

    kproc.spawn(main, 0);
    kproc.schedulerLoop();

    panic.panic("end of kmain\n");
}

extern fn get_el() u64;
extern fn set_el() void;

extern fn set_vbar() void;
