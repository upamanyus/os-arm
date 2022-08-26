#include "util.h"

// Loop `count` times in a way that the compiler won't optimize away
void delay(uint64_t count)
{
    asm volatile("__delay_%=: subs %[count], %[count], #1; bne __delay_%=\n"
                 : "=r"(count): [count]"0"(count) : "cc");
}
