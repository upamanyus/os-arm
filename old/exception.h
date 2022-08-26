#ifndef EXCEPTION_H_
#define EXCEPTION_H_

#include <stdint.h>

// Call before causing exceptions/enabling interrupts.
void exception_init();

// Triggers an undefined instruction exception.
void exception_trigger();

// Sets up the vbar register to point to the location of the exception handlers.
void exception_init_vbar(uint32_t trampoline_addr);

#endif // EXCEPTION_H_
