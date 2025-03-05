// XXX: count must not be 0, otherwise this will delay forever.
pub fn delay(count: u64) void {
    var count_left = count;
    const count_left_ptr: *volatile u64 = @ptrCast(&count_left);

    while (count_left_ptr.* != 0) {
        count_left_ptr.* -= 1;
    }

    // FIXME: will there be multiple __delay__ definitions?
    // FIXME: zig 0.10 broke this.
    // asm volatile ("__delay_%=: subs %[count], %[count], #1; bne __delay_%=\n"
    //     :
    //     : [count] "{x8}" (count),
    //     : "cc", "x8"
    // );
    // FIXME: important to make sure the register holding count is considered
    // clobbered In "debug" mode, the raspi3/uart_init works, but probably not
    // in e.g. ReleaseSmall.
}
