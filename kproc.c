#include "kproc.h"
#include "kmem.h"
#include "uart.h"
#include <stdbool.h>

#define MAXPROCS 1024

#define NCPU 1

enum {
EMPTY = 0,
RUNNING = 1,
IDLE = 2,
};

struct kproc_context sched_ctx;

// this saves all the register state that must be restored when an execption occurs.
// Including sp and lr, because we might end up switching to a different
// (user-space) process after a timer interrupt fires. E.g. after a timer
// interrupt, we won't do a ret to the .
struct exception_frame {
    uint32_t r[15]; // r0-r15; includes sp, lr
};

struct kproc_info {
    int status;
    struct kproc_context ctx;
    uint32_t stack;
};

static struct {
    int curr;
    struct kproc_info procs[MAXPROCS];
    uint32_t nprocs;
} kprocs;

extern char kproc_start[];

void kproc_init()
{
    kprocs.nprocs = 0;
    for (int i = 0; i < MAXPROCS; i++) {
        kprocs.procs[i].status = EMPTY;
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
    kprocs.procs[i].ctx.r[0] = (uint32_t)fn; // in 64-bit, x19 = fn
    kprocs.procs[i].ctx.r[1] = args; // in 64-bit, x20 = args
    kprocs.procs[i].ctx.lr = (uint32_t)kproc_start;
    kprocs.procs[i].stack = (uint32_t)kmem_alloc();
    kprocs.procs[i].ctx.sp = kprocs.procs[i].stack + PGSIZE; // top of stack, since it grows down
    kprocs.procs[i].ctx.fp = kprocs.procs[i].ctx.sp;
    kprocs.procs[i].status = IDLE;
}

void kproc_scheduler(uint32_t cpu)
{
    bool took_step;
    do {
        took_step = false;
        for (int i = 0; i < MAXPROCS; i++) {
            if (kprocs.procs[kprocs.curr].status == IDLE) {
                kprocs.procs[kprocs.curr].status = RUNNING;

                // set the current stack for the CPU, so that an exception will
                // put stuff on the right stack
                kproc_switch(&sched_ctx, &(kprocs.procs[kprocs.curr].ctx));

                if (kprocs.procs[kprocs.curr].status == EMPTY) {
                    kmem_free((uint8_t*)kprocs.procs[kprocs.curr].stack); // cleanup
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
    kprocs.procs[kprocs.curr].status = IDLE;
    kproc_switch(&kprocs.procs[kprocs.curr].ctx, &sched_ctx);
}

void kproc_exit()
{
    kprocs.procs[kprocs.curr].status = EMPTY;
    // kmem_free((uint8_t*)kprocs.procs[kprocs.curr].stack); // (fixed BUG): freeing the same stack we're using!
    // kmem_free tries to return, but the stack that it's using has been freed
    kproc_switch(&kprocs.procs[kprocs.curr].ctx, &sched_ctx);
}
