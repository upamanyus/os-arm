.section ".text"
// ref:
// https://stackoverflow.com/questions/32623597/arm-gcc-generated-functions-prolog

// void kproc_switch(struct kproc_context* old, struct kproc_context *to);

.global kproc_switch

// save r4-r8, r10, r11==fp, SP
kproc_switch:
    // x0 is `old`, and x1 is `to`

    // save current state to `old`
    str lr, [r0, #0]
    mov r2, sp // caller-saved, so we can mess with r2
    str r2, [r0, #0x4]
    str fp, [r0, #0x8]

    add r2, r0, #0xc
    stm r2, {r4-r8, r10}

    // load from `to`
    ldr lr, [r1, #0]
    ldr r2, [r1, #0x4]  // caller-saved, so we can mess with it
    mov sp, r2

    ldr fp, [r1, #0x8]
    add r2, r1, #0xc
    ldm r2, {r4-r8, r10}

    // return to new
    bx lr
