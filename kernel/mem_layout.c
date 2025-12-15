#include "mem_layout.h"
#include <stdint.h>

uintptr_t mem_layout_start;
uintptr_t mem_layout_end;

void mem_layout_init(void) {
    mem_layout_start = (uintptr_t)&__kern_end;
    mem_layout_end = MEM_LAYOUT_END;
}
