#ifndef RASPI3_UART_H
#define RASPI3_UART_H

void raspi3_uart_init(void);
void raspi3_uart_putc(char c);
char raspi3_uart_getc(void);

#endif // RASPI3_UART_H
