#include <stddef.h>
#include <stdint.h>

#include "uart.h"
#include "kmem.h"
#include "kproc.h"

struct kproc_context t1;
struct kproc_context t2;

void test_kproc1()
{
    uart_puts("[T1]: A\r\n");
    kproc_switch(&t1, &t2);
    uart_puts("[T1]: B\r\n");
    kproc_switch(&t1, &t2);
    uart_puts("[T1]: C\r\n");
    kproc_switch(&t1, &t2);
}

void test_kproc2()
{
    uart_puts("[T2]: A\r\n");
    kproc_switch(&t2, &t1);
    uart_puts("[T2]: B\r\n");
    kproc_switch(&t2, &t1);
    uart_puts("[T2]: C\r\n");
}

void test_kproc_old()
{
    t2.lr = (uint64_t)test_kproc2; // Fork a thread with uniniti
    t2.sp = (uint64_t)kmem_alloc(); // Give it a fresh page as stack frame
    t2.fp = t2.sp; // fp == sp?
    test_kproc1();
}

void test_kproc_t1(uint64_t args)
{
    uart_puts("[T1]: A\r\n");
    kproc_yield();
    uart_puts("[T1]: B\r\n");
    kproc_yield();
    uart_puts("[T1]: C\r\n");
}

void test_kproc_t2(uint64_t args)
{
    uart_puts("[T2]: A\r\n");
    uart_puts("[T2]: B\r\n");
    uart_puts("[T2]: C\r\n");
}
// above two threads running concurrently print out:
// [T1]: A
// [T2]: A
// [T1]: B
// [T2]: B
// [T1]: C
// [T2]: C
// Scheduling is deterministic.


void kmain(uint64_t dtb_ptr32, uint64_t x1, uint64_t x2, uint64_t x3)
{
    uart_init(3);
    uart_puts("Hello, kernel World!\r\n");

    uart_puts("Initializing memory\r\n");
    kmem_init();
    uart_puts("Done initializing memory\r\nkalloc() returned: ");

    uart_puts("Initializing kprocs\r\n");
    kproc_init();
    uart_puts("Done initializing kprocs\r\n");

    uint64_t addr = (uint64_t)kmem_alloc();
    uart_hex(addr);
    uart_puts("\r\n");

    kproc_create_thread(test_kproc_t1, 0);
    kproc_create_thread(test_kproc_t2, 0);
    kproc_scheduler();

    while (1)
        uart_putc(uart_getc());
}
