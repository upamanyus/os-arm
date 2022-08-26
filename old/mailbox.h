#ifndef MAILBOX_H_
#define MAILBOX_H_

#include <stdint.h>

// https://github.com/raspberrypi/firmware/wiki/Mailbox-property-interface

struct mbox_tag {
    uint32_t tag_ident;
    uint32_t size;
    uint8_t data[]; // XXX: https://en.wikipedia.org/wiki/Flexible_array_member
}
__attribute__ ((aligned (16)));

struct mbox_buffer {
    uint32_t size;
    uint32_t code;
    struct mbox_tag tags[]; // NOTE: must end with 0 tag
}
__attribute__ ((aligned (16)));

// A mbox message that sets clock rate of UART1 to 3MHz
volatile unsigned int  __attribute__((aligned(16))) mbox_clockrate[9] = {
9*4, 0, 0x38002, 12, 8, 2, 3000000, 0 ,0
};

#endif // MAILBOX_H_
