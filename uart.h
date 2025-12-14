#ifndef UART_H
#define UART_H

#include <stdint.h>

void uart_init(void);
void uart_puts(const char *s);
int uart_getc(void);
void uart_putc(int c);
void uart_printf(const char *fmt, ...);

#endif // UART_H
