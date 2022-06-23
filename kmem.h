#ifndef KMEM_H_
#define KMEM_H_

#include <stdint.h>

#define PGBITS 12
#define PGSIZE (1 << PGBITS)
// Rpi3 end
// #define PHYS_END (0x3C100000) // This is *just past* the max allowed address.
// This number comes from looking at qemu-aarch64 raspi3 emulation, and noting
// that the last 64MiB (0x4000000 bytes) is reserved for VC ram. That includes a
// framebuffer, so writing to it causes the display to do things.

// This is the address for 512MiB total RAM, and with vcram at the end
#define PHYS_END (0x1C100000)

// This module owns all of the memory after KERN_END, excluding MMIO_BASE to
// MMIO_END, up to PHYS_END

// requires: ownership of memory past KERN_END (except MMIO_BASE->MMIO_END)
void kmem_init();

// Allocates a single page, or returns NULL iff out of memory
// ensures: ownership of page containing ret, and that the page is zeroed out.
uint8_t *kmem_alloc();

// Free the page containing the given address. For convenience, addr need not be
// page-aligned.
// requires: ownership of page containig addr
void kmem_free(uint8_t* addr);

// Allocates 2**(size_power) pages continuously, if possible, or returns NULL if
// unable to do so.
uint8_t *kmem_alloc_many(uint32_t size_power);

#endif // KALLOC_H_
