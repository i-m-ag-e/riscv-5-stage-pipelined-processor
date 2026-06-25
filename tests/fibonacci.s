# store first 10 fibonacci numbers at 0x1000
# 0 1 1 2 3 5 8 13 21 34

.global main
main:
    li x20, 0x1000

    li x5, 0 # f(n - 2)
    li x6, 1 # f(n - 1)
    li x7, 10 # fibs to store
    li x8, 0  # fibs done

    sw x5, 0(x20)
    sw x6, 4(x20)
    addi x20, x20, 8
    addi x8, x8, 2

fib_loop:
    add x9, x5, x6  
    sw x9, 0(x20)   
    mv x5, x6       
    mv x6, x9
    addi x20, x20, 4
    addi x8, x8, 1
    blt x8, x7, fib_loop

    li a0, 1
    ret
