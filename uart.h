#ifndef UART_H_
#define UART_H_

#include <stdint.h>

// Must be called before the put/get functions.
void uart_init();

void
uart_putc(unsigned char c);

// Expects null-terminated string as input
void uart_puts(const char* str);

// Waits for input
unsigned char uart_getc();

// prints out input in hex as 0xABCDEF...
void uart_hex(uint64_t a);

#endif // UART_H_
