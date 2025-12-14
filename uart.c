#include "uart.h"
#include "board/raspi3/uart.h"
#include <stdarg.h>

void uart_init(void) {
    raspi3_uart_init();
}

void uart_putc(int c) {
    raspi3_uart_putc((char)c);
}

int uart_getc(void) {
    return (int)raspi3_uart_getc();
}

void uart_puts(const char *s) {
    for (int i = 0; s[i] != '\0'; i++) {
        uart_putc(s[i]);
    }
}

static void print_int(int xx, int base, int sgn) {
    char buf[16];
    int i = 0;
    unsigned int x;

    if (sgn && (sgn = (xx < 0)))
        x = -xx;
    else
        x = xx;

    do {
        buf[i++] = "0123456789abcdef"[x % base];
    } while ((x /= base) != 0);

    if (sgn)
        buf[i++] = '-';

    while (--i >= 0)
        uart_putc(buf[i]);
}

void uart_printf(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);

    for (int i = 0; fmt[i] != '\0'; i++) {
        if (fmt[i] != '%') {
            uart_putc(fmt[i]);
            continue;
        }

        i++;
        switch (fmt[i]) {
        case 'd':
            print_int(va_arg(ap, int), 10, 1);
            break;
        case 'x':
            print_int(va_arg(ap, int), 16, 0);
            break;
        case 's':
            uart_puts(va_arg(ap, char *));
            break;
        case 'c':
            uart_putc(va_arg(ap, int));
            break;
        case '%':
            uart_putc('%');
            break;
        default:
            uart_putc('%');
            uart_putc(fmt[i]);
            break;
        }
    }

    va_end(ap);
}
