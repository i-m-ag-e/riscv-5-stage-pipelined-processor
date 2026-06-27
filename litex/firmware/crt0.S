.global _start
.section .text.init

_start:
    /* 1. Initialize Stack Pointer (LiteX defines _fstack in its linker script) */
    la sp, _fstack

    /* 2. Clear BSS section (LiteX defines _fbss and _ebss) */
    la t0, _fbss
    la t1, _ebss
1:
    bgeu t0, t1, 2f
    sw zero, 0(t0)
    addi t0, t0, 4
    j 1b
2:
    /* 3. Call the LiteX BIOS main() function */
    jal ra, main

    /* 4. Catch-all infinite loop if main() ever accidentally returns */
inf_loop:
    j inf_loop
