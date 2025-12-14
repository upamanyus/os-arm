#ifndef EXECUTION_CONTEXT_H
#define EXECUTION_CONTEXT_H

#include <stdint.h>

#define MAX_CPUS 1024

typedef struct {
    uint64_t x[31];
    uint64_t sp_el0;
    __uint128_t q[32];
    uint64_t elr_el1;
    uint64_t spsr_el1;
    uint64_t fpsr;
    uint64_t fpcr;
} ExecutionContext;

extern uint64_t dispatcher_stacks[MAX_CPUS];

ExecutionContext* new_execution_context(void);
void exit_execution_context(void);
void execution_context_init(uint64_t init_fn_ptr);
void dispatch(void);

// Assembly functions
void switch_to_ectx(ExecutionContext *ectx);
uint64_t get_el(void);
void syscall(void);

#endif // EXECUTION_CONTEXT_H
