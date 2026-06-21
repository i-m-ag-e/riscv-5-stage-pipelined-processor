# --- Directories ---
RTL_DIR = rtl
SIM_DIR = sim
INC_DIR = $(RTL_DIR)/include

# --- Tools ---
COMPILER = iverilog
SIMULATOR = vvp

# --- RISC-V Toolchain ---
RV_PREFIX ?= riscv64-unknown-elf-
RV_CC = $(RV_PREFIX)gcc
RV_OBJCOPY = $(RV_PREFIX)objcopy

# Flags for bare-metal RISC-V compiling
RV_CFLAGS = -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -Ttext=0x0

# --- Flags ---
# -g2012 enables SystemVerilog support
# -Wall enables all warnings
# -I adds the include directory to the search path
CFLAGS = -Wall -g2012 -I $(INC_DIR)

# --- Files for ALU Controller Test ---
# Add any necessary RTL dependencies here as you expand
DEF_ALU = $(INC_DIR)/alu_definitions.sv
SRC_ALU = $(RTL_DIR)/core/alu_controller.sv
TB_ALU = $(SIM_DIR)/tb_alu_controller.v
OUT_ALU = $(SIM_DIR)/tb_alu_controller.vvp

# --- Files for Top Processor Test ---
SRC_ALL = $(wildcard $(RTL_DIR)/core/*.sv) $(wildcard $(RTL_DIR)/mem/*.sv)
DEF_ALL = $(wildcard $(INC_DIR)/*.sv)
TB_TOP = $(SIM_DIR)/tb_top.sv
OUT_TOP = $(SIM_DIR)/tb_top.vvp

# --- Phony Targets ---
# These do not represent physical files
.PHONY: all clean test_alu test_top

# Default target when you just run 'make'
all: test_top

# --- C/Assembly Compilation to .mem ---
%.mem: %.c
	$(RV_CC) $(RV_CFLAGS) -o $*.elf $<
	$(RV_OBJCOPY) -O verilog $*.elf $@

%.mem: %.s
	$(RV_CC) $(RV_CFLAGS) -o $*.elf $<
	$(RV_OBJCOPY) -O verilog $*.elf $@

# --- Simulation Targets ---
# 1. Runs the compiled executable
test_alu: $(OUT_ALU)
	$(SIMULATOR) $(OUT_ALU)

test_top: $(OUT_TOP) firmware.mem
	$(SIMULATOR) $(OUT_TOP)

# 2. Compiles the testbench and source into an executable (.vvp)
$(OUT_ALU):  $(TB_ALU) $(SRC_ALU)
	$(COMPILER) $(CFLAGS) -o $(OUT_ALU) $(DEF_ALU) $(TB_ALU) $(SRC_ALU)

$(OUT_TOP): $(TB_TOP) $(SRC_ALL) $(DEF_ALL)
	$(COMPILER) $(CFLAGS) -o $(OUT_TOP) $(DEF_ALL) $(SRC_ALL) $(TB_TOP)

# --- Cleanup ---
# Removes compiled binaries and waveform files
clean:
	rm -f $(SIM_DIR)/*.vvp $(SIM_DIR)/*.vcd *.elf *.mem
