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

// https://developer.arm.com/documentation/ddi0406/cb/System-Level-Architecture/Virtual-Memory-System-Architecture--VMSA-/Short-descriptor-translation-table-format/Selecting-between-TTBR0-and-TTBR1--Short-descriptor-translation-table-format

typedef struct {
    uint32_t pte[1024];
} pagetable1_t;

typedef struct {
    uint32_t pte[256];
} pagetable2_t;

// Prints out idmmfr0 register, which indicates what VMSA support the system
// has.
void vm_check_support()
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
    uint32_t tbl = (uint32_t)kmem_alloc_many(2);
    return tbl;
}

#define PAGE_MASK (~0xFFF)

#define PTE_KIND_MASK 0b11

#define PTE1_KIND_PAGETABLE 0b01
#define PTE1_KIND_INVALID 0b00

#define PTE2_KIND_INVALID 0b00
#define PTE2_KIND_PAGE 0b10 // for small page

// these flags are for small pages
#define PTE_EXECUTE_NEVER 0b01
#define PTE_EXECUTE_NEVER 0b01

#define PTE_ACC_PRIV_RO 0b0
#define PTE_ACC_PRIV_WR (1 << 9)

#define PTE_ACC_USR_NONE (0b01 << 4)
#define PTE_ACC_USR_RO (0b10 << 4)
#define PTE_ACC_USR_WR (0b11 << 4)

static inline uint32_t index1(uint32_t addr) {
    return (addr >> 20 & 0xFFF);
}

static inline uint32_t index2(uint32_t addr) {
    return ((addr >> 12) & 0xFF);
}

static inline uint32_t get_entry(uint32_t table_addr, uint32_t idx) {
    return ((uint32_t*)table_addr)[idx];
}

static inline void set_entry(uint32_t table_addr, uint32_t idx, uint32_t pte) {
    ((uint32_t*)table_addr)[idx] = pte;
}

void vm_map(vaddr_space_t vs, uint32_t vaddr, uint32_t paddr)
{
    // NOTE: ref
    // https://developer.arm.com/documentation/ddi0406/cb/System-Level-Architecture/Virtual-Memory-System-Architecture--VMSA-/Short-descriptor-translation-table-format/Translation-table-walks--when-using-the-Short-descriptor-translation-table-format

    vaddr = vaddr & PAGE_MASK;
    paddr = paddr & PAGE_MASK;

    // Get the 2nd level table for vaddr, or create one if it doesn't exist.
    uint32_t pte1 = get_entry(vs, index1(vaddr));

    if ((pte1 & PTE_KIND_MASK) != PTE1_KIND_PAGETABLE) {
        // If the entry isn't a "page table" entry, then it should be invalid.
        if ((pte1 & PTE_KIND_MASK) != PTE1_KIND_INVALID) {
            uart_panic("vm_map: tried mapping a page that had an unexpected type");
        }

        // At this point, we need to create a 2nd page level page table for
        // INDEX1(vaddr) and its "neighbors".
        uint32_t tbls2 = (uint32_t)kmem_alloc(); // This page will contain 4 second level page tables.
        if (tbls2 == 0) {
            uart_panic("vm_map: unable to allocate page for 2nd-level table");
        }

        for (int j = 0; j < 4; j++) {
            uint32_t idx = (index1(vaddr) & ~0b11) | j;
            uint32_t new_pte = ((tbls2 >> 10) + j) | PTE1_KIND_PAGETABLE;
            set_entry(vs, idx, new_pte);
        }

        pte1 = get_entry(vs, index1(vaddr));
    }

    uint32_t table2_addr = (pte1 >> 10); // There are 1024 bytes in the second-level table
    uint32_t pte2 = get_entry(table2_addr, index2(vaddr));
    if ((pte2 & PTE_KIND_MASK) != PTE2_KIND_INVALID) {
        uart_hex(pte2);
        uart_puts("\n");
        uart_panic("vm_map: tried mapping a page that was already mapped");
    }

    // TODO: what does "shareable" mean exactly? What should that bit be set to?
    uint32_t new_pte2 = (paddr & PAGE_MASK) | PTE_ACC_PRIV_WR | PTE_ACC_USR_WR;
    set_entry(table2_addr, index2(vaddr), new_pte2);
}
