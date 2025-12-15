.section ".text"

// Exception handlers jump here.
switch_to_dispatcher:
    // Save all user process state on the current execution context, which has
    // address sp_el1.

    // Save x{0-30} and sp_el0.
    stp x0, x1, [sp, #16*0]
    stp x2, x3, [sp, #16*1]
    stp x4, x5, [sp, #16*2]
    stp x6, x7, [sp, #16*3]
    stp x8, x9, [sp, #16*4]
    stp x10, x11, [sp, #16*5]
    stp x12, x13, [sp, #16*6]
    stp x14, x15, [sp, #16*7]
    stp x16, x17, [sp, #16*8]
    stp x18, x19, [sp, #16*9]
    stp x20, x21, [sp, #16*10]
    stp x22, x23, [sp, #16*11]
    stp x24, x25, [sp, #16*12]
    stp x26, x27, [sp, #16*13]
    stp x28, x29, [sp, #16*14]
    mrs x0, sp_el0  // access user-space stack pointer (sp is currently sp_el1)
    stp x30, x0, [sp, #16*15]
    add sp, sp, #16*16

    // Save Q{0-31}.
    stp q0, q1, [sp, #32*0]
    stp q2, q3, [sp, #32*1]
    stp q4, q5, [sp, #32*2]
    stp q6, q7, [sp, #32*3]
    stp q8, q9, [sp, #32*4]
    stp q10, q11, [sp, #32*5]
    stp q12, q13, [sp, #32*6]
    stp q14, q15, [sp, #32*7]
    stp q16, q17, [sp, #32*8]
    stp q18, q19, [sp, #32*9]
    stp q20, q21, [sp, #32*10]
    stp q22, q23, [sp, #32*11]
    stp q24, q25, [sp, #32*12]
    stp q26, q27, [sp, #32*13]
    stp q28, q29, [sp, #32*14]
    stp q30, q31, [sp, #32*15]
    add sp, sp, #32*16

    // Save elr, pstate.
    mrs x0, elr_el1
    // add x0, x0, #4 // FIXME: this increases the returned PC by 4
    mrs x1, spsr_el1 // stores pstate
    stp x0, x1, [sp, #(16*0)]
    // Save fpsr, fpcr.
    mrs x0, fpsr
    mrs x1, fpcr
    stp x0, x1, [sp, #(16*1)]
    add sp, sp, #16*2

    // load per-CPU dispatcher stack pointer
    mrs x0, mpidr_el1
    and x0, x0, 0x7fffff // mask to get [aff2 ++ aff1 ++ aff0]
    lsl x0, x0, #3 // each element of dispatcher_stack is 8 bytes, so multiply x0 by 8
    ldr x1, =dispatcher_stacks
    ldr x1, [x1, x0]
    mov sp, x1

    // jump to dispatcher
    b dispatch


// fn switch_to_ectx(*ExecutionContext) void;
.global switch_to_ectx
.type switch_to_ectx, @function
switch_to_ectx:
    // Set sp to the starting address of the target ExecutionContext.
    mov sp, x0

    add sp, sp, #16*16
    add sp, sp, #32*16

    // Restore elr, pstate.
    ldp x0, x1, [sp, #(16*0)]
    msr elr_el1, x0
    msr spsr_el1, x1 // stores pstate
    // Restore fpsr, fpcr.
    ldp x0, x1, [sp, #(16*1)]
    msr fpsr, x0
    msr fpcr, x1

    // Save Q{0-31}.
    sub sp, sp, #32*16
    ldp q0, q1, [sp, #32*0]
    ldp q2, q3, [sp, #32*1]
    ldp q4, q5, [sp, #32*2]
    ldp q6, q7, [sp, #32*3]
    ldp q8, q9, [sp, #32*4]
    ldp q10, q11, [sp, #32*5]
    ldp q12, q13, [sp, #32*6]
    ldp q14, q15, [sp, #32*7]
    ldp q16, q17, [sp, #32*8]
    ldp q18, q19, [sp, #32*9]
    ldp q20, q21, [sp, #32*10]
    ldp q22, q23, [sp, #32*11]
    ldp q24, q25, [sp, #32*12]
    ldp q26, q27, [sp, #32*13]
    ldp q28, q29, [sp, #32*14]
    ldp q30, q31, [sp, #32*15]

    // Restore x{0-30} and sp_el0.
    sub sp, sp, #16*16
    ldp x30, x0, [sp, #16*15]
    msr sp_el0, x0 // access user-space stack pointer (sp is currently sp_el1)
    ldp x0, x1, [sp, #16*0]
    ldp x2, x3, [sp, #16*1]
    ldp x4, x5, [sp, #16*2]
    ldp x6, x7, [sp, #16*3]
    ldp x8, x9, [sp, #16*4]
    ldp x10, x11, [sp, #16*5]
    ldp x12, x13, [sp, #16*6]
    ldp x14, x15, [sp, #16*7]
    ldp x16, x17, [sp, #16*8]
    ldp x18, x19, [sp, #16*9]
    ldp x20, x21, [sp, #16*10]
    ldp x22, x23, [sp, #16*11]
    ldp x24, x25, [sp, #16*12]
    ldp x26, x27, [sp, #16*13]
    ldp x28, x29, [sp, #16*14]

    // jump to execution context
    eret


// each entry is 16 bytes, so pad align to 7 bits
.macro vector_entry
.align 7
    b switch_to_dispatcher
.endm

// exception vector table
.global exception_vectors
.align 11 // 2KiB aligned
exception_vectors:
    vector_entry
    vector_entry
    vector_entry
    vector_entry

    vector_entry
    vector_entry
    vector_entry
    vector_entry

    vector_entry
    vector_entry
    vector_entry
    vector_entry

    vector_entry
    vector_entry
    vector_entry
    vector_entry

.global get_el
.type get_el, @function
get_el:
    mrs x0, CurrentEL
    lsr x0, x0, #2
    ret

.global set_vbar
set_vbar:
    ldr x0, =exception_vectors
    msr vbar_el1, x0
    ret

.global set_el
.type set_el, @function
set_el:
    mov x1, (1 << 31)       // set EL1 execution state to aarch64
    msr hcr_el2, x1
    mov x1, sp
    msr sp_el1, x1

    // enable FPEN, so that EL1 and EL0 can use SIMD/FP registers, as Zig-generated code
    // (e.g. in printf) does.
    mov x1, (0b11 << 20)
    msr cpacr_el1, x1

    // set up eret to end up in el1
    mov x1, 0b1111000101 // EL1 with interrupts disabled
    msr spsr_el2, x1
    ldr x1, =fin
    msr elr_el2, x1
    eret
fin:
    ret

.global syscall
.type syscall, @function
syscall:
    svc #0
    ret
