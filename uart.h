#ifndef UART_H_
#define UART_H_

// Must be called before the put/get functions.
void uart_init();

void
uart_putc(unsigned char c);

// Expects null-terminated string as input
void uart_puts(const char* str);

// Waits for
unsigned char uart_getc();

unsigned char uart_try_getc();

#endif // UART_H_
