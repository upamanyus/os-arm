#ifndef KMEM_H_
#define KMEM_H_

#include <stdint.h>

#define PGBITS 12
#define PGSIZE (1 << PGBITS)
// #define PHYS_END 0x3F000000 - 4096
#define PHYS_END (0x3C100000)

// This module owns all of the memory after KERN_END, excluding MMIO_BASE to MMIO_END

// requires: ownership of memory past KERN_END (except MMIO_BASE->MMIO_END)
void kmem_init();

// Allocates a single page, or returns NULL if out of memory
// ensures: ownership of page containing ret
uint8_t *kmem_alloc();

// Free the page containing the given address. For convenience, addr need not be
// page-aligned.
// requires: ownership of page containig addr
void kmem_free(uint8_t* addr);

// Allocates the given number of pages continuously, if possible, or returns
// NULL if out of memory
// uint8_t *kmem_alloc_n(uint32_t);

#endif // KALLOC_H_
