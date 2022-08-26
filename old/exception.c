#include "uart.h"
#include "entry.h"
#include "kmem.h"
#include "exception.h"

extern char vector_table[];
extern char vector_table_end[];
extern char vector_table_end[];

void fatal_unsupported_exception() {
    uart_puts("Unsupported ARM exception triggered\n");
    uart_puts("halting\n");
}

void svc_exception() {
    uart_puts("svc exception triggered\n");
    uart_puts("continuing with program\n");
}

void exception_init() {
    // Allocate pages for various exception stacks.
    uint32_t addrs[6];
    for (int i = 0; i < 6; i++) {
        addrs[i] = (uint32_t)kmem_alloc();
    }

    setup_exception_stacks(addrs);
    exception_init_vbar(TRAMPOLINE);
}
