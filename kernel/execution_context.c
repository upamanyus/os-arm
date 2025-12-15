#include "execution_context.h"
#include "uart.h"
#include "panic.h"
#include "kmem.h"

uint64_t dispatcher_stacks[MAX_CPUS];
static ExecutionContext *ectx;

ExecutionContext* new_execution_context(void) {
    return (ExecutionContext*)kmem_alloc_or_panic();
}

void exit_execution_context(void) {
    // This function is empty in the Zig code.
}

void execution_context_init(uint64_t init_fn_ptr) {
    uart_printf("Current EL: %d\n", get_el());
    dispatcher_stacks[0] = (uint64_t)kmem_alloc_or_panic();
    ectx = (ExecutionContext*)kmem_alloc_or_panic();

    ectx->x[0] = 0xdeadbeef;
    ectx->elr_el1 = init_fn_ptr;
    ectx->sp_el0 = (uint64_t)kmem_alloc_or_panic();
    ectx->spsr_el1 = 0b1111000000;
}

void dispatch(void) {
    uart_puts("Dispatching.\n");
    switch_to_ectx(ectx);
}

