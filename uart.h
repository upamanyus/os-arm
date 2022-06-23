#ifndef UART_H_
#define UART_H_

#include <stdint.h>
#include <stdnoreturn.h>

// Must be called before the put/get functions.
void uart_init();

void uart_putc(unsigned char c);

// Expects null-terminated string as input
void uart_puts(const char* str);

// Waits for input
unsigned char uart_getc();

// prints out input in hex as 0xABCDEF...
void uart_hex(uint32_t a);

// prints out input in binary as 0b101010101...
void uart_bin(uint32_t a);

// Prints the message, then halts.
noreturn void uart_panic(const char *str);

#endif // UART_H_
