#include "mmio.h"

// Memory-Mapped I/O output
inline void mmio_write(uint64_t reg, uint32_t data)
{
    *(volatile uint32_t*)(MMIO_BASE + reg) = data;
}

// Memory-Mapped I/O input
inline uint32_t mmio_read(uint64_t reg)
{
    return *(volatile uint32_t*)(MMIO_BASE + reg);
}
