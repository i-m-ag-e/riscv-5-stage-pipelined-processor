#!/usr/bin/env python3
from migen import *
from litex.soc.integration.soc_core import SoCCore, get_mem_data
from litex.soc.integration.builder import Builder

from litex_boards.platforms import digilent_basys3

from my_riscv_core import MyRISCVCPU
from litex.soc.cores.cpu import CPUS
CPUS["my_riscv"] = MyRISCVCPU

class Basys3SoC(SoCCore):
    def __init__(self, platform):
        SoCCore.__init__(self, platform, 
            clk_freq             = int(100e6),
            
            # cpu_type             = "vexriscv", 
            cpu_type             = "my_riscv", 
            
            integrated_rom_size  = 0x8000,   # 32KB 
            integrated_sram_size = 0x8000,   # 32KB 
            integrated_main_ram_size = 0x8000,

            integrated_rom_init  = get_mem_data("firmware/firmware.bin", endianness="little")
        )

def main():
    platform = digilent_basys3.Platform()
    soc      = Basys3SoC(platform)
    
    builder  = Builder(soc, output_dir="build/basys3", compile_software=True)
    builder.build()

if __name__ == "__main__":
    main()