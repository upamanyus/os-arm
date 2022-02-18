#ifndef KPROC_H_
#define KPROC_H_

#include <stdint.h>

// A kernel process consists of:
// * pointer to current stack frame
// * pagetable for that kernel process? No need, unless the kproc will have user
//   stuff mapped in.
// * registers that are callee saved; this is because a kernel process must call
//   kproc_yield_to() in order to yield control, so the compiler will anyways
//   have to save caller-saved registers.

// For ABI, refer to
// https://developer.arm.com/documentation/ihi0055/d
// Across procedure call, must preserve:
// x19-x28;
// lowest 64 bits of v8-v15;
// frame pointer, because it might be used as a general purpose register.
// PC

/*
struct kproc_context {
    uint64_t lr;
    uint64_t sp;
    uint64_t fp;
    uint64_t r[28 - 19 + 1];
    uint64_t v[15 - 8 + 1];
};
*/

struct kproc_context {
    uint32_t lr;
    uint32_t sp;
    uint32_t fp;
    uint32_t r[6]; // r4,5,6,7,8,10
    uint32_t v[15 - 8 + 1];
};

void kproc_switch(struct kproc_context* old, struct kproc_context *to);

// This stuff below is mostly for fun. Won't actually use it for implementing
// userspace multiprocessing, because for that we might want to kproc_switch()
// directly instead of kproc_yield() for more precise control.

// must be called before using the below functions
void kproc_init();

// allocates a fresh kernel proc that runs fn and then exits_
void kproc_create_thread(void (*fn)(uint32_t), uint32_t args);

// Starts running the kernel scheduler. This will exit when there are no more
// threads to run.
void kproc_scheduler();

// Called when a kproc wants to yield control to a different thread.
void kproc_yield();

// Called when a kproc wants to exit
void kproc_exit();

#endif // KPROC_H_
