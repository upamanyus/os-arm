#include "panic.h"
#include "uart.h"

void panic_panic(const char *s) {
    uart_puts(s);
    while (1) {}
}
