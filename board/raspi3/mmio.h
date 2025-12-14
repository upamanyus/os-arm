#ifndef RASPI3_MMIO_H
#define RASPI3_MMIO_H

#include <stdint.h>

#define MMIO_BASE 0x3F000000

#define GPIO_BASE (MMIO_BASE + 0x200000)
#define GPPUD (*(volatile uint32_t*)(GPIO_BASE + 0x94))
#define GPPUDCLK0 (*(volatile uint32_t*)(GPIO_BASE + 0x98))

#define UART0_BASE (GPIO_BASE + 0x1000)
#define UART0_DR (*(volatile uint32_t*)(UART0_BASE + 0x00))
#define UART0_FR (*(volatile uint32_t*)(UART0_BASE + 0x18))
#define UART0_IBRD (*(volatile uint32_t*)(UART0_BASE + 0x24))
#define UART0_FBRD (*(volatile uint32_t*)(UART0_BASE + 0x28))
#define UART0_LCRH (*(volatile uint32_t*)(UART0_BASE + 0x2C))
#define UART0_CR (*(volatile uint32_t*)(UART0_BASE + 0x30))
#define UART0_IMSC (*(volatile uint32_t*)(UART0_BASE + 0x38))
#define UART0_ICR (*(volatile uint32_t*)(UART0_BASE + 0x44))

#define MBOX_BASE (MMIO_BASE + 0xB880)
#define MBOX_READ (*(volatile uint32_t*)(MBOX_BASE + 0x00))
#define MBOX_STATUS (*(volatile uint32_t*)(MBOX_BASE + 0x18))
#define MBOX_WRITE (*(volatile uint32_t*)(MBOX_BASE + 0x20))

#endif // RASPI3_MMIO_H
