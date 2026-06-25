.global main
main:
    li x5, 0x1000
    li x6, 0x1234
    sw x6, 0(x5)
    lw x7, 0(x5)
    
    li a0, 1
    ret
