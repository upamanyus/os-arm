.section ".text"

// HACK: this isn't actually a function following the normal ABI.
// For kproc context, we only save callee-saved registers. So, we put fn and
// args into x19 and x20, resp. This pseudo-function will put x20 into x0, and
// bl to fn, essentially invoking fn(args). After fn(args)
// returns, it calls kproc_exit() to do cleanup.
//
// It's kinda like void kproc_start(uint64_t fn, uint64_t args);

.global kproc_start
kproc_start:
    mov x0, x20
    // https://developer.arm.com/documentation/100076/0100/a64-instruction-set-reference/a64-general-instructions/bl
    blr x19
    bl kproc_exit // this will switch back to scheduler
