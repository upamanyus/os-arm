#include "uart.h"
#ifdef BOARD_raspi3
#include "board/raspi3/uart.h"
#elif defined(BOARD_rockpiS)
#include "board/rockpiS/uart.h"
#endif
#include "kmem.h"
#include "panic.h"
#include "mem_layout.h"
#include "delay.h"
#include "execution_context.h"
#include <stdint.h>

// Assuming __kern_end is defined in the linker script
#include "mem_layout.h"

void init(uint64_t arg) {
    uart_printf("Reached init with arg: 0x%x\n", arg);
    syscall();
    uart_puts("Back to init!");
    (void)uart_getc();
}

void kmain(void) {
    uart_init();
    uart_puts("Serial initialized\n");
    uart_puts("Calling delay.delay...");
    delay(100);
    uart_puts("done.\n");

    // mem_layout_init();
    uart_printf("kmem_end = 0x%x\n", (unsigned int)(uintptr_t)&__kern_end);
    uart_puts("Initializing kmem...");
    kmem_init();
    uart_puts("done.\n");

    uart_puts("Initializing router...");
    execution_context_init((uint64_t)&init);
    uart_puts("done.\n");

    dispatch();

    panic_panic("end of kmain\n");
}

