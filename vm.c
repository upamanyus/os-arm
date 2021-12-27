#include <stdint.h>
#include "vm.h"

// References
// https://developer.arm.com/documentation/101811/0102/Address-spaces
// TCR register: https://developer.arm.com/documentation/100403/0200/register-descriptions/aarch64-system-registers/tcr-el1--translation-control-register--el1?lang=en
// About exception levels
// https://developer.arm.com/documentation/102412/0100/Execution-and-Security-states

// Uses 48-bit address space.
// kernel addresses are 0xFFFF'----'----'----
enum {
TCR_T0SZ = (64 - 48),
TCR_T1SZ = (64 - 48),
// ignore contiguous bit, since it's a TLB optimization
};


typedef struct {
    uint64_t pte[512];
} pagetable_t;


// Refer to page D5-2740 of ARMv8 manual.
void vm_init()
{
    // Identity-map all of 0x0000'----'----'----
}
