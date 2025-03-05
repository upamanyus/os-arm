.section ".text"

.global delay
.type delay, @function
delay:
1: subs x0, x0, #1
    bne 1b
    ret
