.global main
main:
    li x5, 10
    li x6, 20
    
    add x7, x5, x6 
    
    beq x7, x5, fail
    bne x7, x5, next1
    j fail

next1:
    li x4, 0x1000 
    sw x7, 0(x4)
    lw x28, 0(x4)
    
    bne x7, x28, fail
    
success:
    li a0, 1
    ret
    
fail:
    li a0, 0xDEAD
    ret
