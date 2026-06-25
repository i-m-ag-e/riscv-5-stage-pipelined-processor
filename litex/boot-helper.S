.global boot_helper
boot_helper:
    /* * In the RISC-V ABI, the four C arguments (r1, r2, r3, addr) 
     * are passed in registers a0, a1, a2, and a3.
     * Since the target firmware address is the 4th argument, it is sitting in a3.
     * We simply jump to the address in a3 to launch the firmware.
     */
    jr a3
