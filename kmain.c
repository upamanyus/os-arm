#include <stddef.h>
#include <stdint.h>

#include "uart.h"
#include "kmem.h"
#include "kproc.h"
#include "exception.h"

void test_kproc_t1(uint32_t args)
{
    uart_puts("[T1]: A\r\n");
    kproc_yield();
    uart_puts("[T1]: B\r\n");
    kproc_yield();
    uart_puts("[T1]: C\r\n");
}

void test_kproc_t2(uint32_t args)
{
    uart_puts("[T2]: A\r\n");
    uart_puts("[T2]: B\r\n");
    uart_puts("[T2]: C\r\n");
}

void test_kproc_t4(uint32_t args)
{
    uart_puts("[T4]: A\r\n");
    uart_puts("[T4]: B\r\n");
    kproc_yield();
    uart_puts("[T4]: C\r\n");
}

void test_kproc_t3(uint32_t args)
{
    uart_puts("[T3]: A\r\n");
    uart_puts("[T3]: B\r\n");
    kproc_create_thread(test_kproc_t4, 0);
    kproc_yield();
    uart_puts("[T3]: C\r\n");
}

void kmain(uint64_t dtb_ptr32, uint64_t x1, uint64_t x2, uint64_t x3)
{
    uart_init(3);

    uart_puts("Initializing memory\r");
    kmem_init();
    uart_puts("Done initializing memory\r\n");

    uart_puts("Initializing kprocs\r");
    kproc_init();
    uart_puts("Done initializing kprocs\r\n");

    kproc_create_thread(test_kproc_t1, 0);
    kproc_create_thread(test_kproc_t2, 0);
    kproc_create_thread(test_kproc_t3, 0);
    kproc_scheduler(1);

    exception_init();
    exception_trigger();

    while (1)
        uart_putc(uart_getc());
}
