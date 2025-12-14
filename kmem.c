#include "kmem.h"
#include "mem_layout.h"
#include "panic.h"
#include <stddef.h>

typedef struct Node {
    struct Node *next;
} Node;

static Node *freelist = NULL;

static inline uintptr_t pgdown(uintptr_t addr) {
    return addr & ~(KMEM_PGSIZE - 1);
}

static inline uintptr_t pgup(uintptr_t addr) {
    return pgdown(addr + KMEM_PGSIZE - 1);
}

void kmem_init(void) {
    mem_layout_init();

    for (uintptr_t addr = pgup(mem_layout_start); addr + KMEM_PGSIZE < mem_layout_end; addr += KMEM_PGSIZE) {
        kmem_free((void*)addr);
    }
}

void kmem_free(void *addr) {
    Node *node = (Node*)addr;
    node->next = freelist;
    freelist = node;
}

void *kmem_alloc(void) {
    if (freelist) {
        Node *addr = freelist;
        freelist = addr->next;
        // Zero out the page
        uint64_t *p = (uint64_t*)addr;
        for (int i = 0; i < KMEM_PGSIZE / sizeof(uint64_t); i++) {
            p[i] = 0;
        }
        return addr;
    }
    return NULL;
}

void *kmem_alloc_or_panic(void) {
    void *addr = kmem_alloc();
    if (addr == NULL) {
        panic_panic("out of memory");
    }
    return addr;
}
