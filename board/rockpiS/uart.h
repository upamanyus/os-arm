#ifndef ROCKPIS_UART_H
#define ROCKPIS_UART_H

void rockpis_uart_init();
void rockpis_uart_putc(char c);
char rockpis_uart_getc();

#endif
