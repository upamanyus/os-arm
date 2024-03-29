.section ".text"

.macro setup_exception_stack mode, stack_start
    msr cpsr, \mode
    mov sp, \stack_start
.endm

// See: https://github.com/alexhoppus/rpios/blob/29056459323f90868a10114e002315b0f7d8b626/kernel/boot.S#L80
// See: https://developer.arm.com/documentation/den0013/d/ARM-Processor-Modes-and-Registers
#define DAB_MODE  0x17
#define UND_MODE  0x1B
#define HYP_MODE  0x1A
#define SVC_MODE  0x13
#define IRQ_MODE  0x12
#define FIQ_MODE  0x11

#define MODE_MASK 0x1f

// void setup_exception_stacks(uint32_t *stacks)
.global setup_exception_stacks
setup_exception_stacks:
    ldr r1, [r0], #0x4
    setup_exception_stack #DAB_MODE, r1
    ldr r1, [r0], #0x4
    setup_exception_stack #UND_MODE, r1
    ldr r1, [r0], #0x4
    setup_exception_stack #HYP_MODE, r1
    ldr r1, [r0], #0x4
    // setup_exception_stack #SVC_MODE, r1
    // ldr r1, [r0], #0x4
    setup_exception_stack #IRQ_MODE, r1
    ldr r1, [r0], #0x4
    setup_exception_stack #FIQ_MODE, r1

    msr cpsr, SVC_MODE

    bx lr
