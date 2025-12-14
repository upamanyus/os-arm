#include "mmio.h"
#include "../../delay.h"
#include <stdint.h>

volatile uint32_t mbox_clockrate[9] __attribute__((aligned(16))) = {
    9 * 4, 0, 0x38002, 12, 8, 2, 3000000, 0, 0
};

void raspi3_uart_init(void) {
    UART0_CR = 0x00000000;
    // Disable pull up/down for all GPIO pins & delay for 150 cycles.
    GPPUD = 0x00000000;
    delay(150);

    // Disable pull up/down for pin 14,15 & delay for 150 cycles.
    delay(150);

    GPPUDCLK0 = 0x00000000;

    UART0_ICR = 0x7FF;

    uint32_t r = (((uint32_t)(uintptr_t)&mbox_clockrate) & ~0xF) | 8;
    while (MBOX_STATUS & 0x80000000) {}
    MBOX_WRITE = r;
    while ((MBOX_STATUS & 0x40000000) || MBOX_READ != r) {}

    UART0_IBRD = 1;
    UART0_FBRD = 40;

    UART0_LCRH = (1 << 4) | (1 << 5) | (1 << 6);

    UART0_IMSC = (1 << 1) | (1 << 4) | (1 << 5) | (1 << 6) | (1 << 7) | (1 << 8) | (1 << 9) | (1 << 10);

    UART0_CR = (1 << 0) | (1 << 8) | (1 << 9);
}

void raspi3_uart_putc(char c) {
    while (UART0_FR & (1 << 5)) {}
    UART0_DR = c;
}

char raspi3_uart_getc(void) {
    while (UART0_FR & (1 << 4)) {}
    return (char)UART0_DR;
}
