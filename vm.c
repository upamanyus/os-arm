#include "vm.h"
#include "uart.h"
#include "kmem.h"

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

// Refer to page D5-2740 of ARMv8 manual.
void vm_init()
{
    // Identity-map all of 0x0000'----'----'----
}

// https://developer.arm.com/documentation/ddi0406/cb/System-Level-Architecture/Virtual-Memory-System-Architecture--VMSA-/Short-descriptor-translation-table-format/Selecting-between-TTBR0-and-TTBR1--Short-descriptor-translation-table-format

typedef struct {
    uint32_t pte[1024];
} pagetable1_t;

typedef struct {
    uint32_t pte[256];
} pagetable2_t;

// Prints out idmmfr0 register, which indicates what VMSA support the system
// has.
void check_for_vm()
{
    // https://developer.arm.com/documentation/ddi0406/cb/System-Level-Architecture/System-Control-Registers-in-a-VMSA-implementation/VMSA-System-control-registers-descriptions--in-register-order/ID-MMFR0--Memory-Model-Feature-Register-0--VMSA
    uint32_t idmmfr0;
    asm ("MRC p15, 0, %0, c0, c1, 4"
         : "=r" (idmmfr0));

    uart_puts("idmmfr0 = ");
    uart_bin(idmmfr0);
    uart_puts("\n");
}

// SCTLR controls MMU in non-secure world.
// TODO: should disable MMU via SCTLR upon reset (i.e. boot)

// Sets up an empty page table, with no mappings.
vaddr_space_t vm_create()
{
    uint32_t tbl = (uint32_t)kmem_alloc();
    return tbl;
}

#define PAGE_MASK (~0xFFF)

#define TBL1_INDEX(addr) (addr >> 20 & 0xFFF)
#define TBL2_INDEX(addr) ((addr >> 12) & 0xFF)

vaddr_space_t vm_map(vaddr_space_t vs, uint32_t vaddr, uint32_t paddr)
{
    // NOTE: ref
    // https://developer.arm.com/documentation/ddi0406/cb/System-Level-Architecture/Virtual-Memory-System-Architecture--VMSA-/Short-descriptor-translation-table-format/Translation-table-walks--when-using-the-Short-descriptor-translation-table-format

    vaddr = vaddr & PAGE_MASK;
    paddr = paddr & PAGE_MASK;

    // add a mapping to vs that maps vaddr -> paddr
    uint32_t pte1 = ((uint32_t*)vs)[TBL1_INDEX(vaddr)];


    if ((pte1 & 0b11) != 0b00) {
        // expect 01 as the "validty" bits. Panic if we see something else
        if ((pte1 & 0b11) == 0b01) {
            // FIXME: don't panic yet; vm_addr might not be mapped in the second
            // level.
            uart_panic("vm_map: tried mapping a page that was already mapped");
        } else {
            uart_panic("vm_map: tried mapping a page that had an unexpected type");
        }
    }

    uint32_t tbl2 = (pte1 >> 10); // There are 1024 bytes in the second-level table
    // uint32_t pte2 = (uint32_t*)tbl2
}
