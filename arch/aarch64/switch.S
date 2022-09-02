.section ".text"
// ref:
// https://stackoverflow.com/questions/32623597/arm-gcc-generated-functions-prolog

// void kproc_switch(struct kproc_context* old, struct kproc_context *to);

.global kproc_switch
.type kproc_switch, @function;
kproc_switch:
    // x0 is `old`, and x1 is `to`

    // save current state to old
    str lr, [x0, #0]
    mov x5, sp // x5 is caller-saved, so we can mess with it
    str x5, [x0, #0x8]
    str fp, [x0, #0x10]
    stp x19, x20, [x0, #0x18]
    stp x21, x22, [x0, #0x28]
    stp x23, x24, [x0, #0x38]
    stp x25, x26, [x0, #0x48]
    stp x27, x28, [x0, #0x58]
    // FIXME: save and restore v registers

    // load from to
    ldr lr, [x1, #0]
    ldr x5, [x1, #0x8]  // caller-saved, so we can mess with it
    mov sp, x5

    ldr fp, [x1, #0x10]
    ldp x19, x20, [x1, #0x18]
    ldp x21, x22, [x1, #0x28]
    ldp x23, x24, [x1, #0x38]
    ldp x25, x26, [x1, #0x48]
    ldp x27, x28, [x1, #0x58]

    // return to new
    ret

// HACK: this isn't actually a function following the normal ABI.
// For kproc context, we only save callee-saved registers. So, we put fn and
// args into x19 and x20, resp. This pseudo-function will put x20 into x0, and
// bl to fn, essentially invoking fn(args). After fn(args)
// returns, it calls kproc_exit() to do cleanup.
//
// It's kinda like void kproc_start(uint64_t fn, uint64_t args);

.global kproc_start
.type kproc_start, @function;
kproc_start:
    mov x0, x20
    // https://developer.arm.com/documentation/100076/0100/a64-instruction-set-reference/a64-general-instructions/bl
    blr x19
    bl kproc_exit // this will switch back to scheduler
