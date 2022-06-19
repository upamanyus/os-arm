#include "uart.h"
#include "entry.h"
#include "kmem.h"

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
    // allocate pages for various exception stacks
    uint32_t addrs[6];

    for (int i = 0; i < 6; i++) {
        addrs[i] = (uint32_t)kmem_alloc();
    }

    setup_exception_stacks(addrs);

    // copy 7 words from vector_table to address 0x00
    unsigned int n = (vector_table_end - vector_table)/4;
    for (unsigned int i = 0; i < n; i++) {
        *((uint32_t*)(0x00 + i*4)) = *(((uint32_t*)vector_table) + i);
    }
}
