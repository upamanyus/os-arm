#include "panic.h"
#include "uart.h"

void panic(const char *s) {
    uart_puts(s);
    while (1) {}
}
