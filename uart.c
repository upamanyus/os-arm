#include "uart.h"
#include "mmio.h"
#include "util.h"
#include "mailbox.h"

#include <stdnoreturn.h>
#include <stddef.h>

// uart stuff taken from https://wiki.osdev.org/Raspberry_Pi_Bare_Bones
void uart_init(int raspi)
{
    // Disable UART0.
    mmio_write(UART0_CR, 0x00000000);
    // Setup the GPIO pin 14 && 15.

    // Disable pull up/down for all GPIO pins & delay for 150 cycles.
    mmio_write(GPPUD, 0x00000000);
    delay(150);

    // Disable pull up/down for pin 14,15 & delay for 150 cycles.
    mmio_write(GPPUDCLK0, (1 << 14) | (1 << 15));
    delay(150);

    // Write 0 to GPPUDCLK0 to make it take effect.
    mmio_write(GPPUDCLK0, 0x00000000);

    // Clear pending interrupts.
    mmio_write(UART0_ICR, 0x7FF);

    // Set integer & fractional part of baud rate.
    // Divider = UART_CLOCK/(16 * Baud)
    // Fraction part register = (Fractional part * 64) + 0.5
    // Baud = 115200.

    // For Raspi3 and 4 the UART_CLOCK is system-clock dependent by default.
    // Set it to 3Mhz so that we can consistently set the baud rate
    if (raspi >= 3) {
        // UART_CLOCK = 30000000;
        uint32_t r = (((uint32_t)(&mbox_clockrate) & ~0xF) | 8);
        // wait until we can talk to the VC
        while ( mmio_read(MBOX_STATUS) & 0x80000000 ) { }
        // send our message to property channel and wait for the response
        mmio_write(MBOX_WRITE, r);
        while ( (mmio_read(MBOX_STATUS) & 0x40000000) || mmio_read(MBOX_READ) != r ) { }
    }

    // Divider = 3000000 / (16 * 115200) = 1.627 = ~1.
    mmio_write(UART0_IBRD, 1);
    // Fractional part register = (.627 * 64) + 0.5 = 40.6 = ~40.
    mmio_write(UART0_FBRD, 40);

    // Enable FIFO & 8 bit data transmission (1 stop bit, no parity).
    mmio_write(UART0_LCRH, (1 << 4) | (1 << 5) | (1 << 6));

    // Mask all interrupts.
    mmio_write(UART0_IMSC, (1 << 1) | (1 << 4) | (1 << 5) | (1 << 6) |
               (1 << 7) | (1 << 8) | (1 << 9) | (1 << 10));

    // Enable UART0, receive & transfer part of UART.
    mmio_write(UART0_CR, (1 << 0) | (1 << 8) | (1 << 9));
}

void uart_putc(unsigned char c)
{
    // Wait for UART to become ready to transmit.
    while ( mmio_read(UART0_FR) & (1 << 5) ) { }
    mmio_write(UART0_DR, c);
}

unsigned char uart_getc()
{
    // Wait for UART to have received something.
    while ( mmio_read(UART0_FR) & (1 << 4) ) { }
    return mmio_read(UART0_DR);
}

void uart_puts(const char* str)
{
    for (size_t i = 0; str[i] != '\0'; i ++)
        uart_putc((unsigned char)str[i]);
}

char hex_lookup[] =
{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B',
'C', 'D', 'E', 'F'};

void uart_hex(uint32_t a)
{
    uart_puts("0x");
    for (int i = 0; i < 8; i++) { // 8 nibbles
        uart_putc(hex_lookup[(a >> 4 * (7 - i)) & 0xF]);
    }
}

void uart_bin(uint32_t a)
{
    uart_puts("0b");
    for (int i = 0; i < 32; i++) {
        uart_putc(hex_lookup[(a >> (31 - i)) & 0x1]);
    }
}

noreturn void uart_panic(const char *str)
{
    // We could print a backtrace here.
    uart_puts("halting from panic: ");
    uart_puts(str);

    // halt code
    for (;;) {
        asm ("wfe");
    }
}
