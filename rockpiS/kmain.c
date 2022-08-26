#include <stdint.h>

const uint64_t UART_BASE = 0xff0a0000;

// receive buffer register
const uint64_t UART_RBR = UART_BASE + 0x00;
// transmit holding register
const uint64_t UART_THR = UART_BASE + 0x00;

// divisor latch low
const uint64_t UART_DLL = UART_BASE + 0x00;

// divisor latch high
const uint64_t UART_DLH = UART_BASE + 0x04;

// fifo control register
const uint64_t UART_FCR = UART_BASE + 0x08;

// line control register
const uint64_t UART_LCR = UART_BASE + 0x0c;

// line status register
const uint64_t UART_LSR = UART_BASE + 0x0014;

void mmio_write(uint64_t addr, uint32_t data)
{
    *(volatile uint32_t*)(addr) = data;
}

uint64_t mmio_read(uint64_t addr)
{
    return *(volatile uint32_t*)(addr);
}

// Loop `count` times in a way that the compiler won't optimize away
void delay(uint64_t count)
{
    for (;;) {
        if (count == 0) {
            return;
        }
        count = count - 1;
    }
    // asm volatile("__delay_%=: subs %[count], %[count], #1; bne __delay_%=\n"
                 // : "=r"(count): [count]"0"(count) : "cc");
}

void set_clock() {
    // Integer mode:
    // FOUTVCO = (FREF / REFDIV) * FBDIV
    // FOUTPOSTDIV = FOUTVCO / (POSTDIV1*POSTDIV2)
    // to get 1200MHz, e.g. set REFDIV = 1 and FBDIV = 100,
    // and POSTDIV1 = 2, POSTDIV2 = 1. This is the reset config.
    // Not sure why POSTDIV1 = 2.
    //
    // Set DSMPD = 1

    // FIXME: do this
}

void uart_init() {
    set_clock();
    // set the baud rate to 19200
    // XXX: also need USR[0] to be zero
    mmio_write(UART_LCR, 0b10000000); // enable access to DLL+DLH

    // default/reset DPLL clock is 1200MHz
    // baud rate = sclk / (16 * divisor)
    // want divisor = 3906
    uint16_t divisor = 3906;
    mmio_write(UART_DLL, divisor & 0xFF);
    mmio_write(UART_DLH, (divisor & 0xFF00) >> 8);

    mmio_write(UART_LCR, 0b0); // disable access to DLL+DLH, enable access to other regs

    // wait at least 8 clock cycles (of the slowest uart clock)
    delay(2e6);

    mmio_write(UART_FCR, 0x01); // enable FIFO
}

void uart_putc(char c) {
    for (;;) {
        uint32_t lsr = mmio_read(UART_LSR);
        if (lsr >> 5 & 0x1) { // if THR empty
            mmio_write(UART_THR, c);
            return;
        }
    }
}

char uart_getc() {
    for (;;) {
        uint32_t lsr = mmio_read(UART_LSR);
        if (lsr & 0x1) { // if the data ready bit is set
            return (char)(mmio_read(UART_THR));
        }
    }
}

void kmain() {
    uart_init();

    uart_putc('H');
    uart_putc('e');
    uart_putc('l');
    uart_putc('l');
    uart_putc('o');
    uart_putc('\n');
    uart_putc('\r');
    for(;;) {
        char c = uart_getc();
        uart_putc(c);
    }
}
