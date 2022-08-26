.section ".text"

.global skip
skip:

// void vm_init(uint32_t vs)
// Requires vs to be 16KB aligned.
.global vm_init
vm_init:
    // TTBCR := 0, which sets TTBCR.N = 0
    mov r1, #0
    mcr p15, 0, r0, c2, c0, 2

    // For TTBR0, we set all the "attribute" bits to 0, which means
    // non-shareable and non-cacheable.

    // Set TTBR0's address to the given address.
    mcr p15, 0, r0, c2, c0, 0

    // Since we're using short-form descriptors, we are also using "domains."
    // This requires us to set DACR to indicate that the domain can be accessed.
    // Before doing this, turning on the MMU resulted in a prefetch abort
    // exception, with the FSR indicating that it was a domain error.
    // This sets domain 1 as being in "client" mode, which means the permission
    // bits in the final page table entry are actually checked before access.
    mov r1, #1
    mcr p15,0,r1,c3,c0,0

    // Turn on MMU
    mrc p15,0,r1,c1,c0,0
    orr r1, r1, #1
    mcr p15,0,r1,c1,c0,0
    bx lr
