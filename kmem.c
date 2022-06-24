#include <stddef.h>
#include "kmem.h"
#include "mmio.h"
#include "uart.h"

extern char __kern_end[];
static uint8_t* const KERN_END = (uint8_t*)__kern_end;

struct ptrptr {
    struct ptrptr *next;
};

// FIXME: protect this with a spinlock once the kernel is preemptible, or when
// we run on multiple cores.
static struct ptrptr* freelist;

// each chunk in this is 4 continuous pages
static struct ptrptr* freelist4;

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
    freelist4 = NULL;

    // XXX: add 4 16KB pages. This will support 4 page tables.
    for (int i = 0; i < 4; i++) {
        ((struct ptrptr*)curr_page)->next = freelist4;
        freelist4 = (struct ptrptr*)curr_page;
        curr_page += (4*PGSIZE);
    }

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

        // Allocated page will be zeroed out.
        // TODO: do this more efficiently.
        for (int i = 0; i < PGSIZE; i += 4) {
            *(uint32_t*)(pg + i) = 0;
        }
    }


    return pg;
}

uint8_t *kmem_alloc_many(uint32_t size_power)
{
    uint8_t* pg = (uint8_t*)freelist4;
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
