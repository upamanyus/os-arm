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

    while (1)
        uart_putc(uart_getc());
}
