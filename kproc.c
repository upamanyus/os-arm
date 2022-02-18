#include "kproc.h"
#include "kmem.h"
#include "uart.h"
#include <stdbool.h>

#define MAXPROCS 1024

enum {
EMPTY = 0,
RUNNING = 1,
IDLE = 2,
};

struct kproc_context sched_ctx;

static struct {
    int curr;
    int status[MAXPROCS];
    struct kproc_context ctxs[MAXPROCS];
    uint32_t stacks[MAXPROCS]; // Each of these is a single page large; no guard pages rn
    uint32_t nprocs;
} kprocs;

extern char kproc_start[];

void kproc_init()
{
    kprocs.nprocs = 0;
    for (int i = 0; i < MAXPROCS; i++) {
        kprocs.status[i] = EMPTY;
    }
}

void kproc_create_thread(void (*fn)(uint32_t), uint32_t args)
{
    if (kprocs.nprocs >= MAXPROCS) {
        uart_puts("Unable to create a thread, reached max procs already\r\n");
        return;
    }

    uint32_t i = kprocs.nprocs;
    kprocs.nprocs += 1;

    // HACK: see kproc_start.S
    // load fn and args into the first two callee-saved registers
    kprocs.ctxs[i].r[0] = (uint32_t)fn; // in 64-bit, x19 = fn
    kprocs.ctxs[i].r[1] = args; // in 64-bit, x20 = args
    kprocs.ctxs[i].lr = (uint32_t)kproc_start;
    kprocs.stacks[i] = (uint32_t)kmem_alloc();
    kprocs.ctxs[i].sp = kprocs.stacks[i] + PGSIZE; // top of stack, since it grows down
    kprocs.ctxs[i].fp = kprocs.ctxs[i].sp;
    kprocs.status[i] = IDLE;
}

void kproc_scheduler()
{
    bool took_step;
    do {
        took_step = false;
        for (int i = 0; i < MAXPROCS; i++) {
            if (kprocs.status[kprocs.curr] == IDLE) {
                kprocs.status[kprocs.curr] = RUNNING;
                kproc_switch(&sched_ctx, &(kprocs.ctxs[kprocs.curr]));

                if (kprocs.status[kprocs.curr] == EMPTY) {
                    kmem_free((uint8_t*)kprocs.stacks[kprocs.curr]); // cleanup
                }
                took_step = true;
            }

            kprocs.curr += 1;
            if (kprocs.curr == MAXPROCS) {
                kprocs.curr = 0;
            }
        }
    } while (took_step);
    uart_puts("Took no steps this round; kproc scheduler stopping\r\n");
}

void kproc_yield()
{
    kprocs.status[kprocs.curr] = IDLE;
    kproc_switch(&kprocs.ctxs[kprocs.curr], &sched_ctx);
}

void kproc_exit()
{
    kprocs.status[kprocs.curr] = EMPTY;
    // kmem_free((uint8_t*)kprocs.stacks[kprocs.curr]); // (former) BUG: freeing the same stack we're using!
    // kmem_free tries to return, but the stack that it's using has been freed
    kproc_switch(&kprocs.ctxs[kprocs.curr], &sched_ctx);
}
