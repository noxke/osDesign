ENTRY(_start)

SECTIONS
{
    /* 加载内核到0x11000地址处 */
    . = 0x11000;
    .boot :
    {
        *(.boot);
        . = ALIGN(0x1000);
    }

    . = ALIGN(0x1000);
    .text :
    {
        *(.text);
    }

    . = ALIGN(0x1000);
    .rodata :
    {
        *(.rodata);
    }

    . = ALIGN(0x1000);
    .data :
    {
        *(.data);
    }

    . = ALIGN(0x1000);
    .bss :
    {
        *(COMMON);
        *(.bss);
    }
    . = ALIGN(0x1000);
}