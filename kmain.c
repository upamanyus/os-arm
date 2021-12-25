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

void kmain(uint64_t dtb_ptr32, uint64_t x1, uint64_t x2, uint64_t x3)
{
    // initialize UART for Raspi3
    uart_init(3);
    uart_puts("Hello, kernel World!\r\n");

    while (1)
        uart_putc(uart_getc());
}
