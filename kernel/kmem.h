#ifndef KMEM_H
#define KMEM_H

#include <stddef.h> // For size_t

#define KMEM_PGSIZE 4096

void kmem_init(void);
void kmem_free(void* addr);
void* kmem_alloc(void);
void* kmem_alloc_or_panic(void);

#endif // KMEM_H
