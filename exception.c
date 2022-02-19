#include "uart.h"

extern char vector_table[];
extern char vector_table_end[];

void fatal_unsupported_exception() {
    uart_puts("Unsupported ARM exception triggered\n");
    uart_puts("halting\n");
}

void svc_exception() {
    uart_puts("svc exception triggered\n");
    uart_puts("Halting\n");
}

void exception_init() {
    // copy 7 words from vector_table to address 0x00
    unsigned int n = (vector_table_end - vector_table)/4;
    for (unsigned int i = 0; i < n; i++) {
        *((uint32_t*)(0x00 + i*4)) = *(((uint32_t*)vector_table) + i);
    }
}
