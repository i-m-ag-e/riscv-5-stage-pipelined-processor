.global _start
.section .text.init

_start:
    la sp, _fstack

    la t0, _fbss
    la t1, _ebss
1:
    bgeu t0, t1, 2f
    sw zero, 0(t0)
    addi t0, t0, 4
    j 1b
2:
    jal ra, main

inf_loop:
    j inf_loop
