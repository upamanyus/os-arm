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
    uint64_t stacks[MAXPROCS]; // Each of these is a single page large; no guard pages rn
    uint64_t nprocs;
} kprocs;

// FIXME: need to do this until I can put some code in to deallocate stack when
// thread exits
void kproc_init()
{
    for (int i = 0; i < MAXPROCS; i++) {
        kprocs.stacks[i] = (uint64_t)kmem_alloc();
        kprocs.status[i] = EMPTY;
    }
}

void kproc_start_thread()
{
    // make stack
    // fn()
    //
}

void kproc_create_thread(uint64_t fn)
{
    if (kprocs.nprocs >= MAXPROCS) {
        uart_puts("Unable to create a thread, reached max procs already\r\n");
        return;
    }

    // FIXME: want the thread to terminate itself when done.
    uint64_t i = kprocs.nprocs;
    kprocs.nprocs += 1;
    kprocs.ctxs[i].lr = fn;
    kprocs.ctxs[i].sp = kprocs.stacks[i];
    kprocs.status[i] = IDLE;
}

void kproc_scheduler()
{
    bool took_step = false;
    do {
        took_step = false;
        for (int i = 0; i < MAXPROCS; i++) {
            if (kprocs.status[kprocs.curr] == IDLE) {
                kprocs.status[kprocs.curr] = RUNNING;
                kproc_switch(&sched_ctx, &(kprocs.ctxs[kprocs.curr]));
                took_step = true;
            }

            kprocs.curr += 1;
            if (kprocs.curr == MAXPROCS) {
                kprocs.curr = 0;
            }

        }
    } while (took_step);
    uart_puts("Took no steps; kproc scheduler done\r\n");
}

void kproc_yield()
{
    kprocs.status[kprocs.curr] = IDLE;
    kproc_switch(&kprocs.ctxs[kprocs.curr], &sched_ctx);
}

void kproc_exit()
{
    kprocs.status[kprocs.curr] = EMPTY;
    kproc_switch(&kprocs.ctxs[kprocs.curr], &sched_ctx);
}
