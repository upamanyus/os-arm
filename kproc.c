#include "kproc.h"
#include "kmem.h"
#include "uart.h"

#define MAXPROCS 1024

static struct {
    struct kproc_context ctxs[MAXPROCS];
    uint64_t stacks[MAXPROCS];
    uint64_t nprocs;
} kprocs;

void kproc_create_thread(uint64_t fn)
{
    if (kprocs.nprocs >= MAXPROCS) {
        uart_puts("Unable to create a thread, too many procs\r\n");
        return;
    }

    // FIXME: want the thread to terminate itself when done.

    uint64_t i = kprocs.nprocs;
    kprocs.nprocs += 1;
    kprocs.ctxs[i].lr = fn;
    kprocs.ctxs[i].sp = kprocs.stacks[i];
}
