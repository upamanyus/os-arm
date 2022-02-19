.section ".text"

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
    .word invalid_handler
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

svc_handler:
    bl  svc_exception
    bl   _halt

invalid_handler:
    bl  fatal_unsupported_exception
    bl   _halt

// FIXME: I think this should work on rpi zero, but it doesn't on qemu
// void exception_init();
// .global exception_init
// exception_init:
    // ldr r1, vector_table
    // mcr p15,0,r1,c12,c0,0
    // bx lr

// void exception_trigger();
.global exception_trigger
exception_trigger:
    svc #0
    bx lr
