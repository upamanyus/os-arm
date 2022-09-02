pub fn delay(count: u64) void {
    asm volatile ("__delay_%=: subs %[count], %[count], #1; bne __delay_%=\n"
        :
        : [count] "{x8}" (count),
        : "cc", "x8"
    );
    // FIXME: important to make sure the register holding count is considered
    // clobbered In "debug" mode, the raspi3/uart_init works, but probably not
    // in e.g. ReleaseSmall.
}
