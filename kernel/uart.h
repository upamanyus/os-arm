#ifndef UART_H
#define UART_H

#include <stdint.h>

#ifdef BOARD_raspi3
#include "board/raspi3/uart.h"
#define uart_init() raspi3_uart_init()
#define uart_putc(c) raspi3_uart_putc(c)
#define uart_getc() raspi3_uart_getc()
#elif defined(BOARD_rockpiS)
#include "board/rockpiS/uart.h" // Include the board-specific header first
#define uart_init() rockpis_uart_init()
#define uart_putc(c) rockpis_uart_send(c) // rockpis_uart_send expects char, uart_putc expects int
#define uart_getc() rockpis_uart_getc()
#else
#error "BOARD not defined or unsupported"
#endif

void uart_puts(const char *s);
void uart_printf(const char *fmt, ...);

#endif // UART_H
