.section ".text"

// this is run when an exception triggers to save all the register state in
// memory.
.global exception_handler_entry
exception_handler_entry:
    mov sp,
    stp sp_usr

// sets up sp_undef, sp_prefetch, sp_abort, sp_irq, sp_undef
.global setup_exception_stacks
setup_exception_stacks:
