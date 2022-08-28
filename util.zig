pub fn delay(count: u64) void {
    asm volatile ("__delay_%=: subs %[count], %[count], #1; bne __delay_%=\n"
        :
        : [count] "r" (count),
        : "cc"
    );
}
