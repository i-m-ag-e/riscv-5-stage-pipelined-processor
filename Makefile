# Makefile for RISC-V Processor Simulation
# I have used GenAI to help me write this Makefile.

# --- Directories ---
RTL_DIR = rtl
SIM_DIR = sim
INC_DIR = $(RTL_DIR)/include

# --- Tools ---
COMPILER = verilator
VERILATOR_FLAGS = --binary --timing -Wno-TIMESCALEMOD -Wno-WIDTHEXPAND -I$(INC_DIR) -I$(RTL_DIR)/core -I$(RTL_DIR)/mem/tcm -I$(RTL_DIR)/mem/wishbone -I$(RTL_DIR)/tcm -I$(RTL_DIR)/wishbone

# --- RISC-V Toolchain ---
RV_PREFIX ?= riscv64-unknown-elf-
RV_CC = $(RV_PREFIX)gcc
RV_OBJCOPY = $(RV_PREFIX)objcopy

# Flags for bare-metal RISC-V compiling
RV_CFLAGS = -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles

# --- Linker & Startup Configuration ---
CRT0 = firmware/crt0.S
LINKER = firmware/linker.ld
LDFLAGS = -T $(LINKER)

ifdef STANDALONE
	CRT0 =
	LINKER =
	LDFLAGS = -Ttext=0x0
endif

# --- Files for Top Processor Test ---
SRC_ALL = $(wildcard $(RTL_DIR)/core/*.sv) $(wildcard $(RTL_DIR)/mem/tcm/*.sv) $(wildcard $(RTL_DIR)/mem/wishbone/*.sv) $(wildcard $(RTL_DIR)/tcm/*.sv) $(wildcard $(RTL_DIR)/wishbone/*.sv) $(wildcard $(RTL_DIR)/bus/*.sv)

# Ordered so packages are parsed before they are imported
DEF_ALL = $(INC_DIR)/instruction_type.sv \
          $(INC_DIR)/alu_definitions.sv \
          $(INC_DIR)/riscv_opcodes.sv \
          $(INC_DIR)/pipeline_reg_types.sv \
          $(INC_DIR)/forward_type.sv

# --- Phony Targets ---
.PHONY: all clean sim verify verify_wb verify_mega verify_all run test_%

# Default target when you just run 'make'
all: verify

# Run unit tests and ensure top-level executable is built
sim: test_alu test_alu_controller test_branch_adder test_branch_comparator test_control_unit obj_dir/Vtb_top_tcm

# --- Automated Integration Tests ---
TEST_FILES := $(wildcard tests/*.json)

verify: obj_dir/Vtb_top_tcm
	@echo "Running all tests on TCM architecture..."
	@pass=0; fail=0; \
	for test in $(TEST_FILES); do \
		if python3 run_test.py --arch tcm $$test; then \
			pass=$$((pass + 1)); \
		else \
			fail=$$((fail + 1)); \
		fi; \
	done; \
	echo ""; \
	echo "========================================"; \
	echo "TCM Results: $$pass passed, $$fail failed (of $$((pass + fail)) total)"; \
	echo "========================================"; \
	[ $$fail -eq 0 ]

verify_wb: obj_dir/Vtb_wb
	@echo "Running all tests on Wishbone (WB) architecture..."
	@pass=0; fail=0; \
	for test in $(TEST_FILES); do \
		if python3 run_test.py --arch wb $$test; then \
			pass=$$((pass + 1)); \
		else \
			fail=$$((fail + 1)); \
		fi; \
	done; \
	echo ""; \
	echo "========================================"; \
	echo "WB Results: $$pass passed, $$fail failed (of $$((pass + fail)) total)"; \
	echo "========================================"; \
	[ $$fail -eq 0 ]

verify_mega: obj_dir/Vtb_mega
	@echo "Running all tests on both architectures (comparison mode)..."
	@pass=0; fail=0; \
	for test in $(TEST_FILES); do \
		if python3 run_test.py --arch mega $$test; then \
			pass=$$((pass + 1)); \
		else \
			fail=$$((fail + 1)); \
		fi; \
	done; \
	echo ""; \
	echo "========================================"; \
	echo "Mega Results: $$pass passed, $$fail failed (of $$((pass + fail)) total)"; \
	echo "========================================"; \
	[ $$fail -eq 0 ]

verify_all: verify verify_wb verify_mega
	@echo "All verification suites passed! 🎉"

# --- Run an arbitrary program (no JSON checks, just dump state) ---
run: obj_dir/Vtb_top_tcm
ifndef FILE
	$(error FILE is undefined. Usage: make run FILE=path/to/source.s)
endif
	@python3 run_test.py --arch tcm --run $(FILE)

run_wb: obj_dir/Vtb_wb
ifndef FILE
	$(error FILE is undefined. Usage: make run_wb FILE=path/to/source.s)
endif
	@python3 run_test.py --arch wb --run $(FILE)

# Compile any arbitrary C/ASM file to .mem without simulating
build:
ifndef FILE
	$(error FILE is undefined. Usage: make build FILE=path/to/source.c)
endif
	@$(MAKE) $(basename $(FILE)).mem
	@echo "Successfully built $(basename $(FILE)).mem"

# --- C/Assembly Compilation to .mem ---
%.mem: %.c $(CRT0) $(LINKER)
	$(RV_CC) $(RV_CFLAGS) $(LDFLAGS) -o $*.elf $(CRT0) $<
	$(RV_OBJCOPY) -O binary $*.elf $*.bin
	hexdump -v -e '1/4 "%08x" "\n"' $*.bin > $@

%.mem: %.S $(CRT0) $(LINKER)
	$(RV_CC) $(RV_CFLAGS) $(LDFLAGS) -o $*.elf $(CRT0) $<
	$(RV_OBJCOPY) -O binary $*.elf $*.bin
	hexdump -v -e '1/4 "%08x" "\n"' $*.bin > $@
    
%.mem: %.s $(CRT0) $(LINKER)
	$(RV_CC) $(RV_CFLAGS) $(LDFLAGS) -o $*.elf $(CRT0) $<
	$(RV_OBJCOPY) -O binary $*.elf $*.bin
	hexdump -v -e '1/4 "%08x" "\n"' $*.bin > $@

# --- Simulation Compilation Targets ---
test_%: obj_dir/Vtb_%
	@echo "Running tb_$*..."
	@./$< | grep -v '^-'

obj_dir/Vtb_top_tcm: $(SIM_DIR)/tb_top_tcm.sv $(SRC_ALL) $(DEF_ALL)
	@echo "Compiling tb_top_tcm..."
	@$(COMPILER) $(VERILATOR_FLAGS) --top-module tb_top_tcm $(DEF_ALL) $< $(SRC_ALL) > /dev/null

obj_dir/Vtb_wb: $(SIM_DIR)/tb_wb.sv $(SRC_ALL) $(DEF_ALL)
	@echo "Compiling tb_wb..."
	@$(COMPILER) $(VERILATOR_FLAGS) --top-module tb_wb $(DEF_ALL) $< $(SRC_ALL) > /dev/null

obj_dir/Vtb_mega: $(SIM_DIR)/tb_mega.sv $(SRC_ALL) $(DEF_ALL)
	@echo "Compiling tb_mega..."
	@$(COMPILER) $(VERILATOR_FLAGS) --top-module tb_mega $(DEF_ALL) $< $(SRC_ALL) > /dev/null

obj_dir/Vtb_%: sim/core/tb_%.sv $(SRC_ALL) $(DEF_ALL)
	@echo "Compiling tb_$*..."
	@$(COMPILER) $(VERILATOR_FLAGS) --top-module tb_$* $(DEF_ALL) $< $(SRC_ALL) > /dev/null

# --- Cleanup ---
clean:
	rm -rf obj_dir $(SIM_DIR)/*.vcd *.elf *.mem *.bin
