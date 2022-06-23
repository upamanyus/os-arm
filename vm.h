#ifndef VM_H_
#define VM_H_

#include <stdint.h>

// a virt addr space is identified by its top-level page table.
typedef uint32_t vaddr_space_t;

// Checks for whether vm is supported.
void vm_check_support();

// Sets up an empty page table, with no valid mappings. Any access using this
// page table should fault.
vaddr_space_t vm_create();

// Adds a mapping to the given virtual address space `vs` so that the virtual
// page containing `vaddr` maps to the physical page containing `paddr`.
vaddr_space_t vm_map(vaddr_space_t vs, uint32_t vaddr, uint32_t paddr);

// Frees the physical page that `vaddr` points to in `vs`, then removes the
// `vaddr` from vs. Accesses to `vaddr` after this will fault.
vaddr_space_t vm_unmap_and_free(vaddr_space_t vs, uint32_t vaddr);

// Unmaps vaddr without freeing the
vaddr_space_t vm_unmap(vaddr_space_t vs, uint32_t vaddr);

// Frees all the pages that are part of this address space, including the page
// table.
// void vm_free(vaddr_space_t vs);

#endif // VM_H_
