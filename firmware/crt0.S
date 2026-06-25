.global _start
.section .text.init
_start:
    /* Initialize stack pointer to end of RAM */
    la sp, __stack_top

    /* Clear BSS section */
    la t0, __bss_start
    la t1, __bss_end
1:
    bgeu t0, t1, 2f
    sw zero, 0(t0)
    addi t0, t0, 4
    j 1b
2:
    /* Call main (implemented in C or custom Assembly test) */
    jal ra, main

    /* Halt (write to 0x2000 to trigger testbench $finish) */
    li t6, 0x2000
    sw a0, 0(t6)
inf_loop:
    j inf_loop
