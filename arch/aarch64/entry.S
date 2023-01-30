.section ".text"

// exception vector table
.macro vector_entry
.align 7
    bl undef_handler
.endm

.align 11 // XXX: why 11 bits?
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

.global trigger_undef
.type trigger_undef, @function
trigger_undef:
    udf #0xdead

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
