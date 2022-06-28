#include <stddef.h>
#include "kmem.h"
#include "mmio.h"
#include "uart.h"

extern char __kern_end[];
static const addr_t KERN_END = (addr_t)__kern_end;

struct ptrptr {
    struct ptrptr *next;
};

// FIXME: protect this with a spinlock once the kernel is preemptible, or when
// we run on multiple cores.
static struct ptrptr* freelist;

// each chunk in this is 4 continuous pages
static struct ptrptr* freelist4;

static inline addr_t pgup(addr_t addr)
{
    return (addr_t) (PGSIZE * (((uint32_t)addr + (PGSIZE - 1))/PGSIZE));
}

static inline addr_t pgdown(addr_t addr)
{
    return (addr_t) (PGSIZE*((uint32_t)addr/PGSIZE));
}

void kmem_init()
{
    addr_t curr_page = pgup(KERN_END);

    freelist = NULL; // Initialize as though there are no free pages left. This lets us call kmem_free.
    freelist4 = NULL;

    // allocate single pages until curr_page is aligned with 16KB boundary
    while (((uint32_t)curr_page & 0x3FFF) != 0) {
        kmem_free(curr_page);
        curr_page += PGSIZE;
    }

    // XXX: add 4 16KB pages. This will support 4 page tables.
    for (int i = 0; i < 4; i++) {
        ((struct ptrptr*)curr_page)->next = freelist4;
        freelist4 = (struct ptrptr*)curr_page;
        curr_page += (4*PGSIZE);
    }

    while (curr_page < (addr_t)(MMIO_BASE) && curr_page < (addr_t)(PHYS_END)) {
        kmem_free(curr_page);
        curr_page += PGSIZE;
    }

    curr_page = (addr_t)MMIO_END+1;

    while (curr_page + PGSIZE < (addr_t)(PHYS_END)) {
        kmem_free(curr_page);
        curr_page += PGSIZE;
    }
}

void kmem_free(addr_t addr)
{
    addr = pgdown(addr);
    ((struct ptrptr*)addr)->next = freelist;
    freelist = (struct ptrptr*)addr;

    // free pages have random data in them
    for (int i = 4; i < PGSIZE; i += 4) {
        *(uint32_t*)(addr + i) = 16 * i;
    }
}

addr_t kmem_alloc()
{
    addr_t pg = (addr_t)freelist;
    if (pg != NULL) {
        freelist = freelist->next;

        // Allocated page will be zeroed out.
        // TODO: do this more efficiently.
        for (int i = 0; i < PGSIZE; i += 4) {
            *(uint32_t*)(pg + i) = 0;
        }
    }


    return pg;
}

addr_t kmem_alloc_many(uint32_t size_power)
{
    addr_t pg = (addr_t)freelist4;
    if (pg != NULL) {
        freelist4 = freelist4->next;

        // Allocated page will be zeroed out.
        // TODO: do this more efficiently.
        for (int i = 0; i < 4*PGSIZE; i += 4) {
            *(uint32_t*)(pg + i) = 0;
        }
    }

    return pg;
}

// TODO: kmem_free_many
