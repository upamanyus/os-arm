ENTRY(_start)

SECTIONS
{
    /* Starts at LOADER_ADDR. */
    . = 0x10000; /* FIXME: is this the right address for rpi zero? */
    /* For AArch64, use . = 0x80000; */
    __start = .;
    __text_start = .;
    .text :
    {
        KEEP(*(.text.boot))
        *(.text)

        . = ALIGN(4096);
         __trampoline = .;
        *(trampsec)
        . = ALIGN(4096);
         ASSERT(. - __trampoline == 0x1000, "error: trampoline larger than one page");

    }
    . = ALIGN(4096); /* align to page size */
    __text_end = .;

    __rodata_start = .;
    .rodata :
    {
        *(.rodata)
    }
    . = ALIGN(4096); /* align to page size */
    __rodata_end = .;

    __data_start = .;
    .data :
    {
        *(.data)
    }
    . = ALIGN(4096); /* align to page size */
    __data_end = .;

    __bss_start = .;
    .bss :
    {
        bss = .;
        *(.bss)
    }
    . = ALIGN(4096); /* align to page size */
    __bss_end = .;
    __bss_size = __bss_end - __bss_start;
    __kern_end = .;
}
