.section ".text.boot"

.global _start
_start:
    // set EL1 execution state to aarch64
    mov x0, (1 << 31)
    msr hcr_el2, x0

    // enable FPEN, so that EL1 and EL0 can use SIMD/FP registers, as Zig-generated code
    // (e.g. in printf) does.
    mov x0, (0b11 << 20)
    msr cpacr_el1, x0
    msr cptr_el2, x0

    mrs x0, sctlr_el1
    and x0, x0, #~0b11
    msr sctlr_el1, x0

    ldr x0, =_start
    add x0, x0, 8

    // Switch to EL1
    mov x0, 0b1111000101 // EL1 with interrupts disabled
    msr spsr_el2, x0
    ldr x0, =in_el1
    msr elr_el2, x0
    eret
in_el1:
    nop

    // set up exception handlers
    ldr x0, =exception_vectors
    msr vbar_el1, x0

    // read cpu id, stop slave cores
    mrs     x1, mpidr_el1
    and     x1, x1, #3
    cbz     x1, is_cpu0
    // if cpu id > 0, stop
not_cpu0:
    wfe
    b not_cpu0
is_cpu0:  // cpu id == 0

    // set top of stack just before our code (stack grows to a lower address per AAPCS64)
    ldr x1, =_start
    mov sp, x1

    // clear bss
    ldr x1, =__bss_start
    ldr w2, =__bss_size
bss_clear:
    cbz w2, after_bss_clear
    str xzr, [x1], #8
    sub w2, w2, #1
    cbnz  w2, bss_clear
after_bss_clear:

    // jump to C code, should not return
    bl kmain
    // for failsafe, halt this core too
    b not_cpu0
