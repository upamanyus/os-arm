const uart = @import("uart.zig");
const panic = @import("panic.zig");
const kmem = @import("kmem.zig");

const MAX_CPUS = 1024;

// By the time an `execution_context` is executing, SP_EL1 will equal the
// address of the execution context in which its state should be stored if it gets
// stopped.

// TODO: this is architecture specific, so put it in `arch` directory.
const ExecutionContext = extern struct {
    x: [31]u64,
    sp_el0: u64,
    q: [32]u128,
    elr_el1: u64,
    spsr_el1: u64,
    fpsr: u64,
    fpcr: u64,
};

comptime {
    if (@sizeOf(ExecutionContext) > kmem.pgsize) {
        @compileError("execution_context: does not fit in a single page");
    }
}

export var dispatcher_stacks: [MAX_CPUS]u64 = undefined;

// Always allocated on its own page.
pub fn new_execution_context() *ExecutionContext {
    return @ptrFromInt(kmem.alloc_or_panic());
}

pub fn exit_execution_context() void {}

var ectx: *ExecutionContext = undefined;

pub fn init(init_fn: u64) void {
    uart.printf("Current EL: {0}\n", .{get_el()});
    dispatcher_stacks[0] = kmem.alloc_or_panic();
    ectx = @ptrFromInt(kmem.alloc_or_panic());

    ectx.x[0] = 0xdeadbeef;
    ectx.elr_el1 = init_fn;
    ectx.sp_el0 = kmem.alloc_or_panic();
    ectx.spsr_el1 = 0b1111_0_0_0000;
}

pub export fn dispatch() void {
    uart.puts("Dispatching.\n");
    switch_to_ectx(ectx);
}

extern fn switch_to_ectx(*ExecutionContext) void;

extern fn get_el() u64;

pub extern fn syscall() void;

// extern fn r_mpidr() u64;
// extern fn w_mpidr(u64);
