INCLUDE ../build/basys3/software/include/generated/regions.ld
INCLUDE ../build/basys3/software/include/generated/output_format.ld

ENTRY(_start)

SECTIONS
{
    /* Code goes to ROM at 0x00000000 */
    .text :
    {
        _ftext = .;
        *(.text.init)
        *(.text .text.*)
        _etext = .;
    } > rom

    .rodata :
    {
        *(.rodata .rodata.*)
        *(.srodata .srodata.*)
    } > rom

    /* Variables go to SRAM at 0x10000000 */
    .data :
    {
        _fdata = .;
        *(.data .data.*)
        *(.sdata .sdata.*)
        _edata = .;
    } > sram AT > rom

    .bss :
    {
        _fbss = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        *(COMMON)
        _ebss = .;
    } > sram

    _fstack = ORIGIN(sram) + LENGTH(sram) - 4;
}
