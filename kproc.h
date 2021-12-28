#ifndef KCMT_H_
#define KCMT_H_

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
// r19-r28;
// lowest 64 bits of v8-v15;
// frame pointer, because it might be used as a general purpose register.
// PC

struct kproc_context {
    uint64_t lr;
    uint64_t sp;
    uint64_t fp;
    uint64_t r[28 - 19 + 1];
    uint64_t v[15 - 8 + 1];
    // FIXME: keep
};

void kproc_switch(struct kproc_context* old, struct kproc_context *to);

// allocates a fresh kernel proc that runs fn and then exits
void kproc_create_thread(uint64_t fn);

// Starts running the kernel scheduler. This will exit when there are no more
// threads to run.
void kproc_begin();

#endif // KCMT_H_
