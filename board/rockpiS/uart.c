#include "uart.h"
#include "mmio.h"

// UART Register physical addresses as volatile pointers
#define UART0_RBR (*((volatile unsigned int*)(UART0_BASE + 0x00)))
#define UART0_THR (*((volatile unsigned int*)(UART0_BASE + 0x00)))
#define UART0_DLL (*((volatile unsigned int*)(UART0_BASE + 0x00)))
#define UART0_IER     (*((volatile unsigned int*)(UART0_BASE + 0x04)))
#define UART0_DLH (*((volatile unsigned int*)(UART0_BASE + 0x04)))
#define UART0_FCR         (*((volatile unsigned int*)(UART0_BASE + 0x08)))
#define UART0_LCR         (*((volatile unsigned int*)(UART0_BASE + 0x0C)))
#define UART0_LSR         (*((volatile unsigned int*)(UART0_BASE + 0x14)))

// Register bits
#define LCR_DLAB         (1 << 7) // Divisor Latch Access Bit
#define LCR_8N1          0x03     // 8-bit, no parity, 1 stop bit
#define FCR_FIFO_EN      (1 << 0) // Enable XMIT and RCVR FIFOs
#define FCR_RCVR_FIFO_CLR (1 << 1) // Clear RCVR FIFO
#define FCR_XMIT_FIFO_CLR (1 << 2) // Clear XMIT FIFO

#define LSR_DR           (1 << 0) // Data Ready
#define LSR_THRE         (1 << 5) // Transmit Holding Register Empty

void rockpis_uart_init() {
    // NOTE: also need (USR[0] == 0) here, but not checking for it
    UART0_IER = 0x00;
    UART0_LCR = LCR_DLAB;

    // UART0 clock = reset DPLL clock is 1200MHz.
    // divisor = desired baud rate / (16 * 1200MHz)
    // For baud rate divisor = 3906
    UART0_DLL = 3906; // DLL
    UART0_DLH = 0x00;   // DLH

    // Clear DLAB and set 8-bit, no parity, 1 stop bit
    UART0_LCR = LCR_8N1;

    // Enable and clear FIFOs
    UART0_FCR = FCR_FIFO_EN | FCR_RCVR_FIFO_CLR | FCR_XMIT_FIFO_CLR;
}

void rockpis_uart_putc(char c) {
    if (c == '\n') {
        rockpis_uart_putc('\r');
    }
    while (!(UART0_LSR & LSR_THRE));
    UART0_THR = c;
}

char rockpis_uart_getc() {
    while (!(UART0_LSR & LSR_DR));
    return (char)UART0_RBR;
}
