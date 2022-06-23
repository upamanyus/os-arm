#include <stddef.h>
#include "kmem.h"
#include "mmio.h"
#include "uart.h"

extern char __kern_end[];
uint8_t* const KERN_END = (uint8_t*)__kern_end;

struct ptrptr {
    struct ptrptr *next;
};

static struct ptrptr* freelist;

static inline uint8_t* pgup(uint8_t* addr)
{
    return (uint8_t*) (PGSIZE * (((uint32_t)addr + (PGSIZE - 1))/PGSIZE));
}

static inline uint8_t* pgdown(uint8_t* addr)
{
    return (uint8_t*) (PGSIZE*((uint32_t)addr/PGSIZE));
}

void kmem_init()
{
    uint8_t* curr_page = pgup(KERN_END);

    freelist = NULL; // Initialize as though there are no free pages left. This lets us call kmem_free.

    while (curr_page < (uint8_t*)(MMIO_BASE) && curr_page < (uint8_t*)(PHYS_END)) {
        kmem_free(curr_page);
        curr_page += PGSIZE;
    }

    curr_page = (uint8_t*)MMIO_END+1;

    while (curr_page +PGSIZE < (uint8_t*)(PHYS_END)) {
        kmem_free(curr_page);
        curr_page += PGSIZE;
    }
}

void kmem_free(uint8_t* addr)
{
    addr = pgdown(addr);
    ((struct ptrptr*)addr)->next = freelist;
    freelist = (struct ptrptr*)addr;

    // free pages have random data in them
    for (int i = 4; i < PGSIZE; i += 4) {
        *(uint32_t*)(addr + i) = 16 * i;
    }
}

uint8_t* kmem_alloc()
{
    uint8_t* pg = (uint8_t*)freelist;
    if (pg != NULL) {
        freelist = freelist->next;
    }

    // Allocated page will be zeroed out.
    // TODO: do this more efficiently.
    for (int i = 0; i < PGSIZE; i += 4) {
        *(uint32_t*)(pg + i) = 0;
    }

    return pg;
}

uint8_t *kmem_alloc_many(uint32_t size_power)
{
    uart_panic("kmem: alloc_many unsupported");
}
