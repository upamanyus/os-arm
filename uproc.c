#include "uproc.h"
#include "kproc.h"
#include "vm.h"
#include "kmem.h"

struct uproc_info {
    vaddr_space_t vs;
};

extern char __trampoline[];
static const addr_t TRAMPOLINE_PHYS = (addr_t)__trampoline;

void uproc_create(void (*mainfn)) {
    vaddr_space_t vs = vm_create();
    addr_t code_page = kmem_alloc();

    // copy one page from the main function to the code page
    for (int i = 0; i < PGSIZE; i += 4) {
        *(uint32_t*)(code_page + i) = *(uint32_t*)((addr_t)mainfn + i);
    }

    // map the code page to virtual address 0x1000
    vm_map(vs, 0x1000, (uint32_t)code_page);

    // put a single page for the user stack
    addr_t user_stack_page = kmem_alloc();
    vm_map(vs, 0x5000, (uint32_t)user_stack_page);

    // map the trampoline page
    vm_map(vs, TRAMPOLINE, (uint32_t)TRAMPOLINE_PHYS);
}
