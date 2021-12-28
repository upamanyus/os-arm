/*
  #include <stddef.h>
  #include <stdint.h>

  void kmain(uint64_t dtb_ptr32, uint64_t x1, uint64_t x2, uint64_t x3)
  {

  }
*/

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

void kmain(uint64_t dtb_ptr32, uint64_t x1, uint64_t x2, uint64_t x3)
{
    // initialize UART for Raspi3
    uart_init(3);
    uart_puts("Hello, kernel World!\r\n");

    // uart_puts("__kern_end: ");
    // uart_hex((uint64_t)__kern_end);
    // uart_puts("\r\n");

    uart_puts("Initializing memory\r\n");
    kmem_init();
    uart_puts("Done initializing memory\r\nkalloc() returned: ");

    uint64_t addr = (uint64_t)kmem_alloc();
    uart_hex(addr);
    uart_puts("\r\n");

    t2.lr = (uint64_t)test_kproc2; // Fork a thread with uniniti
    t2.sp = (uint64_t)kmem_alloc(); // Give it a fresh page as stack frame
    t2.fp = t2.sp; // fp == sp?
    test_kproc1();

    while (1)
        uart_putc(uart_getc());
}
