#ifndef MEM_LAYOUT_H
#define MEM_LAYOUT_H

#include <stdint.h>

extern uint8_t __kern_end;

#ifdef BOARD_raspi3
#define MEM_LAYOUT_END 0x3C100000

#elif defined(BOARD_rockpiS)
#define MEM_LAYOUT_END 0x20000000

#else
#error "BOARD not defined or unsupported"
#endif

extern uintptr_t mem_layout_start;
extern uintptr_t mem_layout_end;

void mem_layout_init(void);

#endif // MEM_LAYOUT_H
