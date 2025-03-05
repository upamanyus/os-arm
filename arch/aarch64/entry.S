.section ".text"

// exception vector table
.macro vector_entry
.align 7
    bl undef_handler
.endm

.macro vector_entry12
.align 7
    bl undef_handler2
    // FIXME: this is incomplete. We need to save and restore all the registers
    // here.
    eret
.endm

.align 11 // XXX: why 11 bits?
exception_vectors:
    vector_entry
    vector_entry
    vector_entry
    vector_entry

    vector_entry12
    vector_entry
    vector_entry
    vector_entry

    vector_entry12
    vector_entry
    vector_entry
    vector_entry

    vector_entry
    vector_entry
    vector_entry
    vector_entry

.global trigger_undef
.type trigger_undef, @function
trigger_undef:
    hvc 37 // FIXME: lr (among other registers) changes across this call, which it should not.
    // udf #0xdead
    ret

.global get_el
.type get_el, @function
get_el:
    mrs x0, CurrentEL
    lsr x0, x0, #2
    ret

.global set_vbar
set_vbar:
    ldr     x0, =exception_vectors
    msr vbar_el2, x0
    ret

.global set_el
.type set_el, @function
set_el:
    mov x1, (1 << 31)       // EL1 uses aarch64
    msr hcr_el2, x1
    mov x1, sp
    msr sp_el1, x1

    mov x1, 0x3c5           // EL1h (SPSel = 1) with interrupt disabled
    msr spsr_el2, x1

    // enable FPEN, so that EL1 can use SIMD/FP registers, as Zig-generated code
    // (e.g. in printf) does.
    mov x1, (0b11 << 20)
    // msr cptr_el2, x1
    msr cpacr_el1, x1

    ldr x1, =fin
    msr elr_el2, x1
    eret
fin:
    ret
