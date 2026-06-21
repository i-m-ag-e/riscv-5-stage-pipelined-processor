# Makefile for RISC-V Processor Simulation
# I have used GenAI to help me write this Makefile. 

# --- Directories ---
RTL_DIR = rtl
SIM_DIR = sim
INC_DIR = $(RTL_DIR)/include

# --- Tools ---
COMPILER = verilator
VERILATOR_FLAGS = --binary --timing -Wno-TIMESCALEMOD -Wno-WIDTHEXPAND -I$(INC_DIR) -I$(RTL_DIR)/core -I$(RTL_DIR)/mem

# --- RISC-V Toolchain ---
RV_PREFIX ?= riscv64-unknown-elf-
RV_CC = $(RV_PREFIX)gcc
RV_OBJCOPY = $(RV_PREFIX)objcopy

# Flags for bare-metal RISC-V compiling
RV_CFLAGS = -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -Ttext=0x0

# --- Files for Top Processor Test ---
SRC_ALL = $(wildcard $(RTL_DIR)/core/*.sv) $(wildcard $(RTL_DIR)/mem/*.sv)
# Ordered so packages are parsed before they are imported
DEF_ALL = $(INC_DIR)/instruction_type.sv \
          $(INC_DIR)/alu_definitions.sv \
          $(INC_DIR)/riscv_opcodes.sv \
          $(INC_DIR)/pipeline_reg_types.sv \
          $(INC_DIR)/forward_type.sv
TB_TOP = $(SIM_DIR)/tb_top.sv
OUT_TOP = $(SIM_DIR)/tb_top.vvp

# --- Phony Targets ---
# These do not represent physical files
.PHONY: all clean test_top sim test_%

# Default target when you just run 'make'
all: test_top

# Run all self-checking testbenches
sim: test_alu test_alu_controller test_branch_adder test_branch_comparator test_control_unit test_top

# --- C/Assembly Compilation to .mem ---
%.mem: %.c firmware/crt0.S firmware/linker.ld
	$(RV_CC) $(RV_CFLAGS) -T firmware/linker.ld -o $*.elf firmware/crt0.S $<
	$(RV_OBJCOPY) -O binary $*.elf $*.bin
	hexdump -v -e '1/4 "%08x" "\n"' $*.bin > $@

%.mem: %.S firmware/crt0.S firmware/linker.ld
	$(RV_CC) $(RV_CFLAGS) -T firmware/linker.ld -o $*.elf firmware/crt0.S $<
	$(RV_OBJCOPY) -O binary $*.elf $*.bin
	hexdump -v -e '1/4 "%08x" "\n"' $*.bin > $@
    
%.mem: %.s firmware/crt0.S firmware/linker.ld
	$(RV_CC) $(RV_CFLAGS) -T firmware/linker.ld -o $*.elf firmware/crt0.S $<
	$(RV_OBJCOPY) -O binary $*.elf $*.bin
	hexdump -v -e '1/4 "%08x" "\n"' $*.bin > $@

# --- Simulation Targets ---
# 1. Runs the compiled executable
test_top: obj_dir/Vtb_top firmware/firmware.mem
	@echo "Running tb_top..."
	@cp firmware/firmware.mem firmware.mem
	@./obj_dir/Vtb_top | grep -v '^-'

test_%: obj_dir/Vtb_%
	@echo "Running tb_$*..."
	@./$< | grep -v '^-'

# 2. Compiles the testbench and source into an executable
obj_dir/Vtb_top: $(TB_TOP) $(SRC_ALL) $(DEF_ALL)
	@echo "Compiling tb_top..."
	@$(COMPILER) $(VERILATOR_FLAGS) --top-module tb_top $(DEF_ALL) $(TB_TOP) $(SRC_ALL) > /dev/null

obj_dir/Vtb_%: sim/core/tb_%.sv $(SRC_ALL) $(DEF_ALL)
	@echo "Compiling tb_$*..."
	@$(COMPILER) $(VERILATOR_FLAGS) --top-module tb_$* $(DEF_ALL) $< $(SRC_ALL) > /dev/null

# --- Cleanup ---
# Removes compiled binaries and waveform files
clean:
	rm -rf obj_dir $(SIM_DIR)/*.vcd *.elf *.mem *.bin
