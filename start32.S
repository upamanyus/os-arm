.section ".text.boot"

.global _start
.global _halt

_start:
    // read cpu id, stop slave cores
    mrc     p15,    0,  r5, c0, c0, 5
    and     r5,     r5, #3
    cmp     r5,     r0
    // FIXME: for single-core rpizero, why doesn't this give r5 == 0?
    // beq     cpu0_start
    b cpu0_start
    // cpu id > 0, stop
_halt: wfe
    b  _halt
cpu0_start:  // cpu id == 0

    // set top of stack just before our code (stack grows to a lower address per AAPCS64)
    ldr     r5, =_start
    mov     sp, r5

    // clear bss
    ldr     r5, =__bss_start
    mov     r9, #0
3:  cmp     r9, r0
    beq     4f
    str     r0, [r5], #8 // r0 == 0 at the beginning of _start
    sub     r9, r9, #1
    b       3b

    // jump to C code, should not return
4:  bl      kmain
    // for failsafe, halt this core too
    b       _halt
