.global main

.data
array:  .word 10, 20, 30, 40, 50
len:    .word 5

.text
main:
    la x20, array         # load address of array
    la x21, len
    lw x8, 0(x21)         # x8 = 5 (length)

    li x6, 0              # sum = 0
    li x7, 0              # index = 0

sum_loop:
    slli x9, x7, 2
    add x9, x20, x9
    lw x10, 0(x9)
    add x6, x6, x10
    addi x7, x7, 1
    blt x7, x8, sum_loop

    li x5, 0x1000
    sw x6, 0(x5)          # store result

    li a0, 1
    ret

