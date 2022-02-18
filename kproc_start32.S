.section ".text"
// Kinda like void kproc_start(uint64_t fn, uint64_t args);

.global kproc_start
kproc_start:
    mov r0, r5
    // https://developer.arm.com/documentation/100076/0100/a64-instruction-set-reference/a64-general-instructions/bl
    blx r4
    bl kproc_exit // this will switch back to scheduler
