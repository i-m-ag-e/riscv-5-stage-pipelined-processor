from migen import *
from litex.gen import *
from litex.soc.cores.cpu import CPU
from litex.soc.interconnect import wishbone

class MyRISCVCPU(CPU):
    name                 = "my_riscv"
    family               = "riscv"
    data_width           = 32
    endianness           = "little"
    gcc_triple           = "riscv64-unknown-elf" 
    gcc_flags            = "-march=rv32i -mabi=ilp32"
    linker_output_format = "elf32-littleriscv"
    variants             = ["standard"]
    reserved_interrupts  = {}
    io_regions           = {0x8000_0000: 0x8000_0000}
    nop                  = "nop"

    def __init__(self, platform, variant="standard"):
        self.platform     = platform
        self.variant      = variant
        self.reset_address = 0x0000_0000
        
        self.reset = Signal()
        
        self.ibus = ibus = wishbone.Interface(data_width=32)
        self.dbus = dbus = wishbone.Interface(data_width=32)
        
        self.periph_buses = [ibus, dbus] 
        self.memory_buses = []

        self.cpu_params = dict(
            i_clk             = ClockSignal("sys"),
            i_rst_n           = ~(ResetSignal("sys") | self.reset), 

            o_o_ibus_adr      = ibus.adr,
            o_o_ibus_dat_w    = ibus.dat_w,
            i_i_ibus_dat_r    = ibus.dat_r,
            o_o_ibus_sel      = ibus.sel,
            o_o_ibus_cyc      = ibus.cyc,
            o_o_ibus_stb      = ibus.stb,
            o_o_ibus_we       = ibus.we,
            i_i_ibus_ack      = ibus.ack,

            o_o_dbus_adr      = dbus.adr,
            o_o_dbus_dat_w    = dbus.dat_w,
            i_i_dbus_dat_r    = dbus.dat_r,
            o_o_dbus_sel      = dbus.sel,
            o_o_dbus_cyc      = dbus.cyc,
            o_o_dbus_stb      = dbus.stb,
            o_o_dbus_we       = dbus.we,
            i_i_dbus_ack      = dbus.ack,
        )

    def do_finalize(self):
        self.platform.add_verilog_include_path("../rtl/include")

        sv_packages = [
            "../rtl/include/instruction_type.sv",
            "../rtl/include/alu_definitions.sv",
            "../rtl/include/riscv_opcodes.sv",
            "../rtl/include/pipeline_reg_types.sv",
            "../rtl/include/forward_type.sv"
        ]
        for pkg in sv_packages:
            self.platform.add_source(pkg)

        self.platform.add_source_dir("../rtl/core")
        self.platform.add_source_dir("../rtl/bus")
        self.platform.add_source_dir("../rtl/wishbone")

        self.specials += Instance("top_wb", **self.cpu_params)
