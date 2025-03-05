const uart = @import("uart.zig");
const panic = @import("panic.zig");
const kmem = @import("kmem.zig");

// Multitasking approach.
// 1) "kernel procs" run in kernel address space and are cooperatively scheduled.
// `kproc.yield()` will yield control.
// 2) user procs that each run in a unique address space and are preempted.

// FIXME: move to arch folder
// callee-saved things that must be saved on kproc_switch()
const CooperativeContext = struct {
    lr: u64,
    sp: u64,
    fp: u64,
    x: [29 - 19 + 1]u64, // x19-x29 callee-saved
    v: [15 - 8 + 1]u64, // v8-x15 callee saved
};

const max = 1024;

const Process = struct {
    ctx: CooperativeContext,
    state: enum { inactive, idle, running, cleanup } = .inactive,

    // The process owns a stack page. Later this might become multiple pages etc.
    // The process must never overflow the stack, or unsafe behavior can occur.
    // This includes the stack space used when calling yield() to save
    // caller-saved registers.
    stack_addr: usize,
};

// TODO: make this a growable array.
var procs: [max]Process = undefined;

var nproc: u64 = 0; // number of currently active processes

const Func = fn (_: u64) void;

pub fn init() void {
    uart.printf("Procs using up {X} bytes of memory\n", .{@sizeOf(@TypeOf(procs))});
}

pub fn spawn(f: *const Func, args: u64) void {
    if (nproc == max) {
        panic.panic("ran out of kprocs\n");
    }
    for (&procs) |*proc| {
        if (proc.state == .inactive) {
            // found a proc, can return
            proc.ctx.x[0] = @intFromPtr(f); // in 64-bit, x19 = fn
            proc.ctx.x[1] = args; // in 64-bit, x20 = args
            proc.state = .idle;
            proc.stack_addr = kmem.alloc_or_panic();
            proc.ctx.sp = proc.stack_addr + kmem.pgsize; // top of stack, since it grows down
            proc.ctx.fp = proc.ctx.sp;
            proc.ctx.lr = @intFromPtr(&kproc_start);
            nproc += 1;
            return;
        }
    }
    panic.panic("unreachable\n");
}

var cur_proc: *Process = undefined;
var sched_ctx: CooperativeContext = undefined;

pub fn schedulerLoop() void {
    var took_step = true;
    while (took_step) {
        took_step = false;
        for (&procs) |*proc| {
            if (proc.state == .idle) {
                proc.state = .running;
                // run the proc
                cur_proc = proc;
                kproc_switch(&sched_ctx, &proc.ctx);

                // XXX: exit() will set the proc to cleanup to indicate that it
                // needs to be cleaned up.
                if (proc.state == .cleanup) {
                    kmem.free(proc.stack_addr); // cleanup
                    proc.state = .inactive;
                } else {
                    proc.state = .idle;
                }
            }
            took_step = true;
        }
    }
    uart.puts("No procs to run\n");
}

pub fn yield() void {
    kproc_switch(&cur_proc.ctx, &sched_ctx);
}

comptime {
    @export(exit, .{ .name = "kproc_exit", .linkage = .strong });
}

fn exit() callconv(.C) void {
    nproc -= 1;
    cur_proc.state = .cleanup;
    uart.puts("process exiting\n");
    yield();
}

extern fn kproc_switch(old: *CooperativeContext, new: *CooperativeContext) void;
extern fn kproc_start() void;

pub extern fn trigger_undef() void;
