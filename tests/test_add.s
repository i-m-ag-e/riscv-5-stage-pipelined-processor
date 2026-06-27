.global main
main:
    li x5, 15
    li x6, 25
    add x7, x5, x6 
    
    li x4, 0x1000
    sw x7, 0(x4)   
    
    li a0, 1
    ret
