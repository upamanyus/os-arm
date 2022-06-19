.section ".text"

// NOTE: this could be put in the "start" code directly too.
// Benefit of copying it after the kernel starts is that we can use an
// off-the-shelf bootloader (e.g. u-boot has its own handlers in its _start).
.global vector_table
// ref:
// https://developer.arm.com/documentation/dui0471/m/handling-processor-exceptions/vector-table-for-armv6-and-earlier--armv7-a-and-armv7-r-profiles?lang=en
vector_table:
    ldr pc, reset_addr
    ldr pc, undef_addr
    ldr pc, svc_addr
    ldr pc, prefetch_addr
    ldr pc, abort_addr
    nop         // Reserved vector
    ldr pc, irq_addr

reset_addr:
    .word invalid_handler
undef_addr:
    .word svc_handler
svc_addr:
    .word svc_handler
prefetch_addr:
    .word invalid_handler
abort_addr:
    .word invalid_handler
irq_addr:
    .word invalid_handler

.global vector_table_end
vector_table_end:

.macro save_caller_regs
    // Only save caller-saved registers.
    // Callee-saved registers will be saved by the C function that will be
    // called shortly.
    //
    push {r0-r3,r9,r12,r14}

    // save cpsr
    mrs r0, spsr
    push    {r0}

    // save sp_usr and lr_usr
    mov r0, sp
    stmdb   r0, {sp, lr}^
    sub sp, #8
.endm

.macro restore_caller_regs_and_ret
    mov r0, sp
    ldmia r0, {sp, lr}^
    add sp, #8

    pop {r0}
    msr spsr, r0

    pop {r0-r3,r9,r12,r14}
    movs pc, lr
.endm

svc_handler:
    save_caller_regs
    bl  svc_exception
    restore_caller_regs_and_ret
    // bx  lr
    bl  _halt

invalid_handler:
    bl  fatal_unsupported_exception
    bl   _halt

// FIXME: I think this should work on rpi zero, but it doesn't on qemu
// rpi zero uses arm1176, which supposedly supports vbar.
// void exception_init();
// .global exception_init
// exception_init:
    // ldr r1, vector_table
    // mcr p15,0,r1,c12,c0,0
    // bx lr

// void exception_trigger();
.global exception_trigger
exception_trigger:
    .word 0xe0700090
    bx lr
