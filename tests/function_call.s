.global main
main:
    addi sp, sp, -4
    sw ra, 0(sp)

    li a0, 7
    li a1, 6
    jal ra, multiply

    li x20, 0x1000
    sw a0, 0(x20)

    li a0, 1
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Computes a0 * a1 using repeated addition (no MUL instruction in RV32I)
multiply:
    addi sp, sp, -4
    sw ra, 0(sp)

    mv x5, a0         
    mv x6, a1            
    li a0, 0             

mul_loop:
    beq x6, x0, mul_done
    add a0, a0, x5       
    addi x6, x6, -1      
    j mul_loop

mul_done:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret
