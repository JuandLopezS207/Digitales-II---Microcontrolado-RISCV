MEMORY {
    FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 1K
    SRAM  (rw)  : ORIGIN = 0x00000000, LENGTH = 4K
}

SECTIONS {
    .flash : {
        *(.text)
        *(.text.*)
        *(.rodata)
        *(.rodata.*)
        . = ALIGN(4);
    } > FLASH

    .sram : {
        *(.data)
        *(.sdata)
        *(.bss)
        . = ALIGN(4);
    } > SRAM
}
